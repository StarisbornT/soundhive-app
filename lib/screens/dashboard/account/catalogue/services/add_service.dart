import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import '../../../../../components/image_picker.dart';
import '../../../../../components/success.dart';
import '../../../../../components/widgets.dart';
import '../../../../../services/loader_service.dart';
import '../../../../../utils/alert_helper.dart';
import '../catalogue.dart';


class AddService extends ConsumerStatefulWidget {
  @override
  ConsumerState<AddService> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends ConsumerState<AddService> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _assetTypes = ['Sound effect', 'Music', 'Image'];
  final List<String> _workType = ['Remote', 'Onsite'];
  final List<String> _states = [
    "Abia State",
    "Adamawa State",
    "Akwa Ibom State",
    "Anambra State",
    "Bauchi State",
    "Bayelsa State",
    "Benue State",
    "Borno State",
    "Cross River State",
    "Delta State",
    "Ebonyi State",
    "Edo State",
    "Ekiti State",
    "Enugu State",
    "Gombe State",
    "Imo State",
    "Jigawa State",
    "Kaduna State",
    "Kano State",
    "Katsina State",
    "Kebbi State",
    "Kogi State",
    "Kwara State",
    "Lagos State",
    "Nasarawa State",
    "Niger State",
    "Ogun State",
    "Ondo State",
    "Osun State",
    "Oyo State",
    "Plateau State",
    "Rivers State",
    "Sokoto State",
    "Taraba State",
    "Yobe State",
    "Zamfara State"
  ];
  String? _selectedAssetType;
  String? _selectedWorkType;
  String? _selectedFilePath;
  List<String> _selectedStates = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _portfolioController = TextEditingController();
  final ValueNotifier<File?> _imageNotifier = ValueNotifier<File?>(null);
  String? _uploadedImageUrl;
  String? _uploadedAudioUrl;
  Future<bool> _isValidLocalPath(String path) async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = tempDir.path;
    // Check if the path is in the app's temporary directory or a valid URI
    return path.startsWith(tempPath) ||
        path.startsWith('/data') ||
        path.startsWith('file://') ||
        path.startsWith('content://');
  }

  String _parseCloudinaryError(dynamic responseData) {
    try {
      return responseData?['error']?['message'] ?? 'Cloudinary upload failed';
    } catch (e) {
      return 'Failed to process media upload';
    }
  }

  String _parseBackendError(dynamic responseData) {
    try {
      return responseData?['message'] ??
          responseData?['error'] ??
          'Operation failed (${responseData?['statusCode']})';
    } catch (e) {
      return 'Failed to parse server response';
    }
  }

  Future<void> _uploadMediaToCloudinary() async {
    // Upload image
    final imageFile = _imageNotifier.value!;
    _uploadedImageUrl = await _uploadFileToCloudinary(
        file: imageFile,
        resourceType: 'image',
        preset: 'soundhive'
    );
  }

  Future<String> _uploadFileToCloudinary({
    required File file,
    required String resourceType,
    required String preset
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


  void _submitForm() async {
    print('🔄 Starting submission');
    print('📁 Image path: ${_imageNotifier.value?.path}');

    try {
      LoaderService.showLoader(context);
      if (!_formKey.currentState!.validate()) {
        print("Form validation failed");
        return;
      }
      // _validatePaths();
      final imageFile = _imageNotifier.value;
      bool imagePath = await _isValidLocalPath(imageFile!.path);

      // Validate image file
      if (!await imageFile.exists() || !imagePath) { // Changed imagePath to !imagePath
        throw Exception('Invalid or missing image file');
      }
      await _uploadMediaToCloudinary();

      _submitToBackend();

    } catch (error) {
      String errorMessage = 'An unexpected error occurred';
      final logger = Logger(); // Add logger package for better debugging

      // Always log the full error
      logger.e("Submission Error", error: error);
      print('FULL ERROR DETAILS: $error');


      if (error is DioException) {
        print('DIO ERROR RESPONSE: ${error.response?.data}');
        // Handle different Dio error types
        switch (error.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            errorMessage = 'Connection timeout - please check your internet';
            break;
          case DioExceptionType.badCertificate:
            errorMessage = 'Security error occurred';
            break;
          case DioExceptionType.badResponse:
          // Parse Cloudinary errors differently from your backend errors
            if (error.response?.requestOptions.path.contains('cloudinary') ?? false) {
              errorMessage = _parseCloudinaryError(error.response?.data);
            } else {
              errorMessage = _parseBackendError(error.response?.data);
            }
            break;
          case DioExceptionType.cancel:
            errorMessage = 'Request was cancelled';
            break;
          default:
            errorMessage = error.message ?? 'Network error occurred';
        }
      } else if (error is FormatException) {
        errorMessage = 'Invalid data format - please check your inputs';
      } else if (error is Exception) {
        errorMessage = error.toString();
      }

      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: errorMessage,
      );
    }finally {
      LoaderService.hideLoader(context);
    }
  }

  Future<void> _submitToBackend() async {
    final amount = double.parse(
      _priceController.text.replaceAll(RegExp(r'[₦,]'), ''),
    );
    try {
      final response = await ref.read(apiresponseProvider.notifier).addService(
        context: context,
          serviceType: _nameController.text,
          category: _selectedAssetType!,
          workType: _selectedWorkType!,
          availableToWork: _selectedStates,
          price: amount,
          serviceDescription: _descController.text,
          imageUrl: _uploadedImageUrl!,
        portfolio: _portfolioController.text
      );
      if (response.message == "success") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const Success(
              title: 'Service Added',
              subtitle: 'Your Service has been successfully added!',
            ),
          ),
        );
        Navigator.push(context, MaterialPageRoute(builder: (_) =>  CatalogueScreen()));
      }
    }
    catch (e) {
      if (e.toString().contains('must be an array')) {
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: 'Please select at least one state',
        );
      }
    }


  }

  @override
  void dispose() {
    _imageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C051F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),

      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Service to Catalogue',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 20,),
              Text(
                'Kindly complete the information below to add service to your catalogue.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 40,),
              AssetTypeDropdown(
                selectedValue: _selectedAssetType,
                items: _assetTypes,
                onChanged: (value) => setState(() => _selectedAssetType = value),
                label: 'Select Category',
                validator: (value) => value == null ? 'Please select an asset type' : null,
              ),
              const SizedBox(height: 20),
              _buildTextField('What type of service do you provide?', 'E.g Water splash effect',
                  controller: _nameController),
              const SizedBox(height: 20),
              _buildTextField('How much would you charge for this service (₦)', 'Enter amount in Naira',
                  controller: _priceController, isNumber: true),
              const SizedBox(height: 20),
              AssetTypeDropdown(
                selectedValue: _selectedWorkType,
                items: _workType,
                onChanged: (value) => setState(() => _selectedWorkType = value),
                label: 'Work Type',
                validator: (value) => value == null ? 'Please select an work type' : null,
              ),
              const SizedBox(height: 20),
              MultiSelectAssetDropdown(
                items: _states,
                selectedItems: _selectedStates,
                onChanged: (selected) {
                  setState(() {
                    _selectedStates = selected;
                    print("Selected states: $selected");
                  });
                },

              ),
              const SizedBox(height: 20),
              DescriptionField(
                controller: _descController,
                label: 'Tell us more about yourself',
                hintText: 'Describe yourself',
              ),

              const SizedBox(height: 20),
              DescriptionField(
                controller: _portfolioController,
                label: 'Can we see your portfolio',
                hintText: '',
              ),
              const SizedBox(height: 20),
              ImagePickerComponent(
                labelText: 'Image Upload',
                imageNotifier: _imageNotifier,
                validator: (value) {
                  if (value == null) {
                    return ' image is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              Column(
                children: [
                  if (_uploadedImageUrl != null)
                    _buildUploadStatus('Image uploaded', Colors.green),
                  // Rest of your form
                ],
              ),
              RoundedButton(
                title: 'Submit for Review',
                color: Color(0xFF4D3490),
                borderRadius: 24,
                onPressed: () {
                  print('Clicking');
                  _submitForm();
                },
              )
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildTextField(String label, String hint,
      {required TextEditingController controller, bool isNumber = false}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          TextFormField(
            controller: controller,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            inputFormatters: isNumber ? [CurrencyInputFormatter()] : [],
            validator: (value) {
              if (value == null || value.isEmpty) return 'This field is required';
              if (isNumber && !RegExp(r'^₦?\d+(,\d{3})*(\.\d+)?$').hasMatch(value)) {
                return 'Invalid price format';
              }
              return null;
            },
          ),
        ],
      );
  Widget _buildUploadStatus(String text, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: color, size: 16),
          SizedBox(width: 8),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }

}



