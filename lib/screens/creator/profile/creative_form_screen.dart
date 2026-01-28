import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:soundhive2/components/label_text.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/model/category_model.dart';
import 'package:soundhive2/utils/app_colors.dart';

import '../../../components/success.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import '../../../model/apiresponse_model.dart';
import '../../../model/user_model.dart';
import '../../../services/loader_service.dart';
import '../../../utils/alert_helper.dart';
import '../creator_dashboard.dart';

class CreativeFormScreen extends ConsumerStatefulWidget {
  final User user;
  const CreativeFormScreen({super.key, required this.user});

  @override
  ConsumerState<CreativeFormScreen> createState() => _CreativeFormScreenState();
}

extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
class PortfolioData {
  final ValueNotifier<File?> coverNotifier = ValueNotifier<File?>(null);
  final ValueNotifier<File?> imageNotifier = ValueNotifier<File?>(null);
  final ValueNotifier<File?> audioNotifier = ValueNotifier<File?>(null);
  final TextEditingController linkController = TextEditingController();
  final ValueNotifier<List<String>> selectedFormats = ValueNotifier([]);

  String? coverUrl;
  String? imageUrl;
  String? audioUrl;

  void dispose() {
    coverNotifier.dispose();
    imageNotifier.dispose();
    audioNotifier.dispose();
    linkController.dispose();
    selectedFormats.dispose();
  }
}



class _CreativeFormScreenState extends ConsumerState<CreativeFormScreen> {
  int _currentStep = 0;

  List<Category> services = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<Category> selectedServices = [];
  final Map<Category, TextEditingController> rateControllers = {};
  final Map<Category, PortfolioData> portfolioData = {};
  late List<DateTime> availablityDates = [];
  final TextEditingController jobTitleController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  TextEditingController currencyController = TextEditingController();

  // Social media controllers
  final TextEditingController linkedInController = TextEditingController();
  final TextEditingController xController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();


  bool _isSubmitting = false;
  final Logger _logger = Logger();

  late List<Map<String, String>> currencies;

  String? selectedCurrency;

