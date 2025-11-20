import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/model/offerFromUserModel.dart';

import '../../../components/rounded_button.dart';
import '../../../components/success.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import '../../../model/apiresponse_model.dart';
import '../../../model/getOfferFromUserProvider.dart';
import '../../../utils/alert_helper.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/utils.dart';

class OfferDetailScreen extends ConsumerStatefulWidget {
  final OfferFromUser offer;
  const OfferDetailScreen({super.key, required this.offer});

  @override
  ConsumerState<OfferDetailScreen> createState() => _OfferDetailScreenState();
}
class _OfferDetailScreenState extends ConsumerState<OfferDetailScreen>  {

  void _acceptOffer() async {

    try {

      final response = await ref.read(apiresponseProvider.notifier).acceptOffer(
        context: context,
        id: widget.offer.id
      );

      if(response.status) {
        await ref.read(getOfferFromUserProvider.notifier).getOffers(id: int.parse(widget.offer.serviceId));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Success(
              title: 'Offer Accepted',
              subtitle:
              'You have successfully accepted this offer',
              onButtonPressed: () {
               Navigator.pop(context);
              },
            ),
          ),
        );


      }


    } catch (error) {
      String errorMessage = 'An unexpected error occurred';

      print("Raw error: $error");

      if (error is DioException) {
        print("Dio error: ${error.response?.data}");
        print("Status code: ${error.response?.statusCode}");

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
    }
  }
  void _rejectOffer() async {

    try {

      final response = await ref.read(apiresponseProvider.notifier).rejectOffer(
          context: context,
          id: widget.offer.id
      );

      if(response.status) {
        await ref.read(getOfferFromUserProvider.notifier).getOffers(id: int.parse(widget.offer.serviceId));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Success(
              title: 'Offer Rejected',
              subtitle:
              'You have successfully rejected this offer',
              onButtonPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        );


      }


    } catch (error) {
      String errorMessage = 'An unexpected error occurred';

      print("Raw error: $error");

      if (error is DioException) {
        print("Dio error: ${error.response?.data}");
        print("Status code: ${error.response?.statusCode}");

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
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.BACKGROUNDCOLOR,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child:  Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.offer.service!.serviceName,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.w400,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.offer.status == "PENDING"
                  ? const Color.fromRGBO(255, 193, 7, 0.1)
                        : widget.offer.status == "ACCEPTED"
                ? const Color.fromRGBO(76, 175, 80, 0.1)
              : const Color.fromRGBO(244, 67, 54, 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.offer.status,
                    style: TextStyle(
                      color:widget.offer.status == "PENDING"
                          ? const Color(0xFFFFC107)
                          : widget.offer.status == "ACCEPTED"
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFF44336),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10,),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A191E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Utils.confirmRow('Client', "${widget.offer.user?.firstName} ${widget.offer.user?.lastName}"),
                  Utils.confirmRow('Price', ref.formatCreatorCurrency(widget.offer.convertedAmount)),
                  Utils.confirmRow('Service Request', widget.offer.service?.serviceName),
                ],

              ),
            ),
            const SizedBox(height: 50,),
            if(widget.offer.status != "ACCEPTED")
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: _rejectOffer,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text("Reject"),
                  ),

                  RoundedButton(
                    title:  "Accept",
                    onPressed: _acceptOffer,
                    color: AppColors.PRIMARYCOLOR,
                    minWidth: 100,
                    borderWidth: 0,
                    borderRadius: 25.0,
                  ),
                ]
            ),
          ],
        ),
      ),
    );
  }
}