import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/utils/app_colors.dart';
import 'package:soundhive2/utils/utils.dart';

import '../../../components/label_text.dart';
import '../../../lib/dashboard_provider/apiresponseprovider.dart';
import '../../../lib/dashboard_provider/user_provider.dart';
import '../../../model/apiresponse_model.dart';
import '../../../model/user_model.dart';
import '../../../services/loader_service.dart';
import '../../../utils/alert_helper.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final MemberCreatorResponse user;
  const ProfileScreen({super.key, required this.user});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ValueNotifier<File?> _imageNotifier = ValueNotifier<File?>(null);
  String? _uploadedImageUrl;
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

      setState(() {
        _uploadedImageUrl = imageUrl;
      });

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


  Future<String> _uploadFileToCloudinary(
      {required File file,
        required String resourceType,
        required String preset}) async {
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
      "profile_image": imageUrl,
    };

    try {
      await ref.read(apiresponseProvider.notifier).updateProfile(context:context,payload: payload);
      showCustomAlert(
        context: context,
        isSuccess: true,
        title: 'Success',
        message: 'Profile image updated successfully.',
      );
    } catch (error) {
      String errorMessage = 'An unexpected error occurred';
      if (error is DioException && error.response?.data != null) {
        try {
          final apiResponse = ApiResponseModel.fromJson(error.response?.data);
          errorMessage = apiResponse.message;
        } catch (_) {}
      }
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: errorMessage,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    const Color cardBackgroundColor = Color(0xFF1A191E); // Slightly lighter for cards
    const Color textColor = Colors.white;
    const Color hintTextColor = Colors.white70; // For labels


    Future<void> editJobTitle(String newJobTitle) async {
      final payload = {
        "job_title": newJobTitle,
      };

      try {
        final response = await ref.read(apiresponseProvider.notifier).editJobTitle(
          context: context,
          payload: payload,
        );

        // Reload updated user info
        await ref.read(userProvider.notifier).loadUserProfile();

        showCustomAlert(
          context: context,
          isSuccess: true,
          title: 'Success',
          message: 'Job title updated successfully',
        );

      } catch (error) {
        String errorMessage = 'An unexpected error occurred';

        if (error is DioException) {
          if (error.response?.data != null) {
            try {
              final apiResponse = ApiResponseModel.fromJson(error.response?.data);
              errorMessage = apiResponse.message;
            } catch (e) {
              errorMessage = 'Failed to parse error message';
            }
          } else {
            errorMessage = error.message ?? 'Network error occurred';
          }
        }

        print("Error: $errorMessage");
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
        "bio_description": description,
      };

      try {
        final response = await ref.read(apiresponseProvider.notifier).editDescription(
          context: context,
          payload: payload,
        );

        // Reload updated user info
        await ref.read(userProvider.notifier).loadUserProfile();

        showCustomAlert(
          context: context,
          isSuccess: true,
          title: 'Success',
          message: 'Bio Description updated successfully',
        );

      } catch (error) {
        String errorMessage = 'An unexpected error occurred';

        if (error is DioException) {
          if (error.response?.data != null) {
            try {
              final apiResponse = ApiResponseModel.fromJson(error.response?.data);
              errorMessage = apiResponse.message;
            } catch (e) {
              errorMessage = 'Failed to parse error message';
            }
          } else {
            errorMessage = error.message ?? 'Network error occurred';
          }
        }

        print("Error: $errorMessage");
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
        final response = await ref.read(apiresponseProvider.notifier).editSocials(
          context: context,
          payload: payload,
        );

        // Reload updated user info
        await ref.read(userProvider.notifier).loadUserProfile();

        showCustomAlert(
          context: context,
          isSuccess: true,
          title: 'Success',
          message: 'Socials updated successfully',
        );

      } catch (error) {
        String errorMessage = 'An unexpected error occurred';

        if (error is DioException) {
          if (error.response?.data != null) {
            try {
              final apiResponse = ApiResponseModel.fromJson(error.response?.data);
              errorMessage = apiResponse.message;
            } catch (e) {
              errorMessage = 'Failed to parse error message';
            }
          } else {
            errorMessage = error.message ?? 'Network error occurred';
          }
        }

        print("Error: $errorMessage");
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: errorMessage,
        );
      }
    }
    void showEditJobTitleSheet(BuildContext context, String currentJobTitle) {
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
            },
          );
        },
      );
    }

    void showEditBioDescriptionSheet(BuildContext context, String currentBio) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return EditTextFieldBottomSheet(
            title: 'Edit Bio Description',
            initialValue: currentBio,
            hintText: 'I am a professional voice-over artist...',
            isMultiline: true, // Set to true for multiline input
            onSave: (newValue) {
              if (newValue.trim().isEmpty) return;
              editDescription(newValue);
            },
          );
        },
      );
    }

    void showEditSocialsSheet(BuildContext context, Map<String, String> currentSocials) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true, // Allows the bottom sheet to take full height if needed
        backgroundColor: Colors.transparent, // Make background transparent to show custom shape
        builder: (BuildContext context) {
          return EditSocialsBottomSheet(
            initialSocials: currentSocials,
            onSave: (newSocials) {
              if (newSocials.isEmpty) return;
              editSocials(newSocials);
            },
          );
        },
      );
    }
    final user = ref.watch(userProvider);
    final creator = user.value?.creator;

    final instagram = creator?.instagram;
    final linkedin = creator?.linkedin;
    final x = creator?.x;

    final socials = {
      if (instagram != null && instagram.isNotEmpty) 'instagram': instagram,
      if (linkedin != null && linkedin.isNotEmpty) 'linkedin': linkedin,
      if (x != null && x.isNotEmpty) 'x': x,
    };

    return Scaffold(
      backgroundColor: AppColors.BACKGROUNDCOLOR,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0, // No shadow
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () {
            // Implement navigation back
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
              child: const Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10,),
            // Profile Picture Section
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.BUTTONCOLOR,
              backgroundImage: (user.value?.member?.profileImage != null)
                  ? NetworkImage(user.value!.member!.profileImage!)
                  : null,
              child: (user.value?.member?.profileImage == null)
                  ? Text(
                widget.user.member!.firstName.isNotEmpty
                    ? widget.user.member!.firstName[0].toUpperCase()
                    : '',
                style: const TextStyle(fontSize: 24, color: Colors.white),
              )
                  : null,
            ),

            const SizedBox(height: 12),
            Text(
              "${widget.user.member!.firstName} ${widget.user.member!.lastName}",
              style: const TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickAndUploadImage,
              icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFFB0B0B6), size: 12),
              label: const Text(
                'Change profile picture',
                style: TextStyle(color: Color(0xFFB0B0B6), fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2C2C2C)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
            const SizedBox(height: 30),

            // Job Title Card
            _buildInfoCard(
              label: 'Job Title',
              value: user.value?.creator?.jobTitle ?? 'Not specified',
              hasEdit: true,
              onEdit: () {
                showEditJobTitleSheet(context, user.value?.creator?.jobTitle ?? '');
              },
              cardBackgroundColor: cardBackgroundColor,
              textColor: textColor,
              hintTextColor: hintTextColor,
            ),
            const SizedBox(height: 16),

            // Bio Description Card
            _buildInfoCard(
              label: 'Bio Description',
              value: user.value?.creator?.bioDescription ?? 'No bio provided.',
              hasEdit: true,
              onEdit: () {
                showEditBioDescriptionSheet(context, user.value?.creator?.bioDescription ?? 'No bio provided.');
              },
              cardBackgroundColor: cardBackgroundColor,
              textColor: textColor,
              hintTextColor: hintTextColor,
            ),
            const SizedBox(height: 16),

            // Where are you based? Card
            _buildInfoCard(
              label: 'Where are you based?',
              value: widget.user.creator?.location ?? 'Not specified',
              hasEdit: false,
              cardBackgroundColor: cardBackgroundColor,
              textColor: textColor,
              hintTextColor: hintTextColor,
            ),
            const SizedBox(height: 16),

            // Socials Card
          _buildSocialsCard(
            socials: socials,
            onEdit: () {
              showEditSocialsSheet(context, socials);
            },
            cardBackgroundColor: cardBackgroundColor,
            textColor: textColor,
            hintTextColor: hintTextColor,
          ),
          const SizedBox(height: 16),

            // Other Information Card
            Utils.buildOtherInfoCard(
              user: widget.user,
              cardBackgroundColor: cardBackgroundColor,
              textColor: textColor,
              hintTextColor: hintTextColor,
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build a generic info card
  Widget _buildInfoCard({
    required String label,
    required String value,
    required bool hasEdit,
    VoidCallback? onEdit,
    required Color cardBackgroundColor,
    required Color textColor,
    required Color hintTextColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
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
                  color: hintTextColor,
                  fontSize: 14,
                ),
              ),
              if (hasEdit)
                GestureDetector(
                  onTap: onEdit,
                  child: Icon(Icons.edit, color: hintTextColor, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to build the socials card
  Widget _buildSocialsCard({
    required Map<String, String>? socials,
    VoidCallback? onEdit,
    required Color cardBackgroundColor,
    required Color textColor,
    required Color hintTextColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
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
                  color: hintTextColor,
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Icon(Icons.edit_outlined, color: hintTextColor, size: 18),
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
                      entry.key, // Capitalize the social media name
                      style: TextStyle(
                        color: hintTextColor,
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
                        color: textColor,
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
                color: hintTextColor,
                fontSize: 16,
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
  // Initial socials map: { 'linkedin': 'bit.ly/johnnyboy', 'x': '', 'instagram': '...' }
  final Map<String, String> initialSocials;
  final Function(Map<String, String> newSocials) onSave;

  const EditSocialsBottomSheet({
    super.key,
    required this.initialSocials,
    required this.onSave,
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

  // Map to hold controllers for each social platform
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    for (var platform in _fixedSocialPlatforms) {
      // Initialize controller with existing value or empty string
      _controllers[platform] = TextEditingController(
        text: widget.initialSocials[platform] ?? '',
      );
    }
  }

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A191E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Edit Socials',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Dynamically create input fields for each fixed social platform
          ..._fixedSocialPlatforms.map((platform) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platform,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controllers[platform],
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter link',
                      hintStyle: const TextStyle(color: Color(0xFF7C7C88)),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color:  AppColors.FORMGREYCOLOR,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF7C7C88), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    cursorColor: Color(0xFF7C7C88),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 30),

          RoundedButton(
            title: 'Save Changes',
            onPressed: () {
              // Collect all current social links from controllers
              Map<String, String> newSocials = {};
              _controllers.forEach((platform, controller) {
                if (controller.text.isNotEmpty) {
                  newSocials[platform] = controller.text;
                }
              });
              widget.onSave(newSocials); // Call the onSave callback
              Navigator.pop(context);
            },
            color: AppColors.BUTTONCOLOR,
          ),
          // Add padding to avoid keyboard overlap
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
  final Function(String newValue) onSave;

  const EditTextFieldBottomSheet({
    super.key,
    required this.title,
    required this.initialValue,
    this.hintText = '',
    this.isMultiline = false,
    required this.onSave,
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
    return Container(
      // Apply consistent background color and top rounded corners
      decoration: const BoxDecoration(
        color: Color(0xFF1A191E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Make the column take minimum space
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Text input field
          LabeledTextField(
            label: '',
            controller: _controller,
            hintText: widget.hintText,
            keyboardType: widget.isMultiline
                ? TextInputType.multiline
                : TextInputType.text,
            maxLines: widget.isMultiline ? 4 : 1,

          ),
          const SizedBox(height: 30),
          RoundedButton(
              title: 'Save changes',
            color: AppColors.BUTTONCOLOR,
            onPressed: () {
              widget.onSave(_controller.text); // Call the onSave callback
              Navigator.pop(context); // Close the bottom sheet after saving
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