  @override
  void initState() {
    super.initState();
    currencies = [
      {'label': widget.user.wallet!.currency, 'value': widget.user.wallet!.currency},
      {'label': 'USD', 'value': 'USD'},
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) async {

      setState(() {
        // Initialize controllers for any pre-selected services
        for (var service in selectedServices) {
          portfolioData[service] = PortfolioData();
          rateControllers[service] = TextEditingController();
        }
      });
    });
  }
  @override
  void dispose() {
    // Dispose all controllers
    jobTitleController.dispose();
    bioController.dispose();
    locationController.dispose();
    linkedInController.dispose();
    xController.dispose();
    instagramController.dispose();

    // Dispose rate controllers - NEW
    for (var controller in rateControllers.values) {
      controller.dispose();
    }

    // Dispose portfolio data - NEW
    for (var data in portfolioData.values) {
      data.dispose();
    }

    super.dispose();
  }



  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    _isSubmitting = true;

    try {
      LoaderService.showLoader(context);

      // Upload all media files
      await _uploadAllMedia();

      // Submit to backend
      await _submitToBackend();

      // Navigate to success screen

      if (!mounted) return;

      // 4. Hide loader before navigation
      LoaderService.hideLoader(context);

      // 5. Navigate to success screen first
    final user = await ref.read(userProvider.notifier).loadUserProfile();
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Success(
            title: 'Your information has been submitted successfully',
            subtitle: 'Your account is currently under review, and will get feedback within the next 24hours',
            onButtonPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => CreatorDashboard()),
              );
            },
          ),
        ),
      );
    } catch (error) {
      _logger.e("Submission Error", error: error);
      LoaderService.hideLoader(context);

      String errorMessage = 'An unexpected error occurred';

      // Print full error details for debugging
      print('FULL ERROR DETAILS: $error');

      // Handle different Dio error types
      if (error is DioException) {
        if (error.response?.data != null) {
          try {
            final apiResponse = ApiResponseModel.fromJson(
                error.response?.data);
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

      // Show the alert with the error message
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: errorMessage,
      );
      return;
    } finally {
      if(mounted){
        LoaderService.hideLoader(context);
      }
      _isSubmitting = false;

    }
  }
  Future<void> _uploadServiceMedia(PortfolioData data) async {
    // Upload cover image
    if (data.coverNotifier.value != null) {
      data.coverUrl = await _uploadFileToCloudinary(
        file: data.coverNotifier.value!,
        resourceType: 'image',
        preset: 'soundhive',
      );
    }

    // Upload other media based on selected formats
    for (final format in data.selectedFormats.value) {
      if (format == 'image' && data.imageNotifier.value != null) {
        data.imageUrl = await _uploadFileToCloudinary(
          file: data.imageNotifier.value!,
          resourceType: 'image',
          preset: 'soundhive',
        );
      }
      else if (format == 'audio' && data.audioNotifier.value != null) {
        data.audioUrl = await _uploadFileToCloudinary(
          file: data.audioNotifier.value!,
          resourceType: 'video',
          preset: 'soundhive',
        );
      }
    }
  }
  Future<void> _uploadAllMedia() async {
    // Helper function to upload a portfolio section
    final futures = <Future>[];

    for (var service in selectedServices) {
      final data = portfolioData[service]!;
      futures.add(_uploadServiceMedia(data));
    }

    await Future.wait(futures);
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
      throw Exception('$resourceType upload failed: ${response.statusMessage}');
    }

    return response.data['secure_url'] as String;
  }



  Future<ApiResponseModel> _submitToBackend() async {
    final payload = {
      "job_title": jobTitleController.text,
      "bio": bioController.text,
      "location": locationController.text,
      "base_currency": selectedCurrency,
      "linkedin": linkedInController.text.isNotEmpty ? linkedInController.text : null,
      "x": xController.text.isNotEmpty ? xController.text : null,
      "instagram": instagramController.text.isNotEmpty ? instagramController.text : null,
    };

    try {
      final response = await ref.read(apiresponseProvider.notifier).createCreativeProfile(
        context: context,
        payload: payload,
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
    } catch (error) {
      _logger.e("Backend submission failed", error: error);
      rethrow; // Rethrow to be caught in _submitForm
    }
  }

  final List<Map<String, String>> portfolioFormat =[
    {'label': 'Image', 'value': 'image'},
    {'label': 'Link', 'value': 'link'},
    {'label': 'Audio', 'value': 'audio'},
  ];

  void _nextStep() {
    // Validate only if not on the last step
    if (_currentStep < 5) {
      final isValid = _validateCurrentStep();
      if (!isValid) return;

      setState(() {
        _currentStep++;
      });
    }
  }

  void _handleContinue() {
    if (_currentStep == 0) {
      _submitForm();
    } else {
      _nextStep();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Bio Step
        if (jobTitleController.text.isEmpty) {
          _showError("Job title is required");
          return false;
        }
        if (bioController.text.isEmpty) {
          _showError("Bio description is required");
          return false;
        }
        if (selectedCurrency == null && selectedCurrency!.isEmpty) {
          _showError("Currency is required");
          return false;
        }
        if (locationController.text.isEmpty) {
          _showError("Location is required");
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  void _showError(String message) {
    showCustomAlert(
        context: context,
        isSuccess: false,
        title: "Error",
        message: message
    );
    }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        2,
            (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 150,
          height: 4,
          decoration: BoxDecoration(
            color: index <= _currentStep ? AppColors.BUTTONCOLOR : const Color(0xFFBCAEE2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBioStep();
      default:
        return const Center(child: Text("More steps to come", style: TextStyle(color: Colors.white)));
    }
  }


  Widget _buildBioStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Tell us about yourself',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        LabeledTextField(
          label: 'Job Title',
          controller: jobTitleController,
          hintText: "Job Title",
          maxLines: 4,
        ),
        const SizedBox(height: 8),
        LabeledTextField(
          label: 'Bio Description',
          controller: bioController,
          hintText: "Bio Description",
          maxLines: 4,
        ),
        const SizedBox(height: 8),
        LabeledTextField(
          label: 'Where are you based?',
          controller: locationController,
          hintText: "Where are you based?"
        ),
        LabeledSelectField(
          label: "Base Currency",
          controller: currencyController,
          items: currencies,
          hintText: 'Select an Option',
          onChanged: (value) {
            selectedCurrency  = value;
          },
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0513),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFB0B0B6)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                // _buildProgressDots(),
                // const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildStepContent(),
                  ),
                ),
                const SizedBox(height: 10),
                RoundedButton(
                  title: _currentStep == 0 ? 'Submit' : 'Continue',
                    onPressed: _handleContinue,
                  color: AppColors.BUTTONCOLOR,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
