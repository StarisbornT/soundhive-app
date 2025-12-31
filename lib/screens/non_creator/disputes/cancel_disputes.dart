import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/utils/app_colors.dart';
import 'package:soundhive2/components/label_text.dart';

import '../../../components/rounded_button.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import '../../../components/success.dart';
import '../../../model/apiresponse_model.dart';
import '../../../utils/alert_helper.dart';
import '../non_creator.dart';

class CancelRequest extends ConsumerStatefulWidget {
  final int disputeId;
  const CancelRequest({super.key, required this.disputeId});

  @override
  _CancelRequestScreenState createState() => _CancelRequestScreenState();
}

class _CancelRequestScreenState extends ConsumerState<CancelRequest> {
  final TextEditingController cancelController = TextEditingController();
  @override
  void dispose() {
    cancelController.dispose();
    super.dispose();
  }
  void cancelDispute() async {

    try {
      final response =  await ref.read(apiresponseProvider.notifier).cancelDispute(
        context: context,
        disputeId: widget.disputeId,
        payload: {
          "reason": cancelController.text
        },
      );

      if(response.status) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Success(
              title: 'Dispute cancelled Successfully',
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
  @override
  Widget build(BuildContext context) {

    return Scaffold(
     
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Cancel service request",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10,),
            Text(
              'Please note that cancellation will attract a charge of 1% on your order cancellation, and your funds will be paid to your Soundhive Vest wallet.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14.0,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            LabeledTextField(
              label: 'Why do you want to cancel',
              controller: cancelController,
              hintText: "Enter reason for cancellation",
              maxLines: 4,
            ),
            const Spacer(),
            // Confirm cancellation button.
            RoundedButton(
              title: 'Confirm Cancellation',
              onPressed: cancelDispute,
              color: AppColors.BUTTONCOLOR,
            ),
          ],
        ),
      ),
    );
  }
}