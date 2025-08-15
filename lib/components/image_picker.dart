import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ImagePickerComponent extends StatefulWidget {
  final String labelText;
  final String? Function(File?)? validator;
  final ValueNotifier<File?> imageNotifier;
  final String? initialImageUrl;
  final String? hintText;

  const ImagePickerComponent({
    Key? key,
    required this.labelText,
    required this.imageNotifier,
    this.validator,
    this.initialImageUrl,
    this.hintText
  }) : super(key: key);

  @override
  State<ImagePickerComponent> createState() => _ImagePickerComponentState();
}

class _ImagePickerComponentState extends State<ImagePickerComponent> {
  final ImagePicker _picker = ImagePicker();
  String? _errorText;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        File file;
        if (image.path.startsWith('content://')) {
          // Handle content URI by copying to temp file
          final bytes = await image.readAsBytes();
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
          await tempFile.writeAsBytes(bytes);
          file = tempFile;
        } else {
          file = File(image.path);
        }
        if (await file.exists()) {
          widget.imageNotifier.value = file;
          setState(() => _errorText = null);
        } else {
          setState(() => _errorText = 'Selected file does not exist');
        }
      }
    } catch (e) {
      print("Image pick error: $e");
      setState(() => _errorText = 'Failed to select image');
    }
  }

  void _removeImage() {
    widget.imageNotifier.value = null;
    setState(() => _errorText = null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: TextStyle(
            color: _errorText != null ? Colors.red : Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(
                color: _errorText != null ? Colors.red : Colors.grey,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ValueListenableBuilder<File?>(
              valueListenable: widget.imageNotifier,
              builder: (context, imageFile, _) {
                return Stack(
                  children: [
                    if (widget.initialImageUrl != null && imageFile == null)
                      _buildNetworkPreview(widget.initialImageUrl!)
                    else if (imageFile != null)
                      _buildFilePreview(imageFile)
                    else
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt,
                                color: Colors.grey[400], size: 40),
                            const SizedBox(height: 8),
                            Text(widget.hintText ?? 'Tap to upload image',
                                style: TextStyle(color: Colors.grey[400])),
                          ],
                        ),
                      ),
                    if (imageFile != null)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: GestureDetector(
                          onTap: _removeImage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      )
                  ],
                );
              },
            ),
          ),
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 12.0),
            child: Text(
              _errorText!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
  Widget _buildNetworkPreview(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.error),
      ),
    );
  }

  Widget _buildFilePreview(File file) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        file,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.error),
      ),
    );
  }
  Widget _buildImagePreview(Image image) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: image,
    );
  }
}