
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:soundhive2/model/category_model.dart';
import 'package:soundhive2/model/service_model.dart';
import 'package:soundhive2/screens/creator/services/services.dart';

import '../../../components/label_text.dart';
import '../../../components/rounded_button.dart';
import '../../../components/success.dart';
import '../../../components/widgets.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/categoryProvider.dart';
import 'package:soundhive2/lib/dashboard_provider/getCreatorServiceStatisticsProvider.dart';
import 'package:soundhive2/lib/dashboard_provider/serviceProvider.dart';
import 'package:soundhive2/lib/dashboard_provider/sub_category_provider.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import '../../../model/apiresponse_model.dart';
import '../../../model/sub_categories.dart';
import '../../../services/loader_service.dart';
import '../../../utils/alert_helper.dart';
import '../../../utils/app_colors.dart';
import '../profile/creative_form_screen.dart';
import 'add_new_service.dart';

class EditServiceScreen extends ConsumerStatefulWidget {
  final ServiceItem service;

  const EditServiceScreen({
    super.key,
    required this.service,
  });

  @override
  ConsumerState<EditServiceScreen> createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends ConsumerState<EditServiceScreen> {
  // ── Notifiers ──────────────────────────────────────────────────────
  final ValueNotifier<List<Category>> _servicesNotifier = ValueNotifier([]);
  final ValueNotifier<List<dynamic>> _subCategoriesNotifier = ValueNotifier([]);
  final ValueNotifier<bool> _categoryLoadingMoreNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _categoryHasMoreNotifier = ValueNotifier(true);
  final ValueNotifier<bool> _subcategoryLoadingMoreNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _subcategoryHasMoreNotifier = ValueNotifier(false);

  String? selectedCategoryId;
  String? selectedSubCategoryId;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController deliveryDaysController = TextEditingController();
  final TextEditingController revisionsController = TextEditingController();
  final PortfolioData portfolioData = PortfolioData();
  final TextEditingController serviceNameController = TextEditingController();
  final TextEditingController serviceDescriptionController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController subcategoryController = TextEditingController();

  final TextEditingController _categorySearchController = TextEditingController();
  final TextEditingController _subcategorySearchController = TextEditingController();

  bool _isSubmitting = false;
  final Logger _logger = Logger();
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _prefillFormData();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initCategoryAndSubselection();
    });
  }

  void _prefillFormData() {
    final service = widget.service;
    serviceNameController.text = service.serviceName;
    serviceDescriptionController.text = service.serviceDescription ?? '';
    rateController.text = service.rate;
    deliveryDaysController.text = service.deliveryDays?.toString() ?? '0';
    revisionsController.text = service.revisions?.toString() ?? '0';

    portfolioData.coverUrl = service.coverImage;
    portfolioData.imageUrl = service.serviceImage;
    portfolioData.audioUrl = service.serviceAudio ?? '';
    portfolioData.linkController.text = service.link ?? '';

    final selectedFormats = <String>[];
    if (service.serviceImage.isNotEmpty) selectedFormats.add('image');
    if (service.serviceAudio != null && service.serviceAudio!.isNotEmpty) selectedFormats.add('audio');
    if (service.link != null && service.link!.isNotEmpty) selectedFormats.add('link');
    portfolioData.selectedFormats.value = selectedFormats;

    selectedCategoryId = service.categoryId.toString().trim();
    selectedSubCategoryId = service.subCategoryId.toString().trim();
  }

  Future<void> _initCategoryAndSubselection() async {
    final targetCatId = widget.service.categoryId.toString().trim();
    final targetSubCatId = widget.service.subCategoryId.toString().trim();

    if (targetCatId.isEmpty) return;

    try {
      // 1. Reset & Fetch initial Categories
      ref.read(categoryProvider.notifier).resetSearch();
      await ref.read(categoryProvider.notifier).getCategory();
      _syncCategories();

      // 2. Page loop until Category is present in state
      int maxPages = 10;
      while (mounted && maxPages > 0) {
        final categoryExists = _servicesNotifier.value.any(
              (c) => c.id.toString() == targetCatId,
        );
        if (categoryExists) break;

        final hasMore = ref.read(categoryProvider).value?.data.nextPageUrl != null;
        if (!hasMore) break;

        await ref.read(categoryProvider.notifier).loadMore();
        _syncCategories();
        maxPages--;
      }

      // 3. Find Category
      final matchedCatList = _servicesNotifier.value.where(
            (c) => c.id.toString() == targetCatId,
      );

      if (matchedCatList.isNotEmpty && mounted) {
        final matchedCategory = matchedCatList.first;
        setState(() {
          categoryController.text = matchedCategory.name; // Uses category_name from JSON
          selectedCategoryId = matchedCategory.id.toString();
        });

        // 4. Fetch Subcategories for this Category ID explicitly
        final intCatId = int.tryParse(targetCatId) ?? matchedCategory.id;
        await ref.read(subcategoryProvider.notifier).getSubCategory(intCatId);
        _syncSubCategories();

        // 5. Match Subcategory
        final subcategoryData = _subCategoriesNotifier.value;
        final matchedSubList = subcategoryData.where(
              (s) => s.id.toString() == targetSubCatId,
        );

        if (matchedSubList.isNotEmpty && mounted) {
          final matchedSubcategory = matchedSubList.first;
          setState(() {
            subcategoryController.text = matchedSubcategory.name;
            selectedSubCategoryId = matchedSubcategory.id.toString();
          });
        }
      }
    } catch (e, stack) {
      _logger.e("Error preselecting categories", error: e, stackTrace: stack);
    }
  }

  void _syncCategories() {
    final categoryState = ref.read(categoryProvider).value;
    if (categoryState != null) {
      _servicesNotifier.value = List<Category>.from(categoryState.data.data);
      _categoryHasMoreNotifier.value = categoryState.data.nextPageUrl != null;
    }
  }

  void _syncSubCategories() {
    final subcategoryState = ref.read(subcategoryProvider).value;
    if (subcategoryState != null) {
      _subCategoriesNotifier.value = List<dynamic>.from(subcategoryState.data);
      _subcategoryHasMoreNotifier.value = subcategoryState.nextPageUrl != null;
    }
  }

  // ── Category load-more & search ────────────────────────────────────
  Future<void> _loadMoreCategories() async {
    if (_categoryLoadingMoreNotifier.value) return;
    _categoryLoadingMoreNotifier.value = true;
    await ref.read(categoryProvider.notifier).loadMore();
    _syncCategories();
    _categoryLoadingMoreNotifier.value = false;
  }

  Future<void> _onCategorySearch(String query) async {
    await ref.read(categoryProvider.notifier).getCategory(searchQuery: query);
    _syncCategories();
  }

  // ── Subcategory load-more & search ─────────────────────────────────
  Future<void> _loadMoreSubCategories() async {
    if (_subcategoryLoadingMoreNotifier.value) return;
    _subcategoryLoadingMoreNotifier.value = true;
    await ref.read(subcategoryProvider.notifier).loadMore();
    _syncSubCategories();
    _subcategoryLoadingMoreNotifier.value = false;
  }

  Future<void> _onSubcategorySearch(String query) async {
    if (selectedCategoryId == null) return;
    await ref.read(subcategoryProvider.notifier).searchSubCategories(query);
    _syncSubCategories();
  }

  // ── Pickers ────────────────────────────────────────────────────────
  void _openHivesPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaginatedPickerSheet(
        title: 'Select Hive',
        itemsNotifier: _servicesNotifier,
        toPickerItem: (c) => PickerItem(id: (c as Category).id.toString(), label: c.name),
        searchController: _categorySearchController,
        onSearch: _onCategorySearch,
        onLoadMore: _loadMoreCategories,
        isLoadingMoreNotifier: _categoryLoadingMoreNotifier,
        hasMoreNotifier: _categoryHasMoreNotifier,
        onSelected: (id, name) async {
          setState(() {
            categoryController.text = name;
            selectedCategoryId = id;
            subcategoryController.clear();
            selectedSubCategoryId = null;
            _subCategoriesNotifier.value = [];
            _subcategoryHasMoreNotifier.value = false;
          });
          await ref.read(subcategoryProvider.notifier).getSubCategory(int.parse(id));
          _syncSubCategories();
        },
      ),
    );
  }

  void _openClusterPicker() {
    if (selectedCategoryId == null) {
      _showError('Please select a Hive first');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaginatedPickerSheet(
        title: 'Select Cluster',
        itemsNotifier: _subCategoriesNotifier,
        toPickerItem: (s) => PickerItem(id: s.id.toString(), label: s.name),
        searchController: _subcategorySearchController,
        onSearch: _onSubcategorySearch,
        onLoadMore: _loadMoreSubCategories,
        isLoadingMoreNotifier: _subcategoryLoadingMoreNotifier,
        hasMoreNotifier: _subcategoryHasMoreNotifier,
        onSelected: (id, name) {
          setState(() {
            subcategoryController.text = name;
            selectedSubCategoryId = id;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _servicesNotifier.dispose();
    _subCategoriesNotifier.dispose();
    _categoryLoadingMoreNotifier.dispose();
    _categoryHasMoreNotifier.dispose();
    _subcategoryLoadingMoreNotifier.dispose();
    _subcategoryHasMoreNotifier.dispose();
    _categorySearchController.dispose();
    _subcategorySearchController.dispose();
    rateController.dispose();
    deliveryDaysController.dispose();
    revisionsController.dispose();
    portfolioData.dispose();
    serviceNameController.dispose();
    serviceDescriptionController.dispose();
    categoryController.dispose();
    subcategoryController.dispose();
    super.dispose();
  }

  // ── Step Layouts ───────────────────────────────────────────────────
  Widget _buildBioStep() {
    final categoryState = ref.watch(categoryProvider);
    final subcategoryState = ref.watch(subcategoryProvider);

    final bool isCategoryLoading = categoryState.isLoading && categoryController.text.isEmpty;
    final bool isSubcategoryLoading = subcategoryState.isLoading && subcategoryController.text.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Services',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: Colors.white),
        ),
        const SizedBox(height: 20),
        LabeledTextField(
          label: 'Service Name',
          controller: serviceNameController,
          hintText: "Service Name",
        ),
        LabeledTextField(
          label: 'Service Description',
          controller: serviceDescriptionController,
          hintText: "Service Description",
          maxLines: 4,
        ),

        // Hives Picker
        PickerTriggerField(
          label: 'Hives',
          controller: categoryController,
          hintText: isCategoryLoading ? 'Loading...' : 'Select Hives',
          isLoading: isCategoryLoading,
          onTap: categoryState.isLoading ? null : _openHivesPicker,
        ),

        // Service Clusters Picker
        PickerTriggerField(
          label: 'Service Clusters',
          controller: subcategoryController,
          hintText: selectedCategoryId == null
              ? 'Select a Hive first'
              : (isSubcategoryLoading ? 'Loading...' : 'Select Cluster'),
          isLoading: isSubcategoryLoading,
          onTap: (selectedCategoryId == null || subcategoryState.isLoading)
              ? null
              : _openClusterPicker,
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
          'Service Pricing & Terms',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white),
        ),
        const SizedBox(height: 20),
        CurrencyInputField(
          label: serviceNameController.text,
          suffixText: 'per project',
          controller: rateController,
          onChanged: (value) {},
          validator: (value) {
            if (value == null || value.isEmpty || double.tryParse(value) == null) {
              return 'Please enter a valid amount';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        LabeledTextField(
          label: 'Delivery Days',
          controller: deliveryDaysController,
          hintText: "e.g., 3",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        LabeledTextField(
          label: 'Revisions Allowed',
          controller: revisionsController,
          hintText: "e.g., 2 (0 for none)",
          keyboardType: TextInputType.number,
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white),
        ),
        const SizedBox(height: 10),
        const Text(
          'N.B: A good portfolio of work usually attracts good clients.',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: Color(0xFFF2F2F2)),
        ),
        const SizedBox(height: 20),
        PortfolioUploadSection(
          title: serviceNameController.text,
          coverImageNotifier: portfolioData.coverNotifier,
          imageFileNotifier: portfolioData.imageNotifier,
          audioFileNotifier: portfolioData.audioNotifier,
          linkController: portfolioData.linkController,
          selectedFormatsNotifier: portfolioData.selectedFormats,
          existingCoverUrl: portfolioData.coverUrl,
          existingImageUrl: portfolioData.imageUrl,
          existingAudioUrl: portfolioData.audioUrl,
        ),
      ],
    );
  }

  // ── Navigation & Validation ────────────────────────────────────────
  void _nextStep() {
    if (_currentStep < 2) {
      final isValid = _validateCurrentStep();
      if (!isValid) return;
      setState(() => _currentStep++);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (selectedCategoryId == null || categoryController.text.isEmpty) {
          _showError("Please select a Hive (Category)");
          return false;
        }
        if (selectedSubCategoryId == null || subcategoryController.text.isEmpty) {
          _showError("Please select a Cluster (Subcategory)");
          return false;
        }
        if (serviceNameController.text.trim().isEmpty) {
          _showError("Service name is required");
          return false;
        }
        return true;
      case 1:
        if (rateController.text.trim().isEmpty) {
          _showError("Rate is required");
          return false;
        }
        if (deliveryDaysController.text.trim().isEmpty) {
          _showError("Delivery days are required");
          return false;
        }
        if (revisionsController.text.trim().isEmpty) {
          _showError("Revisions are required");
          return false;
        }
        return true;
      case 2:
        if (portfolioData.coverNotifier.value == null && portfolioData.coverUrl == null) {
          _showError("Cover image is required");
          return false;
        }
        if (portfolioData.selectedFormats.value.isEmpty) {
          _showError("Please select at least one portfolio format");
          return false;
        }
        for (final format in portfolioData.selectedFormats.value) {
          if (format == 'image' && portfolioData.imageNotifier.value == null && portfolioData.imageUrl == null) {
            _showError("Image file is required");
            return false;
          }
          if (format == 'audio' && portfolioData.audioNotifier.value == null && portfolioData.audioUrl == null) {
            _showError("Audio file is required");
            return false;
          }
          if (format == 'link' && portfolioData.linkController.text.trim().isEmpty) {
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
    showCustomAlert(context: context, isSuccess: false, title: "Error", message: message);
  }

  void _handleContinue() {
    if (_currentStep == 2) {
      _submitForm();
    } else {
      _nextStep();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  // ── Submissions & API ──────────────────────────────────────────────
  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    try {
      LoaderService.showLoader(context);
      await _uploadServiceMedia(portfolioData);
      await _submitToBackend();
      if (!mounted) return;
      LoaderService.hideLoader(context);
      final user = await ref.read(userProvider.notifier).loadUserProfile();
      await ref.read(getCreatorServiceStatistics.notifier).getStats();
      ref.invalidate(serviceProvider('published'));
      ref.invalidate(serviceProvider('pending'));
      ref.invalidate(serviceProvider('rejected'));
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Success(
            title: 'Your service has been updated successfully',
            subtitle: 'The changes have been saved.',
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
      if (mounted) {
        showCustomAlert(context: context, isSuccess: false, title: 'Error', message: errorMessage);
      }
    } finally {
      if (mounted) {
        LoaderService.hideLoader(context);
        _isSubmitting = false;
      }
    }
  }

  Future<void> _uploadServiceMedia(PortfolioData data) async {
    if (data.coverNotifier.value != null) {
      data.coverUrl = await _uploadFileToCloudinary(
        file: data.coverNotifier.value!,
        resourceType: 'image',
        preset: 'soundhive',
      );
    }
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
      'https://api.cloudinary.com/v1_1/dfwvgagmk/$resourceType/upload',
      data: formData,
    );
    if (response.statusCode != 200) {
      throw Exception('$resourceType upload failed: ${response.statusMessage}');
    }
    return response.data['secure_url'] as String;
  }

  Future<ApiResponseModel> _submitToBackend() async {
    final portfolioFormats = portfolioData.selectedFormats.value;
    String? portfolioImage, portfolioAudio, portfolioLink;
    for (final format in portfolioFormats) {
      if (format == 'image') portfolioImage = portfolioData.imageUrl ?? widget.service.serviceImage;
      else if (format == 'audio') portfolioAudio = portfolioData.audioUrl ?? widget.service.serviceAudio;
      else if (format == 'link') portfolioLink = portfolioData.linkController.text;
    }
    final payload = {
      "category_id": int.parse(selectedCategoryId!),
      "sub_category_id": int.parse(selectedSubCategoryId!),
      "service_name": serviceNameController.text,
      "service_description": serviceDescriptionController.text,
      "rate": rateController.text.replaceAll(",", ""),
      "delivery_days": int.parse(deliveryDaysController.text.trim()),
      "revisions": int.parse(revisionsController.text.trim()),
      "cover_image": portfolioData.coverUrl ?? widget.service.coverImage,
      "service_image": portfolioImage ?? '',
      "service_audio": portfolioAudio ?? '',
      "link": portfolioLink ?? '',
    };
    try {
      final response = await ref.read(apiresponseProvider.notifier).updateService(
        serviceId: widget.service.id,
        payload: payload,
        context: context,
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
      case 0: return _buildBioStep();
      case 1: return _rateStep();
      case 2: return _portfolioStep();
      default: return const Center(child: Text("Invalid Step", style: TextStyle(color: Colors.white)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    onPressed: _currentStep == 0 ? () => Navigator.pop(context) : _previousStep,
                  ),
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Edit service',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                _buildProgressDots(),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(child: _buildStepContent()),
                ),
                const SizedBox(height: 10),
                RoundedButton(
                  title: _currentStep == 2 ? 'Update Service' : 'Continue',
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
