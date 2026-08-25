import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soundhive2/model/user_model.dart';

import '../../components/rounded_button.dart';
import '../../components/widgets.dart';
import '../../lib/dashboard_provider/apiresponseprovider.dart';
import '../../lib/dashboard_provider/user_provider.dart';
import '../../model/apiresponse_model.dart';
import '../../utils/alert_helper.dart';
import '../../utils/app_colors.dart';

class NonCreatorProfile extends ConsumerStatefulWidget {
  final MemberCreatorResponse user;
  const NonCreatorProfile({super.key, required this.user});

  @override
  ConsumerState<NonCreatorProfile> createState() => _NonCreatorProfileState();
}

class _NonCreatorProfileState extends ConsumerState<NonCreatorProfile> {
  final ValueNotifier<File?> _imageNotifier = ValueNotifier<File?>(null);

  // ─── Image Pick & Upload ───────────────────────────────────────────────────

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final imageFile = File(pickedFile.path);
    _imageNotifier.value = imageFile;

    try {
      final imageUrl = await _uploadFileToCloudinary(
        file: imageFile,
        resourceType: 'image',
        preset: 'soundhive',
      );
      await _updateProfile({"image": imageUrl});
    } catch (e) {
      _showError('Failed to upload image.');
    }
  }

  Future<String> _uploadFileToCloudinary({
    required File file,
    required String resourceType,
    required String preset,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
      'upload_preset': preset,
      'resource_type': resourceType,
    });
    final response = await Dio().post(
      'https://api.cloudinary.com/v1_1/djutcezwz/$resourceType/upload',
      data: formData,
    );
    if (response.statusCode != 200) throw Exception('Upload failed');
    return response.data['secure_url'] as String;
  }

  // ─── Generic Backend Update ────────────────────────────────────────────────

  Future<void> _updateProfile(Map<String, dynamic> payload) async {
    try {
      await ref.read(apiresponseProvider.notifier).updateUserProfile(
        context: context,
        payload: payload,
      );
      // Reload so userProvider rebuilds with fresh data (name, phone, etc.)
      await ref.read(userProvider.notifier).loadUserProfile();
      _showSuccess('Profile updated successfully.');
    } catch (error) {
      String msg = 'An unexpected error occurred';
      if (error is DioException && error.response?.data != null) {
        try {
          msg = ApiResponseModel.fromJson(error.response?.data).message;
        } catch (_) {}
      }
      _showError(msg);
    }
  }

  // ─── Alert Helpers ─────────────────────────────────────────────────────────

  void _showSuccess(String message) => showCustomAlert(
    context: context,
    isSuccess: true,
    title: 'Success',
    message: message,
  );

  void _showError(String message) => showCustomAlert(
    context: context,
    isSuccess: false,
    title: 'Error',
    message: message,
  );

  // ─── Bottom Sheet ──────────────────────────────────────────────────────────

  void _showEditSheet({
    required String title,
    required String currentValue,
    required String hintText,
    required String payloadKey,
    bool isMultiline = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditTextFieldBottomSheet(
        title: title,
        initialValue: currentValue,
        hintText: hintText,
        isMultiline: isMultiline,
        theme: theme,
        isDark: isDark,
        onSave: (newValue) {
          if (newValue.trim().isEmpty) return;
          _updateProfile({payloadKey: newValue.trim()});
          Navigator.pop(context);
        },
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Watch userProvider so the whole build() reruns when data changes
    final user = ref.watch(userProvider);
    final liveUser = user.value?.user;

    // Use live data if available, fall back to widget.user passed in
    final firstName = liveUser?.firstName ?? widget.user.user!.firstName;
    final lastName = liveUser?.lastName ?? widget.user.user!.lastName;
    final email = liveUser?.email ?? widget.user.user!.email ?? 'Not provided';
    final phone = liveUser?.phoneNumber ?? 'Not provided';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            Container(
              alignment: Alignment.topLeft,
              child: Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Avatar
            UserAvatarWidget(
              imageUrl: liveUser?.image,
              firstName: firstName,
            ),
            const SizedBox(height: 12),

            // ← Now reads from liveUser so it updates immediately after save
            Text(
              '$firstName $lastName',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 16),

            // Change picture button
            OutlinedButton.icon(
              onPressed: _pickAndUploadImage,
              icon: Icon(
                Icons.camera_alt_outlined,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                size: 12,
              ),
              label: Text(
                'Change profile picture',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.dividerColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
            const SizedBox(height: 30),

            // ── Editable Info Cards ──────────────────────────────────────────

            _buildInfoCard(
              label: 'First Name',
              value: firstName,
              theme: theme,
              isDark: isDark,
              onEdit: () => _showEditSheet(
                title: 'Edit First Name',
                currentValue: firstName,
                hintText: 'John',
                payloadKey: 'first_name',
              ),
            ),
            const SizedBox(height: 16),

            _buildInfoCard(
              label: 'Last Name',
              value: lastName,
              theme: theme,
              isDark: isDark,
              onEdit: () => _showEditSheet(
                title: 'Edit Last Name',
                currentValue: lastName,
                hintText: 'Doe',
                payloadKey: 'last_name',
              ),
            ),
            const SizedBox(height: 16),

            _buildInfoCard(
              label: 'Email',
              value: email,
              theme: theme,
              isDark: isDark,
              hasEdit: false, // Email not editable
            ),
            const SizedBox(height: 16),

            _buildInfoCard(
              label: 'Phone Number',
              value: phone,
              theme: theme,
              isDark: isDark,
              onEdit: () => _showEditSheet(
                title: 'Edit Phone Number',
                currentValue: liveUser?.phoneNumber ?? '',
                hintText: '+2348012345678',
                payloadKey: 'phone',
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Info Card — entire card is tappable ──────────────────────────────────

  Widget _buildInfoCard({
    required String label,
    required String value,
    required ThemeData theme,
    required bool isDark,
    bool hasEdit = true,
    VoidCallback? onEdit,
  }) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A191E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + value stacked on the left
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Edit icon on the right
          if (hasEdit && onEdit != null)
            Icon(
              Icons.edit,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              size: 18,
            ),
        ],
      ),
    );

    // Wrap with InkWell so the whole card fires onEdit, not just the icon
    if (hasEdit && onEdit != null) {
      return InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }

    return card;
  }
}

// ─── Bottom Sheet ──────────────────────────────────────────────────────────

class _EditTextFieldBottomSheet extends StatefulWidget {
  final String title;
  final String initialValue;
  final String hintText;
  final bool isMultiline;
  final Function(String newValue) onSave;
  final ThemeData? theme;
  final bool? isDark;

  const _EditTextFieldBottomSheet({
    required this.title,
    required this.initialValue,
    this.hintText = '',
    this.isMultiline = false,
    required this.onSave,
    this.theme,
    this.isDark,
  });

  @override
  State<_EditTextFieldBottomSheet> createState() =>
      _EditTextFieldBottomSheetState();
}

class _EditTextFieldBottomSheetState
    extends State<_EditTextFieldBottomSheet> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? Theme.of(context);
    final isDark = widget.isDark ?? theme.brightness == Brightness.dark;

    return Padding(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A191E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close,
                      color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              maxLines: widget.isMultiline ? 4 : 1,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5)),
                filled: true,
                fillColor: isDark ? Colors.transparent : Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      width: 1.5),
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              cursorColor: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 30),
            RoundedButton(
              title: 'Save Changes',
              color: AppColors.BUTTONCOLOR,
              onPressed: () => widget.onSave(_controller.text),
            ),
          ],
        ),
      ),
    );
  }
}