import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/components/label_text.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/screens/creator/artist_arena/artist_profile_screen.dart';
import 'package:soundhive2/utils/app_colors.dart';
import '../../../components/image_picker.dart';
import '../../../components/success.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import '../../../model/apiresponse_model.dart';
import '../../../model/user_model.dart';
import '../../../services/loader_service.dart';
import '../../../utils/alert_helper.dart';

class EditArtistProfile extends ConsumerStatefulWidget {
  final Artist user;
  const EditArtistProfile({super.key, required this.user});

  @override
  _EditArtistProfileScreenState createState() => _EditArtistProfileScreenState();
}

class _EditArtistProfileScreenState extends ConsumerState<EditArtistProfile> {
  late TextEditingController artistUserNameController;

  final ValueNotifier<File?> _profilePhotoNotifier = ValueNotifier<File?>(null);
  final ValueNotifier<File?> _coverPhotoNotifier = ValueNotifier<File?>(null);

  String? _uploadedProfileUrl;
  String? _uploadedCoverUrl;

  @override
  void initState() {
    super.initState();
    artistUserNameController = TextEditingController();
    _prefillFormData();
  }

  /// Prefill all form fields with existing artist data
  void _prefillFormData() {
    final artist = widget.user;

    // Prefill username
    artistUserNameController.text = artist.userName ?? '';

    // Prefill profile photo and cover photo URLs if available
    if (artist.profilePhoto != null && artist.profilePhoto!.isNotEmpty) {
      _uploadedProfileUrl = artist.profilePhoto;
    }

    if (artist.coverPhoto != null && artist.coverPhoto!.isNotEmpty) {
      _uploadedCoverUrl = artist.coverPhoto;
    }
  }

  @override
  void dispose() {
    artistUserNameController.dispose();
    super.dispose();
  }

  /// Upload both profile & cover photos to Cloudinary
  Future<void> _uploadMediaToCloudinary() async {
    final profileFile = _profilePhotoNotifier.value;
    final coverFile = _coverPhotoNotifier.value;

    if (profileFile != null) {
      _uploadedProfileUrl = await _uploadFileToCloudinary(
        file: profileFile,
        resourceType: 'image',
        preset: 'soundhive',
      );
    }

    if (coverFile != null) {
      _uploadedCoverUrl = await _uploadFileToCloudinary(
        file: coverFile,
        resourceType: 'image',
        preset: 'soundhive',
      );
    }
  }

  /// Upload a single file to Cloudinary
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

  /// Submit form to backend
  Future<void> _submitForm() async {
    if (artistUserNameController.text.trim().isEmpty) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Missing Field',
        message: 'Please enter your artist username',
      );
      return;
    }

    try {
      LoaderService.showLoader(context);

      // Upload images only if new files were selected
      await _uploadMediaToCloudinary();

      // Send to backend
      await _submitToBackend();

      LoaderService.hideLoader(context);

      // Reload user data
      final user = await ref.read(userProvider.notifier).loadUserProfile();

      // Navigate to success screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Success(
            title: 'Your profile has been updated successfully!',
            subtitle: 'You can now continue sharing your music and content.',
            onButtonPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArtistProfileScreen(user: user!),
                ),
              );
            },
          ),
        ),
      );
    } catch (error) {
      LoaderService.hideLoader(context);
      String errorMessage = 'An unexpected error occurred';
      print('FULL ERROR DETAILS: $error');

      if (error is DioException) {
        if (error.response?.data != null) {
          try {
            final apiResponse = ApiResponseModel.fromJson(error.response?.data);
            errorMessage = apiResponse.message;
          } catch (_) {
            errorMessage = 'Failed to parse error message';
          }
        } else {
          errorMessage = error.message ?? 'Network error occurred';
        }
      }

      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: errorMessage,
      );
    }
  }

  /// Send final payload to backend
  Future<ApiResponseModel> _submitToBackend() async {
    final payload = {
      "username": artistUserNameController.text.trim(),
      "profile_photo": _uploadedProfileUrl,
      "cover_photo": _uploadedCoverUrl,
    };

    final response = await ref
        .read(apiresponseProvider.notifier)
        .updateArtistProfile(context: context, payload: payload, id: widget.user.id);

    if (!response.status) {
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          data: {'message': response.message},
        ),
      );
    }

    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.BACKGROUNDCOLOR,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFB0B0B6)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Edit your artist profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Artist Username
                      LabeledTextField(
                        label: 'Artist Username',
                        controller: artistUserNameController,
                        hintText: 'E.g Davido',
                      ),
                      const SizedBox(height: 10),

                      // Profile Photo Picker
                      ImagePickerComponent(
                        labelText: 'Upload profile photo',
                        imageNotifier: _profilePhotoNotifier,
                        hintText: 'Upload profile photo',
                        initialImageUrl: widget.user.profilePhoto,
                        validator: (value) =>
                        value == null ? 'Profile photo is required' : null,
                      ),
                      const SizedBox(height: 10),

                      // Cover Photo Picker
                      ImagePickerComponent(
                        labelText: 'Upload cover photo',
                        imageNotifier: _coverPhotoNotifier,
                        initialImageUrl: widget.user.coverPhoto,
                        hintText: 'Upload cover photo',
                        validator: (value) =>
                        value == null ? 'Cover photo is required' : null,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Submit Button (fixed at bottom)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: RoundedButton(
                    title: 'Submit',
                    onPressed: _submitForm,
                    color: AppColors.PRIMARYCOLOR,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}


