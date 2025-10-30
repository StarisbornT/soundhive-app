import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/lib/dashboard_provider/get_current_user_dispute_provider.dart';
import 'package:soundhive2/model/active_investment_model.dart';
import 'package:soundhive2/model/market_orders_service_model.dart';
import 'package:soundhive2/model/service_model.dart';
import 'package:soundhive2/screens/non_creator/chat_screen.dart';
import 'package:soundhive2/screens/non_creator/disputes/cancel_disputes.dart';
import 'package:soundhive2/screens/non_creator/disputes/dispute_chat_screen.dart';
import 'package:soundhive2/screens/non_creator/non_creator.dart';
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
  _ServiceOrderSuccessScreenState createState() => _ServiceOrderSuccessScreenState();
}

class _ServiceOrderSuccessScreenState extends ConsumerState<MarkAsCompletedScreen> {
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
    print("Services $services");
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
                "The payment you made for the rentage has been withheld by Soundlive and won’t be released until you mark ${services.service?.user?.firstName}'s job as “Completed”.",
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
                  return const SizedBox.shrink();
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
              const SizedBox(height: 40,),
              const Text(
                'Mark as completed?',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'Are you sure this job has been completed?',
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
                  const SizedBox(width: 16),
                  RoundedButton(
                    title: 'Confirm',
                    color: const Color(0xFF4D3490),
                    borderWidth: 0,
                    borderRadius: 100.0,
                    minWidth: 90,
                    onPressed: () {
                      _submitInvestment();
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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
