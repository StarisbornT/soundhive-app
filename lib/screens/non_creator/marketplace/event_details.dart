import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/model/event_model.dart';
import 'package:soundhive2/screens/non_creator/marketplace/ticket_reciept_screen.dart';
import 'package:soundhive2/utils/utils.dart';
import '../../../components/success.dart';
import '../../../components/widgets.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import '../../../lib/dashboard_provider/getMyTicketProvider.dart';
import '../../../model/apiresponse_model.dart';
import '../../../model/ticket_model.dart';
import '../../../model/user_model.dart';
import '../../../utils/alert_helper.dart';
import '../../../utils/app_colors.dart';
final withdrawStateProvider = StateProvider<bool>((ref) => false);

class EventDetails extends ConsumerStatefulWidget {
  final EventItem event;
  final User user;
  const EventDetails(
      {super.key, required this.event, required this.user});

  @override
  ConsumerState<EventDetails> createState() =>
      _EventDetailsState();
}

class _EventDetailsState extends ConsumerState<EventDetails> {
  int _currentStep = 0;
  String? selectedPaymentOption;
  late List<DateTime> availabilityDates = [];
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
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
    final event = widget.event;
    return  Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: event.image.isNotEmpty
                ? Image.network(
              event.image,
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
        Row(
          children: [
            Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(width: 10,),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: event.isUpcoming
                      ? const Color.fromRGBO(255, 193, 7, 0.1)
                      : event.isCompleted
                      ? const Color.fromRGBO(76, 175, 80, 0.1)
                      : event.isOngoing
                      ? const Color.fromRGBO(188, 174, 226, 0.1)
                      : const Color.fromRGBO(244, 67, 54, 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  event.eventStatus,
                  style: TextStyle(
                    color: event.isUpcoming
                        ? const Color(0xFFFFC107)
                        : event.isCompleted
                        ? const Color(0xFF4CAF50)
                        : event.isOngoing
                        ? const Color(0xFFBCAEE2)
                        : const Color(0xFFF44336),
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 10,),
            Text(
              event.type == "PAID" ? ref.formatUserCurrency(event.convertedRate) : event.type,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.location_on_outlined,
                color: Color(0xFFB0B0B6), size: 18),
            Text(
              event.location,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if(event.type == "CANCELLED")
              const Text(
                '10 Tickets Sold',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            const SizedBox(width: 10),
            Text(
              "${_formatDate(event.date)} ${event.time}",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          "About Event",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          event.description,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        RoundedButton(
          title: 'Buy Ticket',
          onPressed: () {
              setState(() {
                _currentStep++;
              });
          },
          color: AppColors.PRIMARYCOLOR,
          minWidth: 100,
          borderWidth: 0,
          borderRadius: 25.0,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    final event = widget.event;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(
          'Confirm Purchase of ${event.title}',
          style: const TextStyle(color: Colors.white, fontSize: 24),
                 ),
        const SizedBox(height: 20),

        // Booking summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A191E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Utils.confirmRow('Ticket', ref.formatUserCurrency(event.convertedRate)),
              const SizedBox(height: 20),
              Utils.confirmRow('Event', event.title),
              const SizedBox(height: 20),
              Utils.confirmRow('Event Time',  _formatDate(event.date)),
              const SizedBox(height: 20),
              Utils.confirmRow(
                'Location',
               event.location,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PaymentMethodSelector(
          user: widget.user,
          onSelected: (method) {
            print('Selected: $method');
            selectedPaymentOption = method;
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




  void _submitBooking() async {
    if (selectedPaymentOption == null) {
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: 'Please select a payment method',
      );
      return;
    }

    try {
      final payload = {
        "event_id": widget.event.id,
        "amount": widget.event.convertedRate,
      };

      final response = await ref.read(apiresponseProvider.notifier).buyTicket(
        context: context,
        payload: payload,
      );

      if (response.status && response.data != null) {
        await ref.read(userProvider.notifier).loadUserProfile();

        // Create TicketItem from the response data
        final ticket = TicketItem.fromMap(response.data);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Success(
              title: 'Booked Successfully',
              subtitle: 'You have successfully booked this event',
              onButtonPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TicketReceiptScreen(
                      ticket: ticket,
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


}
