import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/lib/dashboard_provider/checkOfferProvider.dart';
import 'package:soundhive2/screens/non_creator/wallet/wallet.dart';
import 'package:soundhive2/utils/utils.dart';
import '../../../components/success.dart';
import '../../../components/widgets.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import 'package:soundhive2/lib/dashboard_provider/getActiveInvestmentProvider.dart';
import '../../../model/apiresponse_model.dart';
import '../../../model/market_orders_service_model.dart';
import '../../../model/offerFromUserModel.dart';
import '../../../model/user_model.dart';
import '../../../utils/alert_helper.dart';
import '../../../utils/app_colors.dart';
import '../../creator/profile/profile_screen.dart';
import '../../dashboard/marketplace/markplace_recept.dart';

final withdrawStateProvider = StateProvider<bool>((ref) => false);

class MarketplaceDetails extends ConsumerStatefulWidget {
  final MarketOrder service;
  final MemberCreatorResponse user;
  const MarketplaceDetails(
      {super.key, required this.service, required this.user});

  @override
  ConsumerState<MarketplaceDetails> createState() =>
      _MarketplaceDetailsScreenState();
}

class _MarketplaceDetailsScreenState extends ConsumerState<MarketplaceDetails> {
  int _currentStep = 0;
  String? selectedPaymentOption;
  late List<DateTime> availabilityDates = [];
  double? _bookingAmount;
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(checkOfferProvider.notifier).checkOffer(widget.service.id);
    });
  }

  void _showCounterOfferDialog(OfferFromUser offer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.BACKGROUNDCOLOR,
        title: const Text(
          'Counter Offer Received',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The creator has countered your offer:',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),

            // Original offer
            _buildCounterOfferRow(
              'Your Offer',
              ref.formatUserCurrency(offer.amount),
            ),

            // Counter offer
            _buildCounterOfferRow(
              'Counter Offer',
              ref.formatUserCurrency(offer.counterAmount ?? '0'),
            ),
            if (offer.counterMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Message: ${offer.counterMessage}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),

            if (offer.counterExpiresAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Expires: ${_formatDate(offer.counterExpiresAt!)}',
                  style: const TextStyle(color: Colors.yellow, fontSize: 12),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _rejectCounterOffer(offer),
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => _acceptCounterOffer(offer),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.PRIMARYCOLOR,
            ),
            child: const Text('Accept', style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterOfferRow(String label, String value,
      {bool isSecondary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSecondary ? Colors.grey : Colors.white70,
              fontSize: isSecondary ? 12 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isSecondary ? Colors.grey : Colors.white,
              fontSize: isSecondary ? 12 : 14,
              fontWeight: isSecondary ? FontWeight.normal : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptCounterOffer(OfferFromUser offer) async {
    Navigator.pop(context);

    try {
      final response =
          await ref.read(apiresponseProvider.notifier).acceptCounterOffer(
                context: context,
                offerId: offer.id,
              );

      if (response.status) {
        await ref
            .read(checkOfferProvider.notifier)
            .checkOffer(widget.service.id);

        showCustomAlert(
          context: context,
          isSuccess: true,
          title: 'Success',
          message: 'Counter offer accepted successfully!',
        );
      }
    } catch (error) {
      _handleCounterOfferError(error);
    }
  }

  Future<void> _rejectCounterOffer(OfferFromUser offer) async {
    Navigator.pop(context);

    try {
      final response =
          await ref.read(apiresponseProvider.notifier).rejectCounterOffer(
                context: context,
                offerId: offer.id,
              );

      if (response.status) {
        await ref
            .read(checkOfferProvider.notifier)
            .checkOffer(widget.service.id);

        showCustomAlert(
          context: context,
          isSuccess: true,
          title: 'Success',
          message: 'Counter offer rejected.',
        );
      }
    } catch (error) {
      _handleCounterOfferError(error);
    }
  }

  void _handleCounterOfferError(dynamic error) {
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

    showCustomAlert(
      context: context,
      isSuccess: false,
      title: 'Error',
      message: errorMessage,
    );
  }

  Widget _buildOfferButton(OfferFromUser? offer) {
    if (offer == null) {
      return OutlinedButton(
        onPressed: () => _showOfferBottomSheet(),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          'Make an Offer',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    switch (offer.status) {
      case 'ACCEPTED':
        return OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Offer Accepted',
            style: TextStyle(color: Colors.white),
          ),
        );

      case 'REJECTED':
        return OutlinedButton(
          onPressed: () => _showOfferBottomSheet(),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Make New Offer',
            style: TextStyle(color: Colors.white),
          ),
        );

      case 'COUNTERED':
        return OutlinedButton(
          onPressed: () => _showCounterOfferDialog(offer),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.yellow,
            side: const BorderSide(color: Colors.yellow),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Counter Offer',
            style: TextStyle(color: Colors.yellow),
          ),
        );

      case 'PENDING':
      default:
        return OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Offer Pending',
            style: TextStyle(color: Colors.white),
          ),
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
          onPressed: _currentStep > 0
              ? () => setState(() => _currentStep--)
              : () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _buildStepContent(),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildDetailsStep();
      case 1:
        return _buildConfirmationStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDetailsStep() {
    final offerState = ref.watch(checkOfferProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: widget.service.coverImage.isNotEmpty
                ? Image.network(
                    widget.service.coverImage,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Utils.buildImagePlaceholder(),
                  )
                : Utils.buildImagePlaceholder(),
          ),
        ),

        const SizedBox(height: 16),
        Text(
          widget.service.serviceName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Dynamic price display
        _buildPriceDisplay(),

        const SizedBox(height: 8),
        Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.BUTTONCOLOR,
              backgroundImage: (widget.service.user?.image != null &&
                      widget.service.user!.image!.isNotEmpty)
                  ? NetworkImage(widget.service.user!.image!)
                  : null,
              child: (widget.service.user?.image == null ||
                      widget.service.user!.image!.isEmpty)
                  ? Text(
                      widget.service.user?.firstName.isNotEmpty == true
                          ? widget.service.user!.firstName[0].toUpperCase()
                          : '',
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              "${widget.service.user?.firstName} ${widget.service.user?.lastName}",
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Icon(Icons.star, color: Colors.yellow, size: 18),
            Text(
              '4.5 rating',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            SizedBox(width: 10),
            Icon(Icons.download, color: Colors.grey, size: 18),
            Text(
              '20k downloads',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.location_on_outlined,
                color: Color(0xFFB0B0B6), size: 18),
            Text(
              widget.service.user?.creator?.location ?? '',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          "Description",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.service.serviceDescription,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Text(
          "About ${widget.service.user?.firstName} ${widget.service.user?.lastName}",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.service.user?.creator?.bio ?? '',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            offerState.when(
              data: (data) {
                return _buildOfferButton(data.offer);
              },
              error: (err, stack) {
                print(err);
                return const Text(
                  "Error loading offer",
                  style: TextStyle(color: Colors.red),
                );
    },
              loading: () => const SizedBox(
                width: 120,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
            RoundedButton(
              title: widget.user.user?.wallet == null
                  ? "Activate your wallet"
                  : 'Book',
              onPressed: () {
                if (widget.user.user?.wallet == null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          WalletScreen(user: widget.user.user!),
                    ),
                  );
                } else {
                  setState(() {
                    _currentStep++;
                  });
                }
              },
              color: AppColors.PRIMARYCOLOR,
              minWidth: 100,
              borderWidth: 0,
              borderRadius: 25.0,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceDisplay() {
    return Consumer(
      builder: (context, ref, child) {
        final offerState = ref.watch(checkOfferProvider);

        return offerState.when(
          data: (data) {
            final hasAcceptedOffer = data.offer?.status == 'ACCEPTED';
            final offerAmount = data.offer?.amount;

            if (hasAcceptedOffer && offerAmount != null) {
              _bookingAmount = double.parse(offerAmount);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Original price with strikethrough
                  Row(
                    children: [
                      Text(
                        ref.formatUserCurrency(widget.service.convertedRate),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.white,
                          decorationThickness: 3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'OFFER PRICE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Offer price
                  Text(
                    ref.formatUserCurrency(offerAmount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            } else {
              _bookingAmount = double.tryParse(offerAmount ?? "") ?? 0.0;
              return Text(
                ref.formatUserCurrency(widget.service.convertedRate),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              );
            }
          },
          loading: () => Text(
            ref.formatUserCurrency(widget.service.convertedRate),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          error: (_, __) => Text(
            ref.formatUserCurrency(widget.service.convertedRate),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfirmationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirm Booking',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        const SizedBox(height: 20),

        // Booking summary
        _buildBookingSummary(),

        const SizedBox(height: 20),
        PaymentMethodSelector(
          user: widget.user.user!,
          onSelected: (method) {
            print('Selected: $method');
            selectedPaymentOption = method;
          },
        ),
        const SizedBox(height: 20),
        DateSelectionInput(
          onDatesSelected: (dates) {
            availabilityDates = dates;
            print(
                'Selected dates: ${dates.map((d) => DateFormat('dd/MM/yyyy').format(d)).join(', ')}');
          },
        ),
        const SizedBox(height: 150),
        RoundedButton(
          title: 'Continue',
          color: AppColors.PRIMARYCOLOR,
          borderWidth: 0,
          borderRadius: 25.0,
          onPressed: () {
            _submitBooking();
          },
        )
      ],
    );
  }

  Widget _buildBookingSummary() {
    return Consumer(
      builder: (context, ref, child) {
        final offerState = ref.watch(checkOfferProvider);

        return offerState.when(
          data: (data) {
            final hasAcceptedOffer = data.offer?.status == 'ACCEPTED';
            final offerAmount = data.offer?.amount;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A191E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (hasAcceptedOffer && offerAmount != null) ...[
                    _buildSummaryRow('Original Price',
                        ref.formatUserCurrency(widget.service.convertedRate)),
                    _buildSummaryRow(
                        'Accepted Offer', ref.formatUserCurrency(offerAmount)),
                    const Divider(color: Colors.white24),
                    _buildSummaryRow(
                      'Total Amount',
                      ref.formatUserCurrency(offerAmount),
                      isTotal: true,
                    ),
                  ] else ...[
                    _buildSummaryRow(
                      'Total Amount',
                      ref.formatUserCurrency(widget.service.convertedRate),
                      isTotal: true,
                    ),
                  ],
                  if (hasAcceptedOffer) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A4D2E).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF4CAF50)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Color(0xFF4CAF50), size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Booking at your accepted offer price',
                              style: TextStyle(
                                color: Color(0xFF4CAF50),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          loading: () => _buildLoadingSummary(),
          error: (_, __) => _buildLoadingSummary(),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A191E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _showOfferBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return EditTextFieldBottomSheet(
          title: 'Offer Amount',
          initialValue: "",
          hintText: 'Enter your offer amount',
          buttonText: "Submit Offer",
          inputType: TextInputType.number,
          onSave: (newValue) {
            if (newValue.trim().isEmpty) return;
            Navigator.pop(context);
            _makeAnOffer(double.parse(newValue));
          },
        );
      },
    );
  }

  void _submitBooking() async {
    if (availabilityDates.isEmpty || selectedPaymentOption == null) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: 'Please select a payment method and at least one start date.',
      );
      return;
    }

    try {
      final offerState = ref.read(checkOfferProvider);
      final hasAcceptedOffer = offerState.value?.offer?.status == 'ACCEPTED';
      final offerAmount = offerState.value?.offer?.amount;

      // Use accepted offer amount if available, otherwise use service rate
      final bookingAmount =
          hasAcceptedOffer ? offerAmount : widget.service.convertedRate;

      final payload = {
        "service_id": widget.service.id,
        "date": availabilityDates
            .map((date) => DateFormat('yyyy-MM-dd').format(date))
            .toList(),
        "amount": bookingAmount,
      };

      final response = await ref.read(apiresponseProvider.notifier).buyServices(
            context: context,
            payload: payload,
          );

      if (response.status) {
        await ref.read(userProvider.notifier).loadUserProfile();
        ref.read(getActiveInvestmentProvider.notifier).getActiveInvestments(
              pageSize: 10,
            );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Success(
              title: 'Booked Successfully',
              subtitle: 'You have successfully booked this service',
              onButtonPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MarketplaceReceiptScreen(
                      service: widget.service,
                      paymentMethod: selectedPaymentOption ?? '',
                      availability: availabilityDates,
                      user: widget.user.user!,
                      price: bookingAmount.toString() ?? "",
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (error) {
      _handleBookingError(error);
    }
  }

  void _handleBookingError(dynamic error) {
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

  void _makeAnOffer(double amount) async {
    try {
      final payload = {
        "amount": amount,
        'service_id': widget.service.id,
      };

      final response = await ref.read(apiresponseProvider.notifier).makeOffer(
            context: context,
            payload: payload,
          );

      if (response.status) {
        await ref.read(userProvider.notifier).loadUserProfile();
        await ref
            .read(checkOfferProvider.notifier)
            .checkOffer(widget.service.id);

        showCustomAlert(
          context: context,
          isSuccess: true,
          title: 'Success',
          message: "Offer Made Successfully",
        );
      }
    } catch (error) {
      _handleOfferError(error);
    }
  }

  void _handleOfferError(dynamic error) {
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
