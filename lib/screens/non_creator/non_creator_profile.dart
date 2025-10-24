import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soundhive2/model/user_model.dart';
import 'package:soundhive2/utils/utils.dart';

import '../../lib/dashboard_provider/apiresponseprovider.dart';
import '../../lib/dashboard_provider/user_provider.dart';
import '../../model/apiresponse_model.dart';
import '../../utils/alert_helper.dart';
import '../../utils/app_colors.dart';

class NonCreatorProfile extends ConsumerStatefulWidget {
  final MemberCreatorResponse user;
  const NonCreatorProfile({super.key, required this.user});

  @override
  _NonCreatorProfileState createState() => _NonCreatorProfileState();
}

class _NonCreatorProfileState extends ConsumerState<NonCreatorProfile> {
  final ValueNotifier<File?> _imageNotifier = ValueNotifier<File?>(null);
  String? _uploadedImageUrl;
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final imageFile = File(pickedFile.path);
    _imageNotifier.value = imageFile;

    try {

      final imageUrl = await _uploadFileToCloudinary(
        file: imageFile,
        resourceType: 'image',
        preset: 'soundhive',
      );

      setState(() {
        _uploadedImageUrl = imageUrl;
      });

      await updateProfile(imageUrl); // Send to backend
      await ref.read(userProvider.notifier).loadUserProfile(); // Reload avatar

    } catch (e) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: 'Failed to upload image.',
      );
    }
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

  Future<void> updateProfile(String imageUrl) async {
    final payload = {
      "image": imageUrl,
    };

    try {
      await ref.read(apiresponseProvider.notifier).updateProfile(context: context,payload: payload);
      showCustomAlert(
        context: context,
        isSuccess: true,
        title: 'Success',
        message: 'Profile image updated successfully.',
      );
    } catch (error) {
      String errorMessage = 'An unexpected error occurred';
      if (error is DioException && error.response?.data != null) {
        try {
          final apiResponse = ApiResponseModel.fromJson(error.response?.data);
          errorMessage = apiResponse.message;
        } catch (_) {}
      }
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: errorMessage,
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    const Color cardBackgroundColor = Color(0xFF1A191E); // Slightly lighter for cards
    const Color textColor = Colors.white;
    const Color hintTextColor = Colors.white70;
    final user = ref.watch(userProvider);
    return Scaffold(
      backgroundColor: AppColors.BACKGROUNDCOLOR,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0, // No shadow
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            // Implement navigation back
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.topLeft,
              child: const Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10,),
            // Profile Picture Section
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.BUTTONCOLOR,
              backgroundImage: (user.value?.user?.image != null)
                  ? NetworkImage(user.value!.user!.image!)
                  : null,
              child: (user.value?.user?.image == null)
                  ? Text(
                widget.user.user!.firstName.isNotEmpty
                    ? widget.user.user!.firstName[0].toUpperCase()
                    : '',
                style: const TextStyle(fontSize: 24, color: Colors.white),
              )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              "${widget.user.user!.firstName} ${widget.user.user!.lastName}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickAndUploadImage,
              icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFFB0B0B6), size: 12),
              label: const Text(
                'Change profile picture',
                style: TextStyle(color: Color(0xFFB0B0B6), fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2C2C2C)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
            const SizedBox(height: 30),

            // Other Information Card
            Utils.buildOtherInfoCard(
              showTitle: false,
              user: widget.user,
              cardBackgroundColor: cardBackgroundColor,
              textColor: textColor,
              hintTextColor: hintTextColor,
            ),
          ],
        ),
      ),
    );
  }
}