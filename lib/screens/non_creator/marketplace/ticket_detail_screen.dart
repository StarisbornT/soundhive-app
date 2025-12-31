import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/model/ticket_model.dart';
import 'package:soundhive2/screens/non_creator/marketplace/ticket_reciept_screen.dart';
import 'package:soundhive2/utils/app_colors.dart';
import '../../../components/rounded_button.dart';
import '../../../lib/navigator_provider.dart';
import '../../../utils/utils.dart';
import '../non_creator.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final TicketItem ticket;
  const TicketDetailScreen({super.key, required this.ticket});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
  @override
  Widget build(BuildContext context) {
    final event = widget.ticket.event;
    return PopScope(
      canPop: false, // Disable default back navigation
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          ref.read(bottomNavigationProvider.notifier).state = 0;
          Navigator.pushNamed(context, NonCreatorDashboard.id);
        }
      },
      child: Scaffold(
       
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFB0B0B6)),
            onPressed: () {
              ref.read(bottomNavigationProvider.notifier).state = 0;
              Navigator.pushNamed(context, NonCreatorDashboard.id);
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
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
                    event.type == "PAID" ? ref.formatUserCurrency(widget.ticket.amount) : event.type,
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
                title: 'View Ticket',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TicketReceiptScreen(
                        ticket: widget.ticket,
                      ),
                    ),
                  );
                },
                color: AppColors.PRIMARYCOLOR,
                minWidth: 100,
                borderWidth: 0,
                borderRadius: 25.0,
              ),
              const SizedBox(height: 16),
            ],
          ),
        )
      ),
    );
  }
}