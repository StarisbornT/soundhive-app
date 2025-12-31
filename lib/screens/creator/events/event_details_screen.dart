import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/lib/dashboard_provider/eventProvider.dart';
import 'package:soundhive2/model/event_model.dart';
import 'package:soundhive2/screens/creator/events/edit_event_screen.dart';
import 'package:soundhive2/screens/creator/events/event_screen.dart';

import '../../../components/success.dart';
import '../../../components/widgets.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/event_stats_provider.dart';
import '../../../model/apiresponse_model.dart';
import '../../../utils/alert_helper.dart';
import 'event_registration_screen.dart';
class EventDetailsScreen extends ConsumerStatefulWidget {
  final EventItem event;
  const EventDetailsScreen({super.key, required this.event});

  @override
  ConsumerState<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends ConsumerState<EventDetailsScreen> {
  late TextEditingController reasonForCancelController;

  @override
  void initState() {
    super.initState();
    reasonForCancelController = TextEditingController();
  }

  @override
  void dispose() {
    reasonForCancelController.dispose();
    super.dispose();
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void showBottomSheet(EventItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => EventActionSheet(
        onView: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventRegistrationScreen(event: widget.event),
            ),
          );
        },
        onEdit: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditEventScreen(event: item),
            ),
          );
        },
        onDelete: () {
          Navigator.pop(context);
          ConfirmBottomSheet.show(
            context: context,
            controller: reasonForCancelController,
            message: "Are you sure you want to cancel this event?",
            confirmText: "Cancel Event",
            cancelText: "Cancel",
            confirmColor: Theme.of(context).colorScheme.primary,
            onConfirm: () {
              cancelEvent(item);
            },
          );
        },
      ),
    );
  }

  void cancelEvent(item) async {
    try {
      final response = await ref.read(apiresponseProvider.notifier).cancelEvent(
          context: context,
          id: item.id,
          payload: {
            "reason_for_cancellation": reasonForCancelController.text
          }
      );

      if (response.status) {
        // Refresh before leaving
        await ref.read(eventStatsProvider.notifier).getStats();
        ref.invalidate(eventProvider('published'));
        ref.invalidate(eventProvider('pending'));
        ref.invalidate(eventProvider('rejected'));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Success(
              title: 'Your event is cancelled successfully',
              subtitle: 'Your event is cancelled successfully',
              onButtonPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const EventScreen()),
                );
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

      if(mounted) {
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: errorMessage,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final event = widget.event;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showBottomSheet(event);
            },
            icon: Icon(
              Icons.more_vert_sharp,
              color: theme.colorScheme.onSurface,
            ),
            iconSize: 20,
          )
        ],
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
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.event,
                          size: 60,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                )
                    : Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.event,
                    size: 60,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: event.status == "PENDING"
                        ? const Color.fromRGBO(255, 193, 7, 0.1)
                        : event.status == "PUBLISHED"
                        ? const Color.fromRGBO(76, 175, 80, 0.1)
                        : const Color.fromRGBO(244, 67, 54, 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: event.status == "PENDING"
                          ? const Color(0xFFFFC107).withOpacity(0.3)
                          : event.status == "PUBLISHED"
                          ? const Color(0xFF4CAF50).withOpacity(0.3)
                          : const Color(0xFFF44336).withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    event.status,
                    style: TextStyle(
                      color: event.status == "PENDING"
                          ? const Color(0xFFFFC107)
                          : event.status == "PUBLISHED"
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFF44336),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 70),
                Text(
                  event.type == "PAID" ? "${event.currency} ${event.amount}" : event.type,
                  style: TextStyle(
                    color: event.type == "PAID"
                        ? Colors.green
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                    Icons.location_on_outlined,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    size: 18
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.location,
                    style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if(event.type == "CANCELLED")
                  Text(
                    '10 Tickets Sold',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 12
                    ),
                  ),
                const SizedBox(width: 10),
                Text(
                  "${_formatDate(event.date)} ${event.time}",
                  style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 12
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "About Event",
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                event.description,
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                    fontSize: 14
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}