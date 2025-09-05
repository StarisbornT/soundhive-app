
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
import '../../../lib/dashboard_provider/sub_category_provider.dart';
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
  Category? selectedService;
  String? selectedCategoryId;
  String? selectedSubCategoryId;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController rateController = TextEditingController(); // Single rate controller
  final PortfolioData portfolioData = PortfolioData(); // Single portfolio data
  final TextEditingController serviceNameController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController subcategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(categoryProvider.notifier).getCategory();
      final fetched = ref.read(categoryProvider).value?.data.data;
      setState(() {
        services = fetched!;
      });
    });
  }

  int _currentStep = 0;
  void _nextStep() {
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
        if (categoryController.text.isEmpty || serviceNameController.text.isEmpty) {
          _showError("Please select a service");
          return false;
        }
        return true;

      case 1: // Rate Step
        if (rateController.text.isEmpty) {
          _showError("Rate is required");
          return false;
        }
        return true;

      case 2: // Portfolio Step
      // Validate cover image
        if (portfolioData.coverNotifier.value == null) {
          _showError("Cover image is required");
          return false;
        }

        // Validate selected formats
        if (portfolioData.selectedFormats.value.isEmpty) {
          _showError("Please select at least one portfolio format");
          return false;
        }

        // Validate each selected format
        for (final format in portfolioData.selectedFormats.value) {
          if (format == 'image' && portfolioData.imageNotifier.value == null) {
            _showError("Image file is required");
            return false;
          }
          if (format == 'audio' && portfolioData.audioNotifier.value == null) {
            _showError("Audio file is required");
            return false;
          }
          if (format == 'link' && portfolioData.linkController.text.isEmpty) {
            _showError("Link is required");
            return false;
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
      message: message,
    );
  }

  @override
  void dispose() {
    rateController.dispose();
    portfolioData.dispose();
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

      // Upload media files
      await _uploadServiceMedia(portfolioData);

      // Submit to backend
      await _submitToBackend();

      if (!mounted) return;

      LoaderService.hideLoader(context);
      final user = await ref.read(userProvider.notifier).loadUserProfile();
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Success(
            title: 'Your new service has been submitted for review',
            subtitle: 'We will review it and get back to you shortly.',
            onButtonPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ServiceScreen(user: user!)),
              );
            },
          ),
        ),
      );
    } catch (error) {
      _logger.e("Submission Error", error: error);
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

      print("Error: $errorMessage");
      if(mounted) {
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: errorMessage,
        );
      }

      return;
    } finally {
      if(mounted) {
        LoaderService.hideLoader(context);
        _isSubmitting = false;
      }

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
      } else if (format == 'audio' && data.audioNotifier.value != null) {
        data.audioUrl = await _uploadFileToCloudinary(
          file: data.audioNotifier.value!,
          resourceType: 'video',
          preset: 'soundhive',
        );
      }
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
      throw Exception('$resourceType upload failed: ${response.statusMessage}');
    }

    return response.data['secure_url'] as String;
  }

  Future<ApiResponseModel> _submitToBackend() async {
    // Prepare portfolio data based on selected formats
    final portfolioFormats = portfolioData.selectedFormats.value;

    String? portfolioImage;
    String? portfolioAudio;
    String? portfolioLink;

    // Set values based on what formats were selected
    for (final format in portfolioFormats) {
      if (format == 'image') {
        portfolioImage = portfolioData.imageUrl;
      } else if (format == 'audio') {
        portfolioAudio = portfolioData.audioUrl;
      } else if (format == 'link') {
        portfolioLink = portfolioData.linkController.text;
      }
    }

    final payload = {
      "category_id": int.parse(selectedCategoryId!),
      "sub_category_id": int.parse(selectedSubCategoryId!),
      "service_name": serviceNameController.text,
      "rate": rateController.text,
      "cover_image": portfolioData.coverUrl,
      "service_image": portfolioImage ?? '',
      "service_audio": portfolioAudio ?? '',
      "link": portfolioLink ?? '',
    };

    try {
      final response = await ref.read(apiresponseProvider.notifier).createService(
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
      rethrow;
    }
  }

  final List<Map<String, String>> portfolioFormat = [
    {'label': 'Image', 'value': 'image'},
    {'label': 'Link', 'value': 'link'},
    {'label': 'Audio', 'value': 'audio'},
  ];

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
        return _rateStep();
      case 2:
        return _portfolioStep();
      default:
        return const Center(child: Text("More steps to come", style: TextStyle(color: Colors.white)));
    }
  }

  Widget _buildBioStep() {
    final categoryItems = services.map((category) {
      return {
        'value': category.id.toString(),
        'label': category.name,
      };
    }).toList();

    final subcategories = ref.watch(subcategoryProvider);

    final subCategoryItems = (subcategories.value?.data ?? []).map((sub) {
      return {
        'value': sub.id.toString(),
        'label': sub.name,
      };
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Services',
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
        LabeledSelectField(
          label: "Category",
          controller: categoryController,
          items: categoryItems,
          hintText: 'Select category',
          onChanged: (selectedValue) {
            selectedCategoryId = selectedValue;
            ref.read(subcategoryProvider.notifier).getSubCategory(int.parse(selectedValue));
          },
        ),
        LabeledSelectField(
          label: "Sub Category",
          controller: subcategoryController,
          items: subCategoryItems,
          hintText: 'Select sub category',
          onChanged: (value) {
            selectedSubCategoryId = value;
          },
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
        PortfolioUploadSection(
          title: serviceNameController.text,
          coverImageNotifier: portfolioData.coverNotifier,
          imageFileNotifier: portfolioData.imageNotifier,
          audioFileNotifier: portfolioData.audioNotifier,
          linkController: portfolioData.linkController,
          selectedFormatsNotifier: portfolioData.selectedFormats,
        ),
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
        CurrencyInputField(
          label: serviceNameController.text,
          suffixText: 'per project',
          controller: rateController,
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
                      color: Colors.white,
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