class MultiSelectAssetDropdown extends StatelessWidget {
  final List<String> items;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onChanged;

  const MultiSelectAssetDropdown({
    super.key,
    required this.items,
    required this.selectedItems,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Select States',
        labelStyle: TextStyle(color: Colors.white), // Add if needed
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.white), // Add if needed
        ),
        filled: true,
        fillColor: Colors.transparent,
      ),
      child: InkWell(
        onTap: () => _showSelectionDialog(context),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: 40), // Ensure minimum tap target
          child: Wrap(
            spacing: 4.0,
            runSpacing: 4.0,
            children: selectedItems.isEmpty
                ? [ // Show placeholder when empty
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Tap to select states',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            ]
                : selectedItems
                .map((item) => Chip(
              label: Text(item,
                  style: TextStyle(color: Colors.white)), // Update text color
              backgroundColor: Colors.blueGrey, // Customize chip color
              onDeleted: () => onChanged(
                selectedItems.where((i) => i != item).toList(),
              ),
            ))
                .toList(),
          ),
        ),
      ),
    );
  }

  void _showSelectionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color(0xFF0C051F), // Match your theme
      builder: (context) => _MultiSelectBottomSheet(
        items: items,
        selectedItems: selectedItems.toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _MultiSelectBottomSheet extends StatefulWidget {
  final List<String> items;
  final List<String> selectedItems;
  final ValueChanged<List<String>> onChanged;

  const _MultiSelectBottomSheet({
    required this.items,
    required this.selectedItems,
    required this.onChanged,
  });

  @override
  _MultiSelectBottomSheetState createState() => _MultiSelectBottomSheetState();
}

class _MultiSelectBottomSheetState extends State<_MultiSelectBottomSheet> {
  late List<String> _tempSelected;
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.selectedItems);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredItems {
    return widget.items.where((item) {
      final query = _searchQuery.toLowerCase();
      return item.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF0C051F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _searchController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Search states',
              labelStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.search, color: Colors.white70),
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => setState(() => _tempSelected = []),
                child: Text('Clear All', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () => setState(() => _tempSelected = List.from(widget.items)),
                child: Text('Select All', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return CheckboxListTile(
                  value: _tempSelected.contains(item),
                  title: Text(item, style: TextStyle(color: Colors.white)),
                  activeColor: Colors.purple,
                  checkColor: Colors.white,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _tempSelected.add(item);
                      } else {
                        _tempSelected.remove(item);
                      }
                    });
                  },
                );
              },
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    widget.onChanged(_tempSelected);
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Apply Selection',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DescriptionField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final String? Function(String?)? validator;

  const DescriptionField({
    Key? key,
    required this.controller,
    this.label = 'Tell us more about this asset',
    this.hintText = 'Describe this asset',
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.white54),
            border: const OutlineInputBorder(),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white70),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            filled: true,
            fillColor: const Color(0xFF0C051F),
            alignLabelWithHint: true,
          ),
          validator: validator ??
                  (value) =>
              value == null || value.isEmpty ? 'Description is required' : null,
        ),
      ],
    );
  }
}


class AssetTypeDropdown extends StatelessWidget {
  final String? selectedValue;
  final List<String> items;
  final Function(String?) onChanged;
  final String label;
  final String? Function(String?)? validator;

  const AssetTypeDropdown({
    Key? key,
    required this.selectedValue,
    required this.items,
    required this.onChanged,
    required this.label,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0C051F),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white70),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          dropdownColor: const Color(0xFF0C051F),
          style: const TextStyle(color: Colors.white),
          hint: const Text('Select asset type', style: TextStyle(color: Colors.white54)),
          value: selectedValue,
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(color: Colors.white70)),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}
