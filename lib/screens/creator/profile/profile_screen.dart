import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/utils/app_colors.dart';
import '../../../components/label_text.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import '../../../components/video_preview_player.dart';
import '../../../components/widgets.dart';
import '../../../model/apiresponse_model.dart';
import '../../../model/creator_model.dart';
import '../../../model/user_model.dart';
import '../../../utils/alert_helper.dart';
import '../../../utils/app_constants.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final MemberCreatorResponse user;
  const ProfileScreen({super.key, required this.user});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ValueNotifier<File?> _imageNotifier = ValueNotifier<File?>(null);

  // Video upload state
  bool _isUploadingVideo = false;
  double _uploadProgress = 0.0;

  static const int _maxVideoSizeBytes = 100 * 1024 * 1024; // 100MB
  static const List<String> _allowedVideoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'webm'];

  // --- Portfolio Overhaul: new section state ---
  bool _isUploadingPortfolioMedia = false;
  double _portfolioUploadProgress = 0.0;
  int? _deletingPortfolioItemId;

  int? _deletingExperienceId;
  bool _isSavingExperience = false;

  final TextEditingController _skillInputController = TextEditingController();
  bool _isAddingSkill = false;
  int? _deletingSkillId;

  bool _isSavingAvailability = false;

  @override
  void dispose() {
    _skillInputController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadVideo() async {
    if (_isUploadingVideo) return; // guard against double-tap while uploading

    final picker = ImagePicker();
    final XFile? pickedFile;

    try {
      pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    } catch (e) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: 'Could not open gallery. Please check app permissions.',
      );
      return;
    }

    if (pickedFile == null) return;

    final videoFile = File(pickedFile.path);

    // Validate extension client-side before wasting bandwidth
    final extension = pickedFile.path.split('.').last.toLowerCase();
    if (!_allowedVideoExtensions.contains(extension)) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Unsupported format',
        message: 'Please select a video in ${_allowedVideoExtensions.join(', ')} format.',
      );
      return;
    }

    // Validate size client-side before wasting bandwidth
    final fileSize = await videoFile.length();
    if (fileSize > _maxVideoSizeBytes) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'File too large',
        message: 'Please select a video under 100MB. Selected file is '
            '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB.',
      );
      return;
    }

    if (fileSize == 0) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: 'Selected file appears to be empty or unreadable.',
      );
      return;
    }

    setState(() {
      _isUploadingVideo = true;
      _uploadProgress = 0.0;
    });

    try {
      await ref.read(apiresponseProvider.notifier).uploadCreatorVideo(
        context: context,
        videoFile: videoFile,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _uploadProgress = progress);
          }
        },
      );

      await ref.read(userProvider.notifier).loadUserProfile();

      if (!mounted) return;
      showCustomAlert(
        context: context,
        isSuccess: true,
        title: 'Success',
        message: 'Intro video updated successfully.',
      );
    } catch (error) {
      if (!mounted) return;
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: _resolveErrorMessage(error, fallback: 'Failed to upload video. Please try again.'),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingVideo = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

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

      await updateProfile(imageUrl); // Send to backend
      await ref.read(userProvider.notifier).loadUserProfile(); // Reload avatar
    } catch (e) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: 'Failed to upload image.',
      );
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

    if (response.statusCode != 200) {
      throw Exception('$resourceType upload failed');
    }

    return response.data['secure_url'] as String;
  }

  Future<void> updateProfile(String imageUrl) async {
    final payload = {
      "image": imageUrl,
    };

    try {
      await ref.read(apiresponseProvider.notifier).updateProfile(
        context: context,
        payload: payload,
      );
      showCustomAlert(
        context: context,
        isSuccess: true,
        title: 'Success',
        message: 'Profile image updated successfully.',
      );
    } catch (error) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: _resolveErrorMessage(error),
      );
    }
  }

  Future<void> editJobTitle(String newJobTitle) async {
    final payload = {
      "job_title": newJobTitle,
    };

    try {
      await ref.read(apiresponseProvider.notifier).editJobTitle(
        context: context,
        payload: payload,
      );

      await ref.read(userProvider.notifier).loadUserProfile();

      showCustomAlert(
        context: context,
        isSuccess: true,
        title: 'Success',
        message: 'Job title updated successfully',
      );
    } catch (error) {
      final errorMessage = _resolveErrorMessage(error);
      debugPrint("Error: $errorMessage");
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: errorMessage,
      );
    }
  }

  Future<void> editDescription(String description) async {
    final payload = {
      "bio": description,
    };

    try {
      await ref.read(apiresponseProvider.notifier).editDescription(
        context: context,
        payload: payload,
      );

      await ref.read(userProvider.notifier).loadUserProfile();

      showCustomAlert(
        context: context,
        isSuccess: true,
        title: 'Success',
        message: 'Bio Description updated successfully',
      );
    } catch (error) {
      final errorMessage = _resolveErrorMessage(error);
      debugPrint("Error: $errorMessage");
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: errorMessage,
      );
    }
  }

  Future<void> editLocation(String location) async {
    final payload = {
      "location": location,
    };

    try {
      await ref.read(apiresponseProvider.notifier).editLocation(
        context: context,
        payload: payload,
      );

      await ref.read(userProvider.notifier).loadUserProfile();

      showCustomAlert(
        context: context,
        isSuccess: true,
        title: 'Success',
        message: 'Location updated successfully',
      );
    } catch (error) {
      final errorMessage = _resolveErrorMessage(error);
      debugPrint("Error: $errorMessage");
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: errorMessage,
      );
    }
  }

  Future<void> editSocials(Map<String, String> socials) async {
    final payload = socials;

    try {
      await ref.read(apiresponseProvider.notifier).editSocials(
        context: context,
        payload: payload,
      );

      await ref.read(userProvider.notifier).loadUserProfile();

      showCustomAlert(
        context: context,
        isSuccess: true,
        title: 'Success',
        message: 'Socials updated successfully',
      );
    } catch (error) {
      final errorMessage = _resolveErrorMessage(error);
      debugPrint("Error: $errorMessage");
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: errorMessage,
      );
    }
  }

  // -----------------------------------------------------------------
  // Portfolio Overhaul — Portfolio media
  // -----------------------------------------------------------------

  Future<void> _pickAndUploadPortfolioMedia({required bool isVideo}) async {
    if (_isUploadingPortfolioMedia) return;

    final picker = ImagePicker();
    final XFile? pickedFile;

    try {
      pickedFile = isVideo
          ? await picker.pickVideo(source: ImageSource.gallery)
          : await picker.pickImage(source: ImageSource.gallery);
    } catch (e) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: 'Could not open gallery. Please check app permissions.',
      );
      return;
    }

    if (pickedFile == null) return;

    final mediaFile = File(pickedFile.path);

    if (isVideo) {
      final extension = pickedFile.path.split('.').last.toLowerCase();
      if (!_allowedVideoExtensions.contains(extension)) {
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Unsupported format',
          message: 'Please select a video in ${_allowedVideoExtensions.join(', ')} format.',
        );
        return;
      }
      final fileSize = await mediaFile.length();
      if (fileSize > _maxVideoSizeBytes) {
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'File too large',
          message: 'Please select a video under 100MB.',
        );
        return;
      }
    }

    setState(() {
      _isUploadingPortfolioMedia = true;
      _portfolioUploadProgress = 0.0;
    });

    try {
      await ref.read(apiresponseProvider.notifier).addPortfolioItem(
        context: context,
        mediaFile: mediaFile,
        onProgress: (progress) {
          if (mounted) setState(() => _portfolioUploadProgress = progress);
        },
      );

      await ref.read(userProvider.notifier).loadUserProfile();

      if (!mounted) return;
      showCustomAlert(
        context: context,
        isSuccess: true,
        title: 'Success',
        message: 'Added to your portfolio.',
      );
    } catch (error) {
      if (!mounted) return;
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: _resolveErrorMessage(error, fallback: 'Failed to add portfolio item. Please try again.'),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPortfolioMedia = false;
          _portfolioUploadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _deletePortfolioItem(CreatorPortfolioItem item) async {
    final confirmed = await _confirmDelete(
      title: 'Remove item?',
      message: 'This will remove it from your portfolio.',
    );
    if (!confirmed) return;

    setState(() => _deletingPortfolioItemId = item.id);
    try {
      await ref.read(apiresponseProvider.notifier).deletePortfolioItem(context: context, id: item.id);
      await ref.read(userProvider.notifier).loadUserProfile();
    } catch (error) {
      if (!mounted) return;
      showCustomAlert(context: context, isSuccess: false, title: 'Error', message: _resolveErrorMessage(error));
    } finally {
      if (mounted) setState(() => _deletingPortfolioItemId = null);
    }
  }

  void _showAddPortfolioMediaSheet(ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A191E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.image_outlined, color: theme.colorScheme.onSurface),
                  title: Text('Add photo', style: TextStyle(color: theme.colorScheme.onSurface)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadPortfolioMedia(isVideo: false);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.videocam_outlined, color: theme.colorScheme.onSurface),
                  title: Text('Add video', style: TextStyle(color: theme.colorScheme.onSurface)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadPortfolioMedia(isVideo: true);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -----------------------------------------------------------------
  // Portfolio Overhaul — Experience
  // -----------------------------------------------------------------

  Future<void> _saveExperience({int? id, required Map<String, dynamic> payload}) async {
    setState(() => _isSavingExperience = true);
    try {
      if (id == null) {
        await ref.read(apiresponseProvider.notifier).addExperience(context: context, payload: payload);
      } else {
        await ref.read(apiresponseProvider.notifier).updateExperience(context: context, id: id, payload: payload);
      }
      await ref.read(userProvider.notifier).loadUserProfile();
      if (!mounted) return;
      showCustomAlert(
        context: context,
        isSuccess: true,
        title: 'Success',
        message: id == null ? 'Experience added' : 'Experience updated',
      );
    } catch (error) {
      if (!mounted) return;
      showCustomAlert(context: context, isSuccess: false, title: 'Error', message: _resolveErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSavingExperience = false);
    }
  }

  Future<void> _deleteExperience(CreatorExperience exp) async {
    final confirmed = await _confirmDelete(
      title: 'Remove experience?',
      message: 'This will remove "${exp.title}" from your profile.',
    );
    if (!confirmed) return;

    setState(() => _deletingExperienceId = exp.id);
    try {
      await ref.read(apiresponseProvider.notifier).deleteExperience(context: context, id: exp.id);
      await ref.read(userProvider.notifier).loadUserProfile();
    } catch (error) {
      if (!mounted) return;
      showCustomAlert(context: context, isSuccess: false, title: 'Error', message: _resolveErrorMessage(error));
    } finally {
      if (mounted) setState(() => _deletingExperienceId = null);
    }
  }

  void _showExperienceFormSheet(ThemeData theme, bool isDark, {CreatorExperience? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ExperienceFormBottomSheet(
          existing: existing,
          theme: theme,
          isDark: isDark,
          onSave: (payload) {
            Navigator.pop(ctx);
            _saveExperience(id: existing?.id, payload: payload);
          },
        );
      },
    );
  }

  // -----------------------------------------------------------------
  // Portfolio Overhaul — Skills
  // -----------------------------------------------------------------

  Future<void> _addSkill() async {
    final label = _skillInputController.text.trim();
    if (label.isEmpty) return;

    setState(() => _isAddingSkill = true);
    try {
      await ref.read(apiresponseProvider.notifier).addSkill(context: context, payload: {'label': label});
      _skillInputController.clear();
      await ref.read(userProvider.notifier).loadUserProfile();
    } catch (error) {
      if (!mounted) return;
      showCustomAlert(context: context, isSuccess: false, title: 'Error', message: _resolveErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isAddingSkill = false);
    }
  }

  Future<void> _deleteSkill(CreatorSkill skill) async {
    setState(() => _deletingSkillId = skill.id);
    try {
      await ref.read(apiresponseProvider.notifier).deleteSkill(context: context, id: skill.id);
      await ref.read(userProvider.notifier).loadUserProfile();
    } catch (error) {
      if (!mounted) return;
      showCustomAlert(context: context, isSuccess: false, title: 'Error', message: _resolveErrorMessage(error));
    } finally {
      if (mounted) setState(() => _deletingSkillId = null);
    }
  }

  // -----------------------------------------------------------------
  // Portfolio Overhaul — Availability
  // -----------------------------------------------------------------

  Future<void> _saveAvailability(Map<String, dynamic> payload) async {
    setState(() => _isSavingAvailability = true);
    try {
      await ref.read(apiresponseProvider.notifier).updateAvailability(context: context, payload: payload);
      await ref.read(userProvider.notifier).loadUserProfile();
      if (!mounted) return;
      showCustomAlert(context: context, isSuccess: true, title: 'Success', message: 'Availability updated');
    } catch (error) {
      if (!mounted) return;
      showCustomAlert(context: context, isSuccess: false, title: 'Error', message: _resolveErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSavingAvailability = false);
    }
  }

  void _showAvailabilitySheet(
      ThemeData theme,
      bool isDark, {
        String? responseTime,
        String? status,
        required bool isAvailableNow,
      }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return AvailabilityFormBottomSheet(
          initialResponseTime: responseTime,
          initialStatus: status,
          initialIsAvailableNow: isAvailableNow,
          theme: theme,
          isDark: isDark,
          onSave: (payload) {
            Navigator.pop(ctx);
            _saveAvailability(payload);
          },
        );
      },
    );
  }

  // -----------------------------------------------------------------
  // Shared helpers
  // -----------------------------------------------------------------

  Future<bool> _confirmDelete({required String title, required String message}) async {
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _resolveErrorMessage(Object error, {String fallback = 'An unexpected error occurred'}) {
    String errorMessage = fallback;
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout || error.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Request timed out. Please check your connection and try again.';
      } else if (error.response?.data != null) {
        try {
          final apiResponse = ApiResponseModel.fromJson(error.response?.data);
          errorMessage = apiResponse.message;
        } catch (_) {}
      } else {
        errorMessage = error.message ?? 'Network error occurred';
      }
    }
    return errorMessage;
  }

  void showEditJobTitleSheet(BuildContext context, String currentJobTitle,
      ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return EditTextFieldBottomSheet(
          title: 'Edit Job Title',
          initialValue: currentJobTitle,
          hintText: 'Voice Over Artist',
          isMultiline: true,
          onSave: (newValue) {
            if (newValue.trim().isEmpty) return;
            editJobTitle(newValue);
            Navigator.pop(context);
          },
          theme: theme,
          isDark: isDark,
        );
      },
    );
  }

  void showEditBioDescriptionSheet(BuildContext context, String currentBio,
      ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return EditTextFieldBottomSheet(
          title: 'Edit Bio Description',
          initialValue: currentBio,
          hintText: 'I am a professional voice-over artist...',
          isMultiline: true,
          onSave: (newValue) {
            if (newValue.trim().isEmpty) return;
            editDescription(newValue);
            Navigator.pop(context);
          },
          theme: theme,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildVideoCard({
    required String? videoUrl,
    required ThemeData theme,
    required bool isDark,
  }) {
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A191E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Intro Video',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              Icon(
                hasVideo ? Icons.check_circle : Icons.info_outline,
                color: hasVideo
                    ? Colors.green
                    : theme.colorScheme.onSurface.withOpacity(0.4),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (hasVideo && !_isUploadingVideo)
            VideoPreviewPlayer(
              key: ValueKey(videoUrl),
              videoUrl: videoUrl,
            )
          else if (!_isUploadingVideo)
            Text(
              'Add a short intro video to help clients get to know you.',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 13,
              ),
            ),

          const SizedBox(height: 12),

          if (_isUploadingVideo) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _uploadProgress > 0 ? _uploadProgress : null,
                minHeight: 6,
                backgroundColor: theme.dividerColor.withOpacity(0.2),
                color: AppColors.PRIMARYCOLOR,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Uploading… ${(_uploadProgress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ] else
            OutlinedButton.icon(
              onPressed: _pickAndUploadVideo,
              icon: Icon(
                Icons.videocam_outlined,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                size: 16,
              ),
              label: Text(
                hasVideo ? 'Replace video' : 'Upload video',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.dividerColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // Portfolio Overhaul — Portfolio media section
  // -----------------------------------------------------------------

  Widget _buildPortfolioSection({
    required List<CreatorPortfolioItem> items,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A191E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Portfolio',
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 14),
              ),
              GestureDetector(
                onTap: _isUploadingPortfolioMedia ? null : () => _showAddPortfolioMediaSheet(theme, isDark),
                child: Icon(Icons.add_circle_outline, color: theme.colorScheme.onSurface.withOpacity(0.6), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isUploadingPortfolioMedia) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _portfolioUploadProgress > 0 ? _portfolioUploadProgress : null,
                minHeight: 6,
                backgroundColor: theme.dividerColor.withOpacity(0.2),
                color: AppColors.PRIMARYCOLOR,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (items.isEmpty && !_isUploadingPortfolioMedia)
            Text(
              'Add photos or videos of your work to build your portfolio.',
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
            )
          else if (items.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                final isDeleting = _deletingPortfolioItemId == item.id;
                print(item.mediaUrl);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NetworkImageWithLoader(
                        imageUrl: item.mediaUrl,
                      ),
                      // Image.network(item.thumbnailUrl ?? item.mediaUrl, fit: BoxFit.cover),
                      if (item.isVideo && !isDeleting)
                        const Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: 28)),
                      if (isDeleting)
                        Container(
                          color: Colors.black45,
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                          ),
                        ),
                      if (!isDeleting)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _deletePortfolioItem(item),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // Portfolio Overhaul — Experience section
  // -----------------------------------------------------------------

  Widget _buildExperienceSection({
    required List<CreatorExperience> experiences,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A191E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Experience',
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 14),
              ),
              GestureDetector(
                onTap: () => _showExperienceFormSheet(theme, isDark),
                child: Icon(Icons.add_circle_outline, color: theme.colorScheme.onSurface.withOpacity(0.6), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (experiences.isEmpty)
            Text(
              'Add previous projects, clients, or roles.',
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
            )
          else
            ...experiences.map((exp) => _buildExperienceTile(exp, theme, isDark)),
        ],
      ),
    );
  }

  Widget _buildExperienceTile(CreatorExperience exp, ThemeData theme, bool isDark) {
    final isDeleting = _deletingExperienceId == exp.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exp.title,
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  exp.organization,
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
                ),
                if (exp.description != null && exp.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    exp.description!,
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (isDeleting)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            Row(
              children: [
                GestureDetector(
                  onTap: () => _showExperienceFormSheet(theme, isDark, existing: exp),
                  child: Icon(Icons.edit, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _deleteExperience(exp),
                  child: Icon(Icons.delete_outline, size: 16, color: theme.colorScheme.error),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // Portfolio Overhaul — Skills section
  // -----------------------------------------------------------------

  Widget _buildSkillsSection({
    required List<CreatorSkill> skills,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A191E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Skills', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 14)),
          const SizedBox(height: 12),
          if (skills.isEmpty)
            Text(
              'Add areas of expertise, e.g. "Color Grading".',
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((s) {
                final isDeleting = _deletingSkillId == s.id;
                return Chip(
                  label: Text(s.label, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 12)),
                  backgroundColor: theme.colorScheme.onSurface.withOpacity(0.06),
                  deleteIcon: isDeleting
                      ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Icon(Icons.close, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  onDeleted: isDeleting ? null : () => _deleteSkill(s),
                );
              }).toList(),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skillInputController,
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Add a skill',
                    hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: isDark ? Colors.transparent : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                  onSubmitted: (_) => _addSkill(),
                ),
              ),
              const SizedBox(width: 8),
              _isAddingSkill
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(
                onPressed: _addSkill,
                icon: const Icon(Icons.add_circle, color: AppColors.PRIMARYCOLOR),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // Portfolio Overhaul — Availability section
  // -----------------------------------------------------------------

  Widget _buildAvailabilitySection({
    required String? responseTime,
    required String? status,
    required bool isAvailableNow,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A191E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Availability',
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 14),
              ),
              GestureDetector(
                onTap: () => _showAvailabilitySheet(
                  theme,
                  isDark,
                  responseTime: responseTime,
                  status: status,
                  isAvailableNow: isAvailableNow,
                ),
                child: Icon(Icons.edit, color: theme.colorScheme.onSurface.withOpacity(0.6), size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isAvailableNow ? Icons.check_circle : Icons.schedule,
                size: 16,
                color: isAvailableNow ? Colors.green : Colors.orangeAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (status == null || status.isEmpty) ? 'Not set' : status,
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                ),
              ),
            ],
          ),
          if (responseTime != null && responseTime.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              responseTime,
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  void showLocationBottomSheet(BuildContext context, String currentBio,
      ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return EditTextFieldBottomSheet(
          title: 'Edit Location',
          initialValue: currentBio,
          hintText: '',
          isMultiline: true,
          onSave: (newValue) {
            if (newValue.trim().isEmpty) return;
            editLocation(newValue);
            Navigator.pop(context);
          },
          theme: theme,
          isDark: isDark,
        );
      },
    );
  }

  void showEditSocialsSheet(BuildContext context, Map<String, String> currentSocials,
      ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return EditSocialsBottomSheet(
          initialSocials: currentSocials,
          onSave: (newSocials) {
            if (newSocials.isEmpty) return;
            editSocials(newSocials);
            Navigator.pop(context);
          },
          theme: theme,
          isDark: isDark,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(userProvider);
    final creator = user.value?.user?.creator;

    final instagram = creator?.instagram;
    final linkedin = creator?.linkedin;
    final x = creator?.x;

    final socials = {
      if (instagram != null && instagram.isNotEmpty) 'instagram': instagram,
      if (linkedin != null && linkedin.isNotEmpty) 'linkedin': linkedin,
      if (x != null && x.isNotEmpty) 'x': x,
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
            UserAvatarWidget(
              imageUrl: user.value?.user?.image,
              firstName: widget.user.user!.firstName,
            ),
            const SizedBox(height: 12),
            Text(
              "${widget.user.user!.firstName} ${widget.user.user!.lastName}",
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 16),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
            const SizedBox(height: 30),

            _buildInfoCard(
              label: 'Job Title',
              value: user.value?.user?.creator?.jobTitle ?? 'Not specified',
              hasEdit: true,
              onEdit: () {
                showEditJobTitleSheet(
                  context,
                  user.value?.user?.creator?.jobTitle ?? '',
                  theme,
                  isDark,
                );
              },
              theme: theme,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            _buildInfoCard(
              label: 'Bio Description',
              value: user.value?.user?.creator?.bio ?? 'No bio provided.',
              hasEdit: true,
              onEdit: () {
                showEditBioDescriptionSheet(
                  context,
                  user.value?.user?.creator?.bio ?? 'No bio provided.',
                  theme,
                  isDark,
                );
              },
              theme: theme,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            _buildInfoCard(
              label: 'Where are you based?',
              value: user.value?.user?.creator?.location ?? 'Not specified',
              hasEdit: true,
              onEdit: () {
                showLocationBottomSheet(
                  context,
                  user.value?.user?.creator?.location ?? '',
                  theme,
                  isDark,
                );
              },
              theme: theme,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            _buildSocialsCard(
              socials: socials,
              onEdit: () {
                showEditSocialsSheet(context, socials, theme, isDark);
              },
              theme: theme,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            _buildVideoCard(
              videoUrl: creator?.videoUrl,
              theme: theme,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // --- Portfolio Overhaul: new sections ---
            _buildPortfolioSection(
              items: creator?.portfolioItems ?? const [],
              theme: theme,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            _buildExperienceSection(
              experiences: creator?.experiences ?? const [],
              theme: theme,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            _buildSkillsSection(
              skills: creator?.skills ?? const [],
              theme: theme,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            _buildAvailabilitySection(
              responseTime: creator?.availabilityResponseTime,
              status: creator?.availabilityStatus,
              isAvailableNow: creator?.isAvailableNow ?? true,
              theme: theme,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            _buildProfileLinkCard(
              creatorId: creator?.id,
              theme: theme,
              isDark: isDark,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileLinkCard({
    required int? creatorId,
    required ThemeData theme,
    required bool isDark,
  }) {
    final link = creatorId != null
        ? '${AppConstants.publicProfileBaseUrl}$creatorId'
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A191E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your profile link',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            link ?? 'Complete your creator setup to get a shareable link',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (link != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyProfileLink(link),
                    icon: Icon(
                      Icons.copy,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    label: Text(
                      'Copy',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.dividerColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareProfileLink(link),
                    icon: const Icon(Icons.share, size: 16, color: Colors.white),
                    label: const Text(
                      'Share',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.PRIMARYCOLOR,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _copyProfileLink(String link) {
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile link copied')),
    );
  }

  void _shareProfileLink(String link) {
    final name = widget.user.user?.firstName ?? 'my';
    SharePlus.instance.share(
      ShareParams(
        text: "Check out $name's profile on Cre8Hive: $link",
      ),
    );
  }

  Widget _buildInfoCard({
    required String label,
    required String value,
    required bool hasEdit,
    required VoidCallback onEdit,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A191E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              if (hasEdit)
                GestureDetector(
                  onTap: onEdit,
                  child: Icon(
                    Icons.edit,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    size: 18,
                  ),
                ),
            ],
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
    );
  }

  Widget _buildSocialsCard({
    required Map<String, String>? socials,
    required VoidCallback onEdit,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A191E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Socials',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Icon(
                  Icons.edit_outlined,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (socials != null && socials.isNotEmpty)
            ...socials.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      StringExtension(entry.key).capitalize(),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            )),
          if (socials == null || socials.isEmpty)
            Text(
              'No social links added.',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }
}

// Extension to capitalize strings for social media names
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class EditSocialsBottomSheet extends StatefulWidget {
  final Map<String, String> initialSocials;
  final Function(Map<String, String> newSocials) onSave;
  final ThemeData? theme;
  final bool? isDark;

  const EditSocialsBottomSheet({
    super.key,
    required this.initialSocials,
    required this.onSave,
    this.theme,
    this.isDark,
  });

  @override
  State<EditSocialsBottomSheet> createState() => _EditSocialsBottomSheetState();
}

class _EditSocialsBottomSheetState extends State<EditSocialsBottomSheet> {
  final List<String> _fixedSocialPlatforms = [
    'linkedin',
    'x',
    'instagram',
  ];

  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    for (var platform in _fixedSocialPlatforms) {
      _controllers[platform] = TextEditingController(
        text: widget.initialSocials[platform] ?? '',
      );
    }
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? Theme.of(context);
    final isDark = widget.isDark ?? theme.brightness == Brightness.dark;

    return Container(
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
                'Edit Socials',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._fixedSocialPlatforms.map((platform) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    StringExtension(platform).capitalize(),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controllers[platform],
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Enter link',
                      hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      filled: true,
                      fillColor: isDark ? Colors.transparent : Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: theme.dividerColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: theme.colorScheme.onSurface.withOpacity(0.5), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    cursorColor: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 30),

          RoundedButton(
            title: 'Save Changes',
            onPressed: () {
              Map<String, String> newSocials = {};
              _controllers.forEach((platform, controller) {
                if (controller.text.isNotEmpty) {
                  newSocials[platform] = controller.text;
                }
              });
              widget.onSave(newSocials);
              Navigator.pop(context);
            },
            color: AppColors.BUTTONCOLOR,
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
          ),
        ],
      ),
    );
  }
}

class EditTextFieldBottomSheet extends StatefulWidget {
  final String title;
  final String initialValue;
  final String hintText;
  final bool isMultiline;
  final bool isCurrency;
  final String? buttonText;
  final TextInputType? inputType;
  final Function(String newValue) onSave;
  final ThemeData? theme;
  final bool? isDark;

  const EditTextFieldBottomSheet({
    super.key,
    required this.title,
    required this.initialValue,
    this.hintText = '',
    this.isMultiline = false,
    required this.onSave,
    this.buttonText,
    this.inputType,
    this.isCurrency = false,
    this.theme,
    this.isDark,
  });

  @override
  State<EditTextFieldBottomSheet> createState() => _EditTextFieldBottomSheetState();
}

class _EditTextFieldBottomSheetState extends State<EditTextFieldBottomSheet> {
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

    return Container(
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
                icon: Icon(
                  Icons.close,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.isCurrency) ...[
            CurrencyInputField(
              label: "",
              controller: _controller,
              onChanged: (value) {
                debugPrint('Input changed to: $value');
              },
              validator: (value) {
                if (value == null || value.isEmpty || double.tryParse(value) == null) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
              theme: theme,
              isDark: isDark,
            ),
          ] else ... [
            LabeledTextField(
              label: '',
              controller: _controller,
              hintText: widget.hintText,
              keyboardType: widget.inputType ?? TextInputType.text,
              maxLines: widget.isMultiline ? 4 : 1,
            ),
          ],

          const SizedBox(height: 30),
          RoundedButton(
            title: widget.buttonText ?? 'Save changes',
            color: AppColors.BUTTONCOLOR,
            onPressed: () {
              widget.onSave(_controller.text);
              Navigator.pop(context);
            },
          ),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------
// Portfolio Overhaul — new bottom sheets
// -----------------------------------------------------------------

class ExperienceFormBottomSheet extends StatefulWidget {
  final CreatorExperience? existing;
  final Function(Map<String, dynamic> payload) onSave;
  final ThemeData theme;
  final bool isDark;

  const ExperienceFormBottomSheet({
    super.key,
    this.existing,
    required this.onSave,
    required this.theme,
    required this.isDark,
  });

  @override
  State<ExperienceFormBottomSheet> createState() => _ExperienceFormBottomSheetState();
}

class _ExperienceFormBottomSheetState extends State<ExperienceFormBottomSheet> {
  late TextEditingController _titleController;
  late TextEditingController _organizationController;
  late TextEditingController _descriptionController;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCurrent = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _organizationController = TextEditingController(text: e?.organization ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _startDate = e?.startDate != null ? DateTime.tryParse(e!.startDate!) : null;
    _endDate = e?.endDate != null ? DateTime.tryParse(e!.endDate!) : null;
    _isCurrent = e?.isCurrent ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _organizationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = (isStart ? _startDate : _endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  String? _fmt(DateTime? d) =>
      d == null ? null : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _handleSave() {
    if (_titleController.text.trim().isEmpty || _organizationController.text.trim().isEmpty) return;
    widget.onSave({
      'title': _titleController.text.trim(),
      'organization': _organizationController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      'start_date': _fmt(_startDate),
      'end_date': _isCurrent ? null : _fmt(_endDate),
      'is_current': _isCurrent,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = widget.isDark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A191E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existing == null ? 'Add Experience' : 'Edit Experience',
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w400),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildLabel('Title', theme),
            TextField(
              controller: _titleController,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: _inputDecoration('e.g. Lead Videographer', theme, isDark),
            ),
            const SizedBox(height: 15),
            _buildLabel('Organization / Client', theme),
            TextField(
              controller: _organizationController,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: _inputDecoration('e.g. Acme Productions', theme, isDark),
            ),
            const SizedBox(height: 15),
            _buildLabel('Description', theme),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: _inputDecoration('What did you do?', theme, isDark),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: true),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: theme.dividerColor)),
                    child: Text(
                      _startDate == null ? 'Start date' : _fmt(_startDate)!,
                      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isCurrent ? null : () => _pickDate(isStart: false),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: theme.dividerColor)),
                    child: Text(
                      _isCurrent ? 'Present' : (_endDate == null ? 'End date' : _fmt(_endDate)!),
                      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isCurrent,
              onChanged: (v) => setState(() => _isCurrent = v),
              title: Text('I currently work here', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13)),
              activeColor: AppColors.PRIMARYCOLOR,
            ),
            const SizedBox(height: 20),
            RoundedButton(title: 'Save', color: AppColors.BUTTONCOLOR, onPressed: _handleSave),
            Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom)),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, ThemeData theme) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w500)),
  );

  InputDecoration _inputDecoration(String hint, ThemeData theme, bool isDark) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
    filled: true,
    fillColor: isDark ? Colors.transparent : Colors.grey[50],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}

class AvailabilityFormBottomSheet extends StatefulWidget {
  final String? initialResponseTime;
  final String? initialStatus;
  final bool initialIsAvailableNow;
  final Function(Map<String, dynamic> payload) onSave;
  final ThemeData theme;
  final bool isDark;

  const AvailabilityFormBottomSheet({
    super.key,
    this.initialResponseTime,
    this.initialStatus,
    required this.initialIsAvailableNow,
    required this.onSave,
    required this.theme,
    required this.isDark,
  });

  @override
  State<AvailabilityFormBottomSheet> createState() => _AvailabilityFormBottomSheetState();
}

class _AvailabilityFormBottomSheetState extends State<AvailabilityFormBottomSheet> {
  late TextEditingController _responseTimeController;
  late TextEditingController _statusController;
  late bool _isAvailableNow;

  @override
  void initState() {
    super.initState();
    _responseTimeController = TextEditingController(text: widget.initialResponseTime ?? '');
    _statusController = TextEditingController(text: widget.initialStatus ?? '');
    _isAvailableNow = widget.initialIsAvailableNow;
  }

  @override
  void dispose() {
    _responseTimeController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = widget.isDark;

    return Container(
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
                'Edit Availability',
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w400),
              ),
              IconButton(
                icon: Icon(Icons.close, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _isAvailableNow,
            onChanged: (v) => setState(() => _isAvailableNow = v),
            title: Text('Available for new bookings', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13)),
            activeColor: AppColors.PRIMARYCOLOR,
          ),
          const SizedBox(height: 8),
          Text('Status', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _statusController,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'e.g. Available this week',
              hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
              filled: true,
              fillColor: isDark ? Colors.transparent : Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 15),
          Text('Response time', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _responseTimeController,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'e.g. Usually responds within 2 hours',
              hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
              filled: true,
              fillColor: isDark ? Colors.transparent : Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),
          RoundedButton(
            title: 'Save',
            color: AppColors.BUTTONCOLOR,
            onPressed: () {
              widget.onSave({
                'availability_status': _statusController.text.trim().isEmpty ? null : _statusController.text.trim(),
                'availability_response_time':
                _responseTimeController.text.trim().isEmpty ? null : _responseTimeController.text.trim(),
                'is_available_now': _isAvailableNow,
              });
            },
          ),
          Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom)),
        ],
      ),
    );
  }
}