import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/screens/non_creator/wallet/wallet.dart';
import 'package:soundhive2/utils/utils.dart';
import '../../../components/widgets.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import '../../../model/apiresponse_model.dart';
import '../../../model/market_orders_service_model.dart';
import '../../../model/user_model.dart';
import '../../../utils/alert_helper.dart';
import '../../../utils/app_colors.dart';
import '../../dashboard/marketplace/markplace_recept.dart';
final withdrawStateProvider = StateProvider<bool>((ref) => false);
class MarketplaceDetails extends ConsumerStatefulWidget {
  final MarketOrder service;
  final MemberCreatorResponse user;
  const MarketplaceDetails({super.key, required this.service, required this.user});

  @override
  ConsumerState<MarketplaceDetails> createState() => _MarketplaceDetailsScreenState();
}
class _MarketplaceDetailsScreenState extends ConsumerState<MarketplaceDetails>  {

  int _currentStep = 0;
  String? selectedPaymentOption;
  late List<DateTime> availablityDates = [];

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
    return  Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child:  ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: (widget.service.coverImage.isNotEmpty)
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
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          ref.formatUserCurrency(widget.service.convertedRate),
          style: const TextStyle(
            color: Colors.white, fontSize: 24, fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
         Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.BUTTONCOLOR,
              backgroundImage: (widget.service.user?.image != null && widget.service.user!.image!.isNotEmpty)
                  ? NetworkImage(widget.service.user!.image!)
                  : null,
              child: (widget.service.user?.image == null || widget.service.user!.image!.isEmpty)
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
            const Icon(Icons.location_on_outlined, color: Color(0xFFB0B0B6), size: 18),
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
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.service.serviceDescription ?? '',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 16),
         Text(
          "About ${widget.service.user?.firstName} ${widget.service.user?.lastName}",
          style: const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
       widget.service.user?.creator?.bio ?? '',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Center(
          child: RoundedButton(
            title:  widget.user.user?.wallet == null ?
                "Activate your wallet"
                :  'Book',
            onPressed: () {
              if(widget.user.user?.wallet == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>  WalletScreen(user: widget.user.user!,),
                  ),
                );
              }
              else {
                setState(() {
                  _currentStep++;
                });
              }
            },
            color: AppColors.PRIMARYCOLOR,
            borderWidth: 0,
            borderRadius: 25.0,
          ),
        ),

      ],
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
        PaymentMethodSelector(
          user: widget.user.user!,
          onSelected: (method) {
            print('Selected: $method');
            selectedPaymentOption= method;
          },
        ),
        const SizedBox(height: 20),
        DateSelectionInput(
          onDatesSelected: (dates) {
            availablityDates = dates;
            print('Selected dates: ${dates.map((d) => DateFormat('dd/MM/yyyy').format(d)).join(', ')}');
          },
        ),
        const SizedBox(height: 430,),
        RoundedButton(title: 'Continue',
          color: AppColors.PRIMARYCOLOR,
          borderWidth: 0,
          borderRadius: 25.0,
          onPressed: () {
            _submitInvestment();
          },
        )
      ],
    );
  }
  void _submitInvestment() async {
    if (availablityDates.isEmpty || selectedPaymentOption == null) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: 'Please select a payment method and at least one start date.',
      );
      return;
    }

    try {
      final payload = {
        "service_id": widget.service.id,
        "date": availablityDates.map((date) => DateFormat('yyyy-MM-dd').format(date)).toList(),
        "amount": widget.service.rate,
      };

      final response = await ref.read(apiresponseProvider.notifier).buyServices(
        context: context,
        payload: payload,
      );

      if(response.status) {
        await ref.read(userProvider.notifier).loadUserProfile();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MarketplaceReceiptScreen(
              service: widget.service,
              paymentMethod: selectedPaymentOption ?? '',
              availability: availablityDates,
              user: widget.user.user!,
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



}

