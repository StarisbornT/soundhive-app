import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
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

class CreateArtistProfile extends ConsumerStatefulWidget {
  final User user;
  const CreateArtistProfile({super.key, required this.user});

  @override
  ConsumerState<CreateArtistProfile> createState() => _CreateArtistProfileScreenState();
}

class _CreateArtistProfileScreenState extends ConsumerState<CreateArtistProfile> {
  late TextEditingController artistUserNameController;

  final ValueNotifier<File?> _profilePhotoNotifier = ValueNotifier<File?>(null);
  final ValueNotifier<File?> _coverPhotoNotifier = ValueNotifier<File?>(null);

  String? _uploadedProfileUrl;
  String? _uploadedCoverUrl;

  @override
  void initState() {
    super.initState();
    artistUserNameController = TextEditingController();
  }

  @override
  void dispose() {
    artistUserNameController.dispose();
    super.dispose();
  }

  /// Upload both profile & cover photos
  Future<void> _uploadMediaToCloudinary() async {
    final profileFile = _profilePhotoNotifier.value;
    final coverFile = _coverPhotoNotifier.value;

    if (profileFile == null || coverFile == null) {
      throw Exception('Profile or cover photo is missing');
    }

    final profileUrl = await _uploadFileToCloudinary(
      file: profileFile,
      resourceType: 'image',
      preset: 'soundhive',
    );

    final coverUrl = await _uploadFileToCloudinary(
      file: coverFile,
      resourceType: 'image',
      preset: 'soundhive',
    );

    _uploadedProfileUrl = profileUrl;
    _uploadedCoverUrl = coverUrl;
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

  /// Check if the path is valid and local
  Future<bool> _isValidLocalPath(String path) async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = tempDir.path;

    return path.startsWith(tempPath) ||
        path.startsWith('/data') ||
        path.startsWith('file://') ||
        path.startsWith('content://');
  }

  /// Submit form to backend
  void _submitForm() async {
    print('🔄 Starting submission');

    if (artistUserNameController.text.trim().isEmpty) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Missing Field',
        message: 'Please enter your artist username',
      );
      return;
    }

    if (_profilePhotoNotifier.value == null) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Missing Field',
        message: 'Please upload your profile photo',
      );
      return;
    }

    if (_coverPhotoNotifier.value == null) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Missing Field',
        message: 'Please upload your cover photo',
      );
      return;
    }

    try {
      LoaderService.showLoader(context);

      final profileFile = _profilePhotoNotifier.value!;
      final coverFile = _coverPhotoNotifier.value!;

      bool isProfileValid = await _isValidLocalPath(profileFile.path);
      bool isCoverValid = await _isValidLocalPath(coverFile.path);

      if (!await profileFile.exists() || !isProfileValid) {
        throw Exception('Invalid or missing profile photo');
      }

      if (!await coverFile.exists() || !isCoverValid) {
        throw Exception('Invalid or missing cover photo');
      }

      await _uploadMediaToCloudinary();

      await _submitToBackend();

      LoaderService.hideLoader(context);
      final user = await ref.read(userProvider.notifier).loadUserProfile();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Success(
            title: 'Your profile has been created successfully!',
            subtitle: 'You can now start sharing your music and content.',
            onButtonPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ArtistProfileScreen(user: user!,)),
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
    } finally {
      LoaderService.hideLoader(context);
    }
  }

  /// Send final payload to backend
  Future<ApiResponseModel> _submitToBackend() async {
    final response =
    await ref.read(apiresponseProvider.notifier).createArtistProfile(
      context: context,
      payload: {
        "username": artistUserNameController.text.trim(),
        "profile_photo": _uploadedProfileUrl,
        "cover_photo": _uploadedCoverUrl,
      },
    );

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
     
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Scrollable form
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Setup your artist profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 40),
                      LabeledTextField(
                        label: 'Artist Username',
                        controller: artistUserNameController,
                        hintText: 'E.g Davido',
                      ),
                      const SizedBox(height: 10),
                      ImagePickerComponent(
                        labelText: 'Upload profile photo',
                        imageNotifier: _profilePhotoNotifier,
                        hintText: 'Upload profile photo',
                        validator: (value) =>
                        value == null ? 'Profile photo is required' : null,
                      ),
                      const SizedBox(height: 10),
                      ImagePickerComponent(
                        labelText: 'Upload cover photo',
                        imageNotifier: _coverPhotoNotifier,
                        hintText: 'Upload cover photo',
                        validator: (value) =>
                        value == null ? 'Cover photo is required' : null,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Fixed submit button
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: RoundedButton(
                    title: 'Submit',
                    onPressed: _submitForm,
                    color: AppColors.PRIMARYCOLOR,
                    borderWidth: 0,
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

