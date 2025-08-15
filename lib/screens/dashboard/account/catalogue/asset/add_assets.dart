import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
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

class AddAssets extends ConsumerStatefulWidget {
  @override
  ConsumerState<AddAssets> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends ConsumerState<AddAssets> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _assetTypes = [
    'Background instrumentals (beats, loops)',
    'Sound effects (SFX packs)',
    'Royalty-free background music',
    'Album cover templates',
    'Event flyer templates',
    'Poster and social media design templates',
    'Illustrations (e.g. hand-drawn or digital)',
    'Logo packs for musicians or events',
    'Visual loops for stage or event backdrops',
    'Intro/outro video templates',
    'Motion graphics (e.g., animated lower-thirds, overlays)',
    'Music video elements (transitions, effects)',
    'Performance scripts (e.g., spoken word, stage skits)',
    'Songwriting prompts or templates',
    'Contract templates for creatives (licensing, collabs, etc.)'
  ];
  String? _selectedAssetType;
  String? _selectedFilePath;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final ValueNotifier<File?> _imageNotifier = ValueNotifier<File?>(null);
  String? _uploadedImageUrl;
  String? _uploadedAudioUrl;
  bool _isUploading = false;
  Future<bool> _isValidLocalPath(String path) async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = tempDir.path;
    // Check if the path is in the app's temporary directory or a valid URI
    return path.startsWith(tempPath) ||
        path.startsWith('/data') ||
        path.startsWith('file://') ||
        path.startsWith('content://');
  }

  // void _validatePaths() {
  //   if (_imageNotifier.value != null) {
  //     final imagePath = _imageNotifier.value!.path;
  //     if (!_isValidLocalPath(imagePath)) {
  //       throw Exception('Invalid image path format');
  //     }
  //   }
  //
  //   if (_selectedFilePath != null) {
  //     if (!_isValidLocalPath(_selectedFilePath!)) {
  //       throw Exception('Invalid audio path format');
  //     }
  //   }
  // }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowCompression: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final path = result.files.single.path;
      if (path != null && File(path).existsSync()) {
        setState(() => _selectedFilePath = path);
      } else {
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: 'Selected file does not exist',
        );
      }
    }
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
        file: imageFile, resourceType: 'image', preset: 'soundhive');

    // Upload audio
    final audioFile = File(_selectedFilePath!);
    _uploadedAudioUrl = await _uploadFileToCloudinary(
        file: audioFile, resourceType: 'video', preset: 'soundhive');
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

  void _submitForm() async {
    print('🔄 Starting submission');
    print('📁 Image path: ${_imageNotifier.value?.path}');
    print('🎵 Audio path: $_selectedFilePath');

    try {
      LoaderService.showLoader(context);
      if (!_formKey.currentState!.validate()) {
        print("Form validation failed");
        return;
      }

      final imageFile = _imageNotifier.value;
      final audioFile = _selectedFilePath;
      bool imagePath = await _isValidLocalPath(imageFile!.path);
      bool audioPath = await _isValidLocalPath(audioFile!);

      // Validate image file
      if (!await imageFile.exists() || !imagePath) {
        throw Exception('Invalid or missing image file');
      }
      if (!File(audioFile).existsSync() || !audioPath) {
        // Changed audioPath to !audioPath
        throw Exception('Invalid or missing audio file');
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
            if (error.response?.requestOptions.path.contains('cloudinary') ??
                false) {
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
    } finally {
      LoaderService.hideLoader(context);
    }
  }

  Future<void> _submitToBackend() async {
    final amount = double.parse(
      _priceController.text.replaceAll(RegExp(r'[₦,]'), ''),
    );

    final response = await ref.read(apiresponseProvider.notifier).addAssets(
      context: context,
          assetType: _selectedAssetType!,
          amount: amount,
          assetName: _nameController.text,
          assetDescription: _descController.text,
          image: _uploadedImageUrl!,
          assetUrl: _uploadedAudioUrl!,
        );
    if (response.message == "success") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const Success(
            title: 'Assets Added',
            subtitle: 'Your Assets has been successfully added!',
          ),
        ),
      );
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => CatalogueScreen()));
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
                'Add Asset to Catalogue',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Text(
                'Kindly complete the information below to add assets to your catalogue.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(
                height: 40,
              ),
              _buildAssetTypeSection(),
              const SizedBox(height: 20),
              _buildTextField('Asset name', 'E.g Water splash effect',
                  controller: _nameController),
              const SizedBox(height: 20),
              _buildTextField('Price (N)', 'Enter amount in Naira',
                  controller: _priceController, isNumber: true),
              const SizedBox(height: 20),
              _buildDescriptionField(),
              const SizedBox(height: 20),
              _buildFileUploadSection(),
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
                  if (_uploadedAudioUrl != null)
                    _buildUploadStatus('Audio uploaded', Colors.green),
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

  Widget _buildAssetTypeSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What type of asset are you adding?',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return DropdownButtonFormField<String>(
                isExpanded: true, // Important!
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF0C051F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                dropdownColor: const Color(0xFF0C051F),
                style: const TextStyle(color: Colors.white),
                hint: const Text('Select asset type',
                    style: TextStyle(color: Colors.white54)),
                value: _selectedAssetType,
                items: _assetTypes.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedAssetType = value),
                validator: (value) =>
                    value == null ? 'Please select an asset type' : null,
              );
            },
          )
        ],
      );

  Widget _buildTextField(String label, String hint,
          {required TextEditingController controller, bool isNumber = false}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white)),
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
              if (value == null || value.isEmpty)
                return 'This field is required';
              if (isNumber &&
                  !RegExp(r'^₦?\d+(,\d{3})*(\.\d+)?$').hasMatch(value)) {
                return 'Invalid price format';
              }
              return null;
            },
          ),
        ],
      );

  Widget _buildDescriptionField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tell us more about this asset',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          TextFormField(
            controller: _descController,
            maxLines: 5,
            style: TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Describe this asset',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            validator: (value) =>
                value!.isEmpty ? 'Description is required' : null,
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

  Widget _buildFileUploadSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upload audio',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.upload),
            label: const Text('Choose File',
                style: TextStyle(color: Colors.white70)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
          if (_selectedFilePath != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selected file: ${_selectedFilePath!.split('/').last}',
                      style: const TextStyle(color: Colors.grey)),
                  if (!File(_selectedFilePath!).existsSync())
                    const Text('Warning: File appears to be missing!',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ),
            ),
          const Text('Supported file types: mp3, Max file size: 2MB',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      );
}
