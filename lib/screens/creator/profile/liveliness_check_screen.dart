import 'dart:io';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../components/success.dart';
import '../../../lib/dashboard_provider/apiresponseprovider.dart';
import '../../../model/apiresponse_model.dart';
import '../../../utils/alert_helper.dart';
import '../../../utils/app_colors.dart';
import '../creator_dashboard.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';

class LivelinessCheckScreen extends ConsumerStatefulWidget {
  const LivelinessCheckScreen({super.key});

  @override
  ConsumerState<LivelinessCheckScreen> createState() => _LivelinessCheckScreenState();
}

class _LivelinessCheckScreenState extends ConsumerState<LivelinessCheckScreen> {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraReady = true);
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // Helper to upload to Cloudinary
  Future<String?> _uploadToCloudinary(File file) async {
    try {
      final dio = Dio();
      final response = await dio.post(
        'https://api.cloudinary.com/v1_1/djutcezwz/image/upload',
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path),
          'upload_preset': 'soundhive',
        }),
      );
      return response.data['secure_url'];
    } catch (e) {
      return null;
    }
  }

  Future<void> _handleLivelinessSubmit() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    setState(() => _isSubmitting = true);

    try {
      // 1. Capture two rapid photos to simulate liveliness
      final xFile1 = await _cameraController!.takePicture();
      await Future.delayed(const Duration(milliseconds: 500));
      final xFile2 = await _cameraController!.takePicture();

      // 2. Upload to Cloudinary
      final url1 = await _uploadToCloudinary(File(xFile1.path));
      final url2 = await _uploadToCloudinary(File(xFile2.path));

      if (url1 == null || url2 == null) {
        throw Exception("Image upload failed");
      }

      // 3. Submit to your backend
      await ref.read(apiresponseProvider.notifier).livelinessCheck(
        context: context,
        payload: {
          "image1": url1,
          "image2": url2,
        },
      );

      await ref.read(userProvider.notifier).loadUserProfile();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Success(
            title: 'Submitted Successfully',
            subtitle: 'Your account is under review and you will get feedback within 24 hours.',
            onButtonPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreatorDashboard()),
              );
            }
          ),
        ),
      );
    } catch (error) {
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF050112), // Matching the dark background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const Spacer(),
            // Camera Preview Circle
            Center(
              child: Container(
                width: size.width * 0.7,
                height: size.width * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 4),
                ),
                child: ClipOval(
                  child: _isCameraReady
                      ? AspectRatio(
                    aspectRatio: 1,
                    child: CameraPreview(_cameraController!),
                  )
                      : const Center(child: CircularProgressIndicator(color: Colors.green)),
                ),
              ),
            ),
            const Spacer(),
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleLivelinessSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9D50DD), // Purple color from design
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text(
                  "Submit",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}