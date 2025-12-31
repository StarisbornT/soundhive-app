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

class _OfferDetailScreenState extends ConsumerState<OfferDetailScreen> {
  final TextEditingController _counterAmountController = TextEditingController();
  final TextEditingController _counterMessageController = TextEditingController();
  bool _isCountering = false;

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
              subtitle: 'You have successfully accepted this offer',
              onButtonPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        );
      }
    } catch (error) {
      _handleError(error);
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
              subtitle: 'You have successfully rejected this offer',
              onButtonPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        );
      }
    } catch (error) {
      _handleError(error);
    }
  }

  void _showCounterOfferDialog() {
    final originalAmount = widget.offer.convertedAmount ?? 0;
    final suggestedAmount = (originalAmount * 1.1).toStringAsFixed(2);
    _counterAmountController.text = suggestedAmount;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A191E),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Make Counter Offer',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Original Offer:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
               ref.formatCreatorCurrency(widget.offer.convertedAmount ?? ''),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _counterAmountController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Counter Amount',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'Enter your counter offer amount',
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.PRIMARYCOLOR),
                  ),
                  prefixText: ref.creatorBaseCurrency,
                  prefixStyle: const TextStyle(color: Colors.white),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _counterMessageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Message (Optional)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'Add a message for your counter offer...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.PRIMARYCOLOR),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _counterAmountController.clear();
              _counterMessageController.clear();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: _sendCounterOffer,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.PRIMARYCOLOR,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Send Counter Offer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _sendCounterOffer() async {
    final amount = _counterAmountController.text.trim();
    final message = _counterMessageController.text.trim();

    if (amount.isEmpty) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: 'Please enter a counter offer amount',
      );
      return;
    }

    final amountValue = double.tryParse(amount);
    if (amountValue == null || amountValue <= 0) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: 'Please enter a valid amount',
      );
      return;
    }

    setState(() {
      _isCountering = true;
    });

    try {
      final response = await ref.read(apiresponseProvider.notifier).counterOffer(
        context: context,
        id: widget.offer.id,
        counterAmount: amount,
        counterMessage: message,
      );

      if (response.status) {
        Navigator.pop(context); // Close dialog
        _counterAmountController.clear();
        _counterMessageController.clear();

        await ref.read(getOfferFromUserProvider.notifier).getOffers(id: int.parse(widget.offer.serviceId));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Success(
              title: 'Counter Offer Sent',
              subtitle: 'Your counter offer has been sent successfully. Waiting for user response.',
              onButtonPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        );
      }
    } catch (error) {
      _handleError(error);
    } finally {
      setState(() {
        _isCountering = false;
      });
    }
  }

  void _handleError(dynamic error) {
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

  @override
  void dispose() {
    _counterAmountController.dispose();
    _counterMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.offer.service!.serviceName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.offer.status == "PENDING"
                        ? const Color.fromRGBO(255, 193, 7, 0.1)
                        : widget.offer.status == "ACCEPTED"
                        ? const Color.fromRGBO(76, 175, 80, 0.1)
                        : widget.offer.status == "COUNTERED"
                        ? const Color.fromRGBO(33, 150, 243, 0.1)
                        : const Color.fromRGBO(244, 67, 54, 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.offer.status,
                    style: TextStyle(
                      color: widget.offer.status == "PENDING"
                          ? const Color(0xFFFFC107)
                          : widget.offer.status == "ACCEPTED"
                          ? const Color(0xFF4CAF50)
                          : widget.offer.status == "COUNTERED"
                          ? const Color(0xFF2196F3)
                          : const Color(0xFFF44336),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Show counter offer details if status is COUNTERED
            if (widget.offer.status == "COUNTERED")
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D47A1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2196F3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.local_offer, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Counter Offer Sent',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Utils.confirmRow('Your Counter Amount', '${widget.offer.counterAmount} ${widget.offer.counterCurrency}'),
                    if (widget.offer.counterMessage != null && widget.offer.counterMessage!.isNotEmpty)
                      Utils.confirmRow('Your Message', widget.offer.counterMessage!),
                    Utils.confirmRow('Expires', widget.offer.counterExpiresAt != null ? _formatDate(widget.offer.counterExpiresAt!) : 'N/A'),
                  ],
                ),
              ),

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
                  if (widget.offer.counterMessage != null && widget.offer.counterMessage!.isNotEmpty)
                    Utils.confirmRow('Client Message', widget.offer.counterMessage!),
                ],
              ),
            ),
            const SizedBox(height: 50),

            if (widget.offer.status == "PENDING")
              Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runAlignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 12,
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

                    // Counter Offer Button
                    OutlinedButton(
                      onPressed: _showCounterOfferDialog,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2196F3),
                        side: const BorderSide(color: Color(0xFF2196F3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("Counter Offer"),
                    ),

                    RoundedButton(
                      title: "Accept",
                      onPressed: _acceptOffer,
                      color: AppColors.PRIMARYCOLOR,
                      minWidth: 100,
                      borderWidth: 0,
                      borderRadius: 25.0,
                    ),
                  ]
              ),

            if (widget.offer.status == "COUNTERED")
              Center(
                child: Text(
                  'Waiting for client to respond to your counter offer',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}