
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:soundhive2/model/category_model.dart';
import 'package:soundhive2/screens/creator/services/services.dart';

import '../../../components/label_text.dart';
import '../../../components/rounded_button.dart';
import '../../../components/success.dart';
import '../../../components/widgets.dart';
import '../../../lib/dashboard_provider/apiresponseprovider.dart';
import '../../../lib/dashboard_provider/categoryProvider.dart';
import '../../../lib/dashboard_provider/user_provider.dart';
import '../../../model/apiresponse_model.dart';
import '../../../services/loader_service.dart';
import '../../../utils/alert_helper.dart';
import '../../../utils/app_colors.dart';
import '../profile/creative_form_screen.dart';

class AddNewServiceScreen extends ConsumerStatefulWidget {
  const AddNewServiceScreen({super.key});

  @override
  _AddNewServiceScreenState createState() => _AddNewServiceScreenState();
}

class _AddNewServiceScreenState extends ConsumerState<AddNewServiceScreen> {
  List<Category> services = [];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<Category> selectedServices = [];
  final Map<Category, TextEditingController> rateControllers = {};
  final Map<Category, PortfolioData> portfolioData = {};
  final TextEditingController serviceNameController = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(categoryProvider.notifier).getCategory();
      final fetched = ref.read(categoryProvider).value?.data;
      setState(() {
        services = fetched!;
        for (var service in selectedServices) {
          portfolioData[service] = PortfolioData();
          rateControllers[service] = TextEditingController();
        }
      });
    });
  }

  int _currentStep = 0;
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

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Bio Step
        if (selectedServices.isEmpty) {
          _showError("Please select at least one service");
          return false;
        }
        return true;

      case 1: // Rate Step - UPDATED
        for (var service in selectedServices) {
          if (rateControllers[service]!.text.isEmpty) {
            _showError("Rate for $service is required");
            return false;
          }
        }
        return true;

      case 2: // Portfolio Step - UPDATED
        for (var service in selectedServices) {
          final data = portfolioData[service]!;

          // Validate cover image
          if (data.coverNotifier.value == null) {
            _showError("Cover image is required for $service");
            return false;
          }

          // Validate selected formats
          if (data.selectedFormats.value.isEmpty) {
            _showError("Please select at least one portfolio format for $service");
            return false;
          }

          // Validate each selected format
          for (final format in data.selectedFormats.value) {
            if (format == 'image' && data.imageNotifier.value == null) {
              _showError("Image file is required for $service");
              return false;
            }
            if (format == 'audio' && data.audioNotifier.value == null) {
              _showError("Audio file is required for $service");
              return false;
            }
            if (format == 'link' && data.linkController.text.isEmpty) {
              _showError("Link is required for $service");
              return false;
            }
          }
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

  @override
  void dispose() {
    for (var controller in rateControllers.values) {
      controller.dispose();
    }
    for (var data in portfolioData.values) {
      data.dispose();
    }

    super.dispose();
  }

  void _handleContinue() {
    if (_currentStep == 2) {
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
  bool _isSubmitting = false;
  final Logger _logger = Logger();

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
      final user = await ref.read(userProvider.notifier).loadUserProfile();
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Success(
            title: 'Your new service(s) has been submitted for review',
            subtitle: 'We will review it and get back to you shortly.',
            onButtonPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) =>  ServiceScreen(user: user!,)),
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
      LoaderService.hideLoader(context);
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
    final List<Map<String, dynamic>> servicesPayload = [];

    for (var service in selectedServices) {
      final data = portfolioData[service]!;
      final amount = rateControllers[service]?.text ?? "";

      // If the backend expects one portfolio item only (based on the example)
      final primaryPortfolio = data.selectedFormats.value.isNotEmpty
          ? data.selectedFormats.value.first
          : "";

      servicesPayload.add({
        "service_name": service.name,
        "service_amount": amount,
        "service_image": data.coverUrl,
        "service_portfolio_format": primaryPortfolio,
        "service_portfolio_image": _getPortfolioUrl(data, primaryPortfolio),
      });
    }
    // Prepare payload
    final payload = {
      "services": servicesPayload,
    };

    try {
      final response = await ref.read(apiresponseProvider.notifier).createService(
        payload: payload,
      );

      if (response.message != "sucess") {
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
  String _getPortfolioUrl(dynamic data, String format) {
    switch (format) {
      case 'image':
        return data.imageUrl;
      case 'audio':
        return data.audioUrl;
      case 'link':
        return data.linkController.text;
      default:
        return '';
    }
  }
  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
            (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 98,
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
      case 1:
        return _buildServicesStep();
      case 2:
        return _rateStep();
      case 3:
        return _portfolioStep();
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
          'Service Name',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        LabeledTextField(
          label: 'Service Name',
          controller: serviceNameController,
          hintText: "Service Name",
        ),
      ],
    );
  }
  Widget _portfolioStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'What are some of the amazing projects you have done so far?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'N.B: A good portfolio of work usually attract good clients.',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: Color(0xFFF2F2F2),
          ),
        ),
        const SizedBox(height: 20),

        ...selectedServices.map((service) {
          final data = portfolioData[service]!;
          return Column(
            children: [
              PortfolioUploadSection(
                title: service.name, // Assuming Category has a 'name' property
                coverImageNotifier: data.coverNotifier,
                imageFileNotifier: data.imageNotifier,
                audioFileNotifier: data.audioNotifier,
                linkController: data.linkController,
                selectedFormatsNotifier: data.selectedFormats,
              ),
              const SizedBox(height: 20),
            ],
          );
        }).toList(),
      ],
    );
  }
  Widget _rateStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'What are your rates?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),

        ...selectedServices.map((service) {
          return Column(
            children: [
              const SizedBox(height: 16),
              CurrencyInputField(
                label: service.name, // Assuming Category has a 'name' property
                suffixText: 'per project',
                controller: rateControllers[service]!,
                onChanged: (value) {
                  print('Input changed to: $value');
                },
                validator: (value) {
                  if (value == null || value.isEmpty || double.tryParse(value) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
  Widget _buildServicesStep() {
    final TextEditingController searchController = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Select the service(s) you want to add',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        LabeledTextField(
          label: 'Search',
          controller: searchController,
          prefixIcon: Icons.search,
          hintText: "Search for service",
        ),
        const SizedBox(height: 20),
        Wrap(
          children: services.map((service) {
            return CheckboxListTile(
              value: selectedServices.contains(service),
              activeColor: const Color(0xFF8F4EFF),
              controlAffinity: ListTileControlAffinity.leading,
              checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              title: Text(service.name, style: const TextStyle(color: Colors.white)), // Assuming Category has a 'name' property
              onChanged: (_) {
                setState(() {
                  if (selectedServices.contains(service)) {
                    selectedServices.remove(service);
                  } else {
                    selectedServices.add(service);
                    // Initialize controllers and portfolio data when adding a service
                    if (!rateControllers.containsKey(service)) {
                      rateControllers[service] = TextEditingController();
                    }
                    if (!portfolioData.containsKey(service)) {
                      portfolioData[service] = PortfolioData();
                    }
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.BACKGROUNDCOLOR,
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
                    onPressed: _previousStep,
                  ),
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                      'Add a new service',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white
                    ),
                  ),
                ),
                _buildProgressDots(),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildStepContent(),
                  ),
                ),
                const SizedBox(height: 10),
                RoundedButton(
                  title: _currentStep == 2 ? 'Submit' : 'Continue',
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
