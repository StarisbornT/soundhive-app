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

class VerifyIdentity extends ConsumerStatefulWidget {
  final User user;
  const VerifyIdentity({super.key, required this.user});

  @override
  _VerifyIdentityScreenState createState() => _VerifyIdentityScreenState();
}

class _VerifyIdentityScreenState extends ConsumerState<VerifyIdentity> {
  late TextEditingController bvnController;
  late TextEditingController ninController;
  late TextEditingController genderController;
  TextEditingController idTypeController = TextEditingController();
  TextEditingController copyOfIdController = TextEditingController();
  TextEditingController utilityBillController = TextEditingController();
  final ValueNotifier<File?> _imageNotifier = ValueNotifier<File?>(null);
  final ValueNotifier<File?> _utilityNotifier = ValueNotifier<File?>(null);

  String? selectedGender;
  String? selectedIdType;
  String? selectedUtility;

  @override
  void initState() {
    super.initState();
    bvnController = TextEditingController(
      text: widget.user.bvn ?? '',
    );
    ninController = TextEditingController(
      text: widget.user.nin ?? '',
    );
    genderController = TextEditingController(
      text: widget.user.gender ?? '',
    );
  }
  final List<Map<String, String>> gender =[
    {'label': 'Male', 'value': 'male'},
    {'label': 'Female', 'value': 'female'},
  ];
  final List<Map<String, String>> utilityBill =[
    {'label': 'Light Bill', 'value': 'light_bill'},
  ];
  final List<Map<String, String>> idTypeOptions = [
    {'label': 'National ID', 'value': 'national_id'},
    {'label': 'Driver License', 'value': 'driver_license'},
    {'label': 'International Passport', 'value': 'international_passport'},
    {'label': 'Voter Card', 'value': 'voter_card'},
  ];
  String? _uploadedImageUrl;
  String? _uploadedUtilityUrl;


  Future<void> _uploadMediaToCloudinary() async {
    final imageFile = _imageNotifier.value;
    final utilityFile = _utilityNotifier.value;

    if (imageFile == null || utilityFile == null) {
      throw Exception('Image or utility bill is missing');
    }

    // Upload both images
    final imageUrl = await _uploadFileToCloudinary(
      file: imageFile,
      resourceType: 'image',
      preset: 'soundhive',
    );

    final utilityUrl = await _uploadFileToCloudinary(
      file: utilityFile,
      resourceType: 'image',
      preset: 'soundhive',
    );

    _uploadedImageUrl = imageUrl; // For ID image
    _uploadedUtilityUrl = utilityUrl; // Add this new variable
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

    // ✅ Check that all fields are filled before proceeding
    if (selectedGender == null || selectedGender!.isEmpty) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Missing Field',
        message: 'Please select your gender',
      );
      return;
    }

    if (bvnController.text.trim().isEmpty) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Missing Field',
        message: 'Please enter your BVN',
      );
      return;
    }

    if (ninController.text.trim().isEmpty) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Missing Field',
        message: 'Please enter your NIN',
      );
      return;
    }

    if (selectedIdType == null || selectedIdType!.isEmpty) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Missing Field',
        message: 'Please select your ID type',
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

    if (selectedUtility == null || selectedUtility!.isEmpty) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Missing Field',
        message: 'Please select a Utility Bill type',
      );
      return;
    }

    if (_utilityNotifier.value == null) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Missing Field',
        message: 'Please upload your Utility Bill',
      );
      return;
    }

    // ✅ If all checks pass, continue with your existing logic
    try {
      LoaderService.showLoader(context);

      final imageFile = _imageNotifier.value!;
      final utilityFile = _utilityNotifier.value!;

      bool isImageValid = await _isValidLocalPath(imageFile.path);
      bool isUtilityValid = await _isValidLocalPath(utilityFile.path);

      if (!await imageFile.exists() || !isImageValid) {
        throw Exception('Invalid or missing ID image file');
      }

      if (!await utilityFile.exists() || !isUtilityValid) {
        throw Exception('Invalid or missing Utility Bill file');
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

    final response = await ref.read(apiresponseProvider.notifier).verifyIdentity(
      context: context,
     payload: {
       "gender": selectedGender,
       "bvn": bvnController.text,
       "nin": ninController.text,
       "id_type": selectedIdType,
       "copy_of_id": _uploadedImageUrl,
       "utility_bill" : selectedUtility,
       "copy_of_utility_bill": _uploadedUtilityUrl,
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
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100), // Add space for button
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
                    LabeledSelectField(
                      label: "Gender",
                      controller: genderController,
                      items: gender,
                      hintText: 'Select gender',
                      onChanged: (value) {
                        selectedGender= value;
                      },
                    ),
                    const SizedBox(height: 10),
                    LabeledTextField(
                      label: 'Bank Verification Number (BVN)',
                      controller: bvnController,
                      keyboardType: TextInputType.number,
                      hintText: 'Enter your BVN',
                      secondLabel: 'Why this?',
                    ),
                    const SizedBox(height: 10),
                    LabeledTextField(
                      label: 'National Identification Number (NIN)',
                      controller: ninController,
                      keyboardType: TextInputType.number,
                      hintText: 'Enter your NIN',
                      secondLabel: 'Why this?',
                    ),
                    const SizedBox(height: 10),
                    LabeledSelectField(
                      label: "ID Type",
                      controller: idTypeController,
                      items: idTypeOptions,
                      hintText: 'Select an ID Type',
                      onChanged: (value) {
                        selectedIdType = value;
                      },
                    ),
                    const SizedBox(height: 10),
                    ImagePickerComponent(
                      labelText: 'Copy of ID',
                      imageNotifier: _imageNotifier,
                      hintText: 'Upload Document',
                      validator: (value) {
                        if (value == null) {
                          return ' image is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    LabeledSelectField(
                      label: "Utility Bill",
                      controller: utilityBillController,
                      items: utilityBill,
                      hintText: 'Select an Utility Bill',
                      onChanged: (value) {
                        selectedUtility  = value;
                      },
                    ),
                    ImagePickerComponent(
                      labelText: 'Copy of Utility',
                      imageNotifier: _utilityNotifier,
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
                  color: AppColors.BUTTONCOLOR,
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
