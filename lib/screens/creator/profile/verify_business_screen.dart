import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soundhive2/components/label_text.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/utils/app_colors.dart';
import '../../../components/image_picker.dart';
import '../../../components/success.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import '../../../model/apiresponse_model.dart';
import '../../../model/user_model.dart';
import '../../../services/loader_service.dart';
import '../../../utils/alert_helper.dart';
import '../creator_dashboard.dart';

class VerifyBusinessScreen extends ConsumerStatefulWidget {
  final User user;
  const VerifyBusinessScreen({super.key, required this.user});

  @override
  ConsumerState<VerifyBusinessScreen> createState() => _VerifyBusinessScreenState();
}

class _VerifyBusinessScreenState extends ConsumerState<VerifyBusinessScreen> {
  late TextEditingController businessNameController;
  late TextEditingController phoneNumberController;
  late TextEditingController emailAddressController;
  TextEditingController addressController = TextEditingController();
  TextEditingController bvnController = TextEditingController();
  final ValueNotifier<File?> _imageNotifier = ValueNotifier<File?>(null);

  @override
  void initState() {
    super.initState();

    businessNameController = TextEditingController(

    );

    phoneNumberController = TextEditingController(

    );

    emailAddressController = TextEditingController(

    );

    addressController = TextEditingController(
    );

    bvnController = TextEditingController(
      text: widget.user.bvn ?? '',
    );
  }

  String? _uploadedImageUrl;
  @override
  void dispose() {
    businessNameController.dispose();
    phoneNumberController.dispose();
    emailAddressController.dispose();
    addressController.dispose();
    bvnController.dispose();
    super.dispose();
  }



  Future<void> _uploadMediaToCloudinary() async {
    final imageFile = _imageNotifier.value;

    if (imageFile == null) {
      throw Exception('Image or utility bill is missing');
    }

    // Upload both images
    final imageUrl = await _uploadFileToCloudinary(
      file: imageFile,
      resourceType: 'image',
      preset: 'soundhive',
    );


    _uploadedImageUrl = imageUrl; // For ID image
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

  Future<bool> _isValidLocalPath(String path) async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = tempDir.path;
    // Check if the path is in the app's temporary directory or a valid URI
    return path.startsWith(tempPath) ||
        path.startsWith('/data') ||
        path.startsWith('file://') ||
        path.startsWith('content://');
  }

  void _submitForm() async {
    print('🔄 Starting submission');

    if (bvnController.text.trim().isEmpty) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Missing Field',
        message: 'Please enter your BVN',
      );
      return;
    }

    if (_imageNotifier.value == null) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Missing Field',
        message: 'Please upload a copy of your ID',
      );
      return;
    }


    // ✅ If all checks pass, continue with your existing logic
    try {
      LoaderService.showLoader(context);

      final imageFile = _imageNotifier.value!;

      bool isImageValid = await _isValidLocalPath(imageFile.path);

      if (!await imageFile.exists() || !isImageValid) {
        throw Exception('Invalid or missing ID image file');
      }

      // Upload both files
      await _uploadMediaToCloudinary();

      // Submit to backend
      await _submitToBackend();

      LoaderService.hideLoader(context);
      await ref.read(userProvider.notifier).loadUserProfile();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Success(
            title: 'Your information has been submitted successfully',
            subtitle:
            'Your account is currently under review, and will get feedback within the next 24 hours',
            onButtonPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreatorDashboard()),
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
          } catch (e) {
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

  Future<ApiResponseModel> _submitToBackend() async {

    final response = await ref.read(apiresponseProvider.notifier).verifyBusiness(
        context: context,
        payload: {
          "business_name": businessNameController.text,
          "business_phone": phoneNumberController.text,
          "business_email": emailAddressController.text,
          "business_address": addressController.text,
          "bvn" : bvnController.text,
          "cac_docs": _uploadedImageUrl,
        }
    );
    if(!response.status) {
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
      backgroundColor: const Color(0xFF0C0513),
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
                        icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFB0B0B6)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Verify your Identity',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Kindly provide the information below',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 40),
                      LabeledTextField(
                        label: 'Business Name',
                        controller: businessNameController,
                        hintText: 'Enter your Business Name',
                      ),
                      const SizedBox(height: 10),
                      LabeledTextField(
                        label: 'Phone Number',
                        controller: phoneNumberController,
                        keyboardType: TextInputType.number,
                        hintText: 'Enter your Business Number',
                      ),
                      const SizedBox(height: 10),
                      LabeledTextField(
                        label: 'Email Address',
                        controller: emailAddressController,
                        keyboardType: TextInputType.emailAddress,
                        hintText: 'Enter your Business Email address',
                      ),
                      const SizedBox(height: 10),
                      LabeledTextField(
                        label: 'Address',
                        controller: addressController,
                        hintText: 'Enter address',
                      ),
                      const SizedBox(height: 10),
                      LabeledTextField(
                        label: 'BVN of a listed director',
                        controller: bvnController,
                        keyboardType: TextInputType.number,
                        hintText: 'Enter your BVN',
                        secondLabel: 'Why this?',
                      ),
                      const SizedBox(height: 10),
                      ImagePickerComponent(
                        labelText: 'Copy of CAC document',
                        imageNotifier: _imageNotifier,
                        hintText: 'Upload Document',
                        validator: (value) {
                          if (value == null) {
                            return ' image is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Fixed button
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: RoundedButton(
                    title: 'Submit',
                    onPressed: () {
                      _submitForm();
                    },
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
