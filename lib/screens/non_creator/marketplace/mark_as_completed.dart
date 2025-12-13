import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soundhive2/lib/dashboard_provider/get_current_user_dispute_provider.dart';
import 'package:soundhive2/model/active_investment_model.dart';
import 'package:soundhive2/screens/chats/chat_screen.dart';
import 'package:soundhive2/screens/non_creator/disputes/cancel_disputes.dart';
import 'package:soundhive2/screens/non_creator/disputes/dispute_chat_screen.dart';
import 'package:soundhive2/screens/non_creator/non_creator.dart';
import '../../../components/image_picker.dart';
import '../../../components/rounded_button.dart';
import '../../../components/success.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/navigator_provider.dart';
import '../../../model/apiresponse_model.dart';
import '../../../model/user_model.dart';
import '../../../utils/alert_helper.dart';
import '../../../utils/app_colors.dart';

class MarkAsCompletedScreen extends ConsumerStatefulWidget {
  final ActiveInvestment services;
  final User user;
  const MarkAsCompletedScreen({super.key, required this.services, required this.user});

  @override
  ConsumerState<MarkAsCompletedScreen> createState() => _MarkAsCompletedScreenState();
}

class _MarkAsCompletedScreenState extends ConsumerState<MarkAsCompletedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await ref.read(getCurrentUserDisputeProvider.notifier)
            .getDispute(bookingId: widget.services.id);
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final services = widget.services;
    final disputeState = ref.watch(getCurrentUserDisputeProvider);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              ref.read(bottomNavigationProvider.notifier).state = 0;
              Navigator.popUntil(context, ModalRoute.withName(NonCreatorDashboard.id));
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${services.service?.serviceName}\nrequest initiated",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "The payment you made for the ${services.service?.serviceName} has been withheld by Cre8Hive and won’t be released until you mark ${services.service?.user?.firstName}'s job as “Completed”.",
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        services.service?.user?.image != null
                            ? Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(services.service?.user?.image ?? ''),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                            : Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.BUTTONCOLOR,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            services.service!.user!.firstName.isNotEmpty
                                ? services.service!.user!.firstName[0].toUpperCase()
                                : "?",
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                       // const CircleAvatar(
                       //    radius: 22,
                       //    backgroundImage:  AssetImage("images/logo.png")
                       //  ),

                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${services.service?.user?.firstName} ${services.service?.user?.lastName}",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            const  Row(
                                children: [
                                  Icon(Icons.star, color: Colors.amber, size: 14),
                                   SizedBox(width: 4),
                                  Text(
                                    ' 4.5 rating',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Stack(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(context,  MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        sellerId: widget.services.service!.user!.id.toString(),
                                        sellerName: "${widget.services.service?.user?.firstName} ${widget.services.service?.user?.lastName}",
                                        receiverId: widget.user.id.toString(),
                                        senderName: "${widget.user.firstName} ${widget.user.lastName}",
                                        sellerService: widget.services.service!.serviceName,
                                      ),
                                    ),);
                                  },
                                  icon: const Icon(Icons.chat_bubble, color: Color(0xFFA585F9),),
                                ),
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              "Chat",
                              style: TextStyle(
                                color: Color(0xFFA585F9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )

                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildStepItem("1", "${services.service?.user?.firstName} has been notified of your service request. Reach out to the service provider via the chat button beside his/her name, and discuss the modalities of how you want your project handled."),
                    const SizedBox(height: 16),
                    _buildStepItem("2", "Once the project or service has been fully rendered, click the “Mark as completed” button below to release the service provider’s payment."),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 221, 118, 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Do not do this if your job has not been completed",
                              style: TextStyle(color: Color(0xFFFFDD76), fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              RoundedButton(
                title: 'Mark as completed',
                color: const Color(0xFF4D3490),
                borderWidth: 0,
                borderRadius: 25.0,
                onPressed: () {
                  markAsCompleted(context);
                },
              ),
              const SizedBox(height: 16),
              disputeState.when(
                data: (dispute)  {
                  if(dispute.data != null) {
                    if(dispute.data?.status != "CLOSED") {
                      return  Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>  CancelRequest(disputeId: dispute.data!.id,),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Text("Cancel request"),
                            ),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(context,  MaterialPageRoute(
                                  builder: (context) => DisputeChatScreen(
                                    sellerId: widget.services.service!.user!.id.toString(),
                                    sellerName: "${widget.services.service?.user?.firstName} ${widget.services.service?.user?.lastName}",
                                    userId: widget.user.id.toString(),
                                    senderName: "${widget.user.firstName} ${widget.user.lastName}",
                                    disputeId: dispute.data!.id.toString(),
                                  ),
                                ),);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text("View Dispute"),
                            ),
                          ),
                        ],
                      );
                    }else {
                      return SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            dispute.data?.status != "CLOSED" ?   disputeBottomSheet(context) : null;
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text(dispute.data?.status != "CLOSED" ? "Initiate dispute" : "Dispute has been closed"),
                        ),
                      );
                    }

                  }else {
                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          dispute.data?.status != "CLOSED" ?   disputeBottomSheet(context) : null;
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Text(dispute.data?.status != "CLOSED" ? "Initiate dispute" : "Dispute has been closed"),
                      ),
                    );
                  }
                },  error: (err, stack) => Text(
                "Error: $err",
                style: const TextStyle(color: Colors.red),
              ),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
              )

            ],
          ),
        ),
      ),
    );
  }
  void reviewBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F0F10),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (BuildContext context) {
        return _ReviewBottomSheetContent(submitInvestment: _submitInvestment,services: widget.services,);
      },
    );
  }

  void disputeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20,),
              Image.asset('images/dispute.png'),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to initiate a dispute resolution with this service provider?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFB0B0B6)),
              ),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  RoundedButton(
                    title: 'Initiate Dispute',
                    color: const Color(0xFF4D3490),
                    borderWidth: 0,
                    borderRadius: 100.0,
                    minWidth: 90,
                    onPressed: () {
                      initiateDispute();
                    },
                  )
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  void markAsCompleted(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Mark as completed?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure this job has been completed?',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFB0B0B6),
                ),
              ),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  RoundedButton(
                    title: 'Confirm',
                    color: const Color(0xFF4D3490),
                    borderWidth: 0,
                    borderRadius: 100.0,
                    minWidth: 90,
                    onPressed: () {
                      // Close the current bottom sheet FIRST
                      Navigator.pop(context);

                      // Then show the review bottom sheet after a short delay
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (mounted) {
                          reviewBottomSheet(context);
                        }
                      });
                    },
                  )
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void initiateDispute() async {

    try {
      final response =  await ref.read(apiresponseProvider.notifier).initiateDispute(
        context: context,
        payload: {
          "booking_id": widget.services.id,
          "creator_id": widget.services.userId
        },
      );

      if(response.status) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Success(
              title: 'Dispute Initiated Successfully',
              subtitle: 'You have successfully initiated dispute',
              onButtonPressed: () {
                Navigator.pushNamed(context, NonCreatorDashboard.id);
              },
            ),
          ),
        );
      }

    } catch (error) {
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

      print("Error: $errorMessage");

      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: errorMessage,
      );
    }
  }

  void _submitInvestment() async {

    try {
      final response =  await ref.read(apiresponseProvider.notifier).markAsCompleted(
        context: context,
        memberServiceId: widget.services.id,
      );

      if(response.status) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Success(
              title: 'Your service marked as completed',
              subtitle: 'You service has successfully marked as completed',
              onButtonPressed: () {
               Navigator.pushNamed(context, NonCreatorDashboard.id);
              },
            ),
          ),
        );
      }

    } catch (error) {
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

      print("Error: $errorMessage");

      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: errorMessage,
      );
    }
  }

  Widget _buildStepItem(String step, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$step.",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _ReviewBottomSheetContent extends ConsumerStatefulWidget {
  final Function submitInvestment;
  final ActiveInvestment services;
  const _ReviewBottomSheetContent({required this.submitInvestment, required this.services});

  @override
  ConsumerState<_ReviewBottomSheetContent> createState() =>
      _ReviewBottomSheetContentState();
}

