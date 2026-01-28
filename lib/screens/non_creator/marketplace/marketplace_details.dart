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
import '../../../model/active_investment_model.dart';
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

  void _showCounterOfferDialog(OfferFromUser offer, ThemeData theme, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          'Counter Offer Received',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The creator has countered your offer:',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),

            // Original offer
            _buildCounterOfferRow(
              'Your Offer',
              ref.formatUserCurrency(offer.amount),
              theme,
            ),

            // Counter offer
            _buildCounterOfferRow(
              'Counter Offer',
              ref.formatUserCurrency(offer.counterAmount ?? '0'),
              theme,
            ),
            if (offer.counterMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Message: ${offer.counterMessage}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ),

            if (offer.counterExpiresAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Expires: ${_formatDate(offer.counterExpiresAt!)}',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _rejectCounterOffer(offer),
            child: Text(
              'Reject',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
          ElevatedButton(
            onPressed: () => _acceptCounterOffer(offer),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.BUTTONCOLOR,
            ),
            child: Text(
              'Accept',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterOfferRow(String label, String value, ThemeData theme,
      {bool isSecondary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSecondary
                  ? theme.colorScheme.onSurface.withOpacity(0.5)
                  : theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: isSecondary ? 12 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isSecondary
                  ? theme.colorScheme.onSurface.withOpacity(0.5)
                  : theme.colorScheme.onSurface,
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

  Widget _buildOfferButton(OfferFromUser? offer, ThemeData theme, bool isDark) {
    if (offer == null) {
      return OutlinedButton(
        onPressed: () => _showOfferBottomSheet(theme, isDark),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
          side: BorderSide(color: theme.dividerColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          'Make an Offer',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
      );
    }

    switch (offer.status) {
      case 'ACCEPTED':
        return OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface.withOpacity(0.5),
            side: BorderSide(color: theme.dividerColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            'Offer Accepted',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
        );

      case 'REJECTED':
        return OutlinedButton(
          onPressed: () => _showOfferBottomSheet(theme, isDark),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface,
            side: BorderSide(color: theme.dividerColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            'Make New Offer',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        );

      case 'COUNTERED':
        return OutlinedButton(
          onPressed: () => _showCounterOfferDialog(offer, theme, isDark),
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
            foregroundColor: theme.colorScheme.onSurface.withOpacity(0.5),
            side: BorderSide(color: theme.dividerColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            'Offer Pending',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
          onPressed: _currentStep > 0
              ? () => setState(() => _currentStep--)
              : () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _buildStepContent(theme, isDark),
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme, bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildDetailsStep(theme, isDark);
      case 1:
        return _buildConfirmationStep(theme, isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDetailsStep(ThemeData theme, bool isDark) {
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
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Dynamic price display
        _buildPriceDisplay(theme),

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
                style: TextStyle(fontSize: 14, color: Colors.white),
              )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              "${widget.service.user?.firstName} ${widget.service.user?.lastName}",
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 18),
            Text(
              (widget.service.user?.creator != null)
                  ? Utils.getOverallRating(widget.service.user!.creator!).toString()
                  : "0.0",

              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.download,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                size: 18),
            Text(
              '20k downloads',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.location_on_outlined,
                color: theme.colorScheme.onSurface.withOpacity(0.6), size: 18),
            Text(
              widget.service.user?.creator?.location ?? '',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          "Description",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.service.serviceDescription,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "About ${widget.service.user?.firstName} ${widget.service.user?.lastName}",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.service.user?.creator?.bio ?? '',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        offerState.when(
          data: (data) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildOfferButton(data.offer, theme, isDark),
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
                    }else if (data.offer?.status == "PENDING") {
                      showCustomAlert(context: context, isSuccess: false, title: "Error", message: "Your Offer is on Pending");
                    }
                    else {
                      setState(() {
                        _currentStep++;
                      });
                    }
                  },
                  color: AppColors.BUTTONCOLOR,
                  minWidth: 100,
                  borderWidth: 0,
                  borderRadius: 25.0,
                ),
              ],
            );
          },
          error: (err, stack) {
            debugPrint(err.toString());
            return Text(
              "Error loading offer",
              style: TextStyle(color: theme.colorScheme.error),
            );
          },
          loading: () => SizedBox(
            width: 120,
            child: Center(
              child: CircularProgressIndicator(color: theme.colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceDisplay(ThemeData theme) {
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
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 16,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: theme.colorScheme.onSurface.withOpacity(0.5),
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
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
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
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              );
            }
          },
          loading: () => Text(
            ref.formatUserCurrency(widget.service.convertedRate),
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
          error: (_, __) => Text(
            ref.formatUserCurrency(widget.service.convertedRate),
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfirmationStep(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Booking',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 20),

        // Booking summary
        _buildBookingSummary(theme, isDark),

        const SizedBox(height: 20),
        PaymentMethodSelector(
          user: widget.user.user!,
          onSelected: (method) {
            debugPrint('Selected: $method');
            selectedPaymentOption = method;
          },
          theme: theme,
          isDark: isDark,
        ),
        const SizedBox(height: 20),
        DateSelectionInput(
          onDatesSelected: (dates) {
            availabilityDates = dates;
            debugPrint(
                'Selected dates: ${dates.map((d) => DateFormat('dd/MM/yyyy').format(d)).join(', ')}');
          },
        ),
        const SizedBox(height: 150),
        RoundedButton(
          title: 'Continue',
          color: AppColors.BUTTONCOLOR,
          borderWidth: 0,
          borderRadius: 25.0,
          onPressed: () {
            _submitBooking();
          },
        )
      ],
    );
  }

  Widget _buildBookingSummary(ThemeData theme, bool isDark) {
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
                color: isDark
                    ? const Color(0xFF1A191E)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Summary',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (hasAcceptedOffer && offerAmount != null) ...[
                    _buildSummaryRow(
                      'Original Price',
                      ref.formatUserCurrency(widget.service.convertedRate),
                      theme,
                    ),
                    _buildSummaryRow(
                      'Accepted Offer',
                      ref.formatUserCurrency(offerAmount),
                      theme,
                    ),
                    Divider(color: theme.dividerColor),
                    _buildSummaryRow(
                      'Total Amount',
                      ref.formatUserCurrency(offerAmount),
                      theme,
                      isTotal: true,
                    ),
                  ] else ...[
                    _buildSummaryRow(
                      'Total Amount',
                      ref.formatUserCurrency(widget.service.convertedRate),
                      theme,
                      isTotal: true,
                    ),
                  ],
                  if (hasAcceptedOffer) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A4D2E).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF4CAF50)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: const Color(0xFF4CAF50), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Booking at your accepted offer price',
                              style: TextStyle(
                                color: const Color(0xFF4CAF50),
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
          loading: () => _buildLoadingSummary(theme, isDark),
          error: (_, __) => _buildLoadingSummary(theme, isDark),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeData theme,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSummary(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A191E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      ),
    );
  }

  void _showOfferBottomSheet(ThemeData theme, bool isDark) {
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
        final bookings = ActiveInvestment.fromMap(response.data);

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
                      service: bookings,
                      paymentMethod: selectedPaymentOption ?? '',
                      price: bookingAmount.toString(),
                      availability: availabilityDates,
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

    debugPrint("Raw error: $error");

    if (error is DioException) {
      debugPrint("Dio error: ${error.response?.data}");
      debugPrint("Status code: ${error.response?.statusCode}");

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

    debugPrint("Raw error: $error");

    if (error is DioException) {
      debugPrint("Dio error: ${error.response?.data}");
      debugPrint("Status code: ${error.response?.statusCode}");

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