class _ReviewBottomSheetContentState extends ConsumerState<_ReviewBottomSheetContent> {
  final TextEditingController reviewController = TextEditingController();
  final ValueNotifier<File?> _imageNotifier = ValueNotifier<File?>(null);
  double rating = 0;
  List<String> selectedTags = [];

  final List<String> tags = [
    "Professional",
    "Great Communication",
    "Timely",
    "Highly Skilled",
    "Value for Money",
  ];

  String? _uploadedImageUrl;

  Future<void> _uploadMediaToCloudinary() async {
    final imageFile = _imageNotifier.value;

    if (imageFile == null) {
      throw Exception('Image or utility bill is missing');
    }

    // Upload both images
    final imageUrl = await _uploadFileToCloudinary(
      file: imageFile,
      resourceType: 'image',
      preset: 'soundhive',
    );


    _uploadedImageUrl = imageUrl; // For ID image
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

    // Check if widget is still mounted
    if (!mounted) return;

    // Validate required fields
    if (rating == 0) {
      if (mounted) {
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: 'Please provide a rating',
        );
      }
      return;
    }

    if (reviewController.text.trim().isEmpty) {
      if (mounted) {
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: 'Please write a review',
        );
      }
      return;
    }

    if (selectedTags.isEmpty) {
      if (mounted) {
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: 'Please select at least one tag',
        );
      }
      return;
    }

    try {
      if (_imageNotifier.value != null) {
        final imageFile = _imageNotifier.value!;
        bool isImageValid = await _isValidLocalPath(imageFile.path);

        if (!await imageFile.exists() || !isImageValid) {
          throw Exception('Invalid or missing image file');
        }

        // Upload both files
        await _uploadMediaToCloudinary();
      }

      // Submit to backend
      final response = await _submitToBackend();

      if (!mounted) return;

      if (response.status) {
        // Close the bottom sheet
        Navigator.pop(context);

        // Call the submitInvestment callback
        widget.submitInvestment();
      } else {
        // Show error if review submission failed
        if (mounted) {
          showCustomAlert(
            context: context,
            isSuccess: false,
            title: 'Error',
            message: response.message,
          );
        }
      }

    } catch (error) {
      print('FULL ERROR DETAILS: $error');

      if (!mounted) return;

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
      } else if (error is String) {
        errorMessage = error;
      }

      if (mounted) {
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: errorMessage,
        );
      }
    }
  }

  Future<ApiResponseModel> _submitToBackend() async {
    // Get the creator ID safely
    String? creatorId = widget.services.service?.userId.toString();


    final response = await ref.read(apiresponseProvider.notifier).makeReview(
      context: context,
      payload: {
        "creator_id": creatorId,
        "booking_id": widget.services.id,
        "rating": rating.toInt(),
        "review_text": reviewController.text.trim(),
        "tags": selectedTags,
        "media_url": _uploadedImageUrl,
      },
    );

    return response;
  }


  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85, // Reduced from 0.92 to prevent overflow
      maxChildSize: 0.92,     // Reduced from 0.95
      minChildSize: 0.5,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F0F10),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Close indicator
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title section
                const Text(
                  "Hurray🎉!!! Drop a review",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Kindly tell us your experience with this service provider",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 20),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ⭐ Rating Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: List.generate(
                            5,
                                (index) => IconButton(
                              onPressed: () {
                                setState(() => rating = index + 1.0);
                              },
                              icon: Icon(
                                index < rating ? Icons.star : Icons.star_border,
                                size: 32,
                                color: index < rating ? Colors.amber : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // 📝 Review Text Field
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade800),
                          ),
                          child: TextField(
                            controller: reviewController,
                            maxLines: 4,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: "Enter your review",
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),

                        // 🏷 TAGS
                        const Text(
                          "Select at least one of the tags below that best describes the service provider's performance.",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 15),

                        Wrap(
                          spacing: 10,
                          runSpacing: 12,
                          children: tags.map((tag) {
                            final isSelected = selectedTags.contains(tag);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    selectedTags.remove(tag);
                                  } else {
                                    selectedTags.add(tag);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: isSelected
                                      ? Colors.deepPurple.shade600
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.deepPurple.shade400
                                        : Colors.grey.shade700,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 30),

                        // 📸 Upload Media
                        ImagePickerComponent(
                          labelText: 'Media (Optional)',
                          imageNotifier: _imageNotifier,
                          hintText: 'Upload Media',
                          validator: (value) {
                            if (value == null) {
                              return ' image is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),

                // 📩 Submit Button (Fixed at bottom)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8A3FFC),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      "Submit review",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

