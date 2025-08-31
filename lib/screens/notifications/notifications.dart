import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:soundhive2/lib/dashboard_provider/notification_api_provider.dart';
import '../../model/notification_model.dart';
import '../../utils/app_colors.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationApiProvider.notifier).getNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationApiProvider);

    return Scaffold(
      backgroundColor: AppColors.BACKGROUNDCOLOR,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: notificationState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (notificationModel) {
          if (notificationModel.data.notifications.isEmpty) {
            return const Center(
              child: Text('No notifications yet'),
            );
          }

          return _buildNotificationContent(notificationModel.data);
        },
      ),
    );
  }

  Widget _buildNotificationContent(PaginatedNotifications paginatedData) {
    // Group notifications by date
    final Map<String, List<NotificationData>> groupedNotifications = {};

    for (final notification in paginatedData.notifications) {
      final date = _formatNotificationDate(notification.createdAt);
      groupedNotifications.putIfAbsent(date, () => []).add(notification);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        ...groupedNotifications.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                  ),
                ),
              ),
              ...entry.value.map((notification) =>
                  _buildNotificationItem(notification)
              ),
              const SizedBox(height: 16),
            ],
          );
        }),

        // Pagination controls if needed
        if (paginatedData.nextPageUrl != null)
          TextButton(
            onPressed: () {
              ref.read(notificationApiProvider.notifier).loadMore();
            },
            child: const Text('Load More'),
          ),
      ],
    );
  }

  Widget _buildNotificationItem(NotificationData notification) {
    return InkWell(
      onTap: () {
        // Mark as read when tapped
        ref.read(notificationApiProvider.notifier)
            .markAsRead(notification.id);

        // Handle navigation based on notification type
        _handleNotificationTap(notification);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white10
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white70,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getNotificationColor(notification.type),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: notification.isRead ? Colors.white70: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8), // small space before the time
                      Text(
                        _formatNotificationTime(notification.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (notification.data.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildNotificationData(notification.data),
                  ],
                ],
              ),
            ),
            if (!notification.isRead)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.circle,
                  color: Colors.blue,
                  size: 8,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationData(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data['amount'] != null)
            Text(
              'Amount: ₦${data['amount']}',
              style: const TextStyle(fontSize: 12),
            ),
          if (data['property_name'] != null)
            Text(
              'Property: ${data['property_name']}',
              style: const TextStyle(fontSize: 12),
            ),
          if (data['location'] != null)
            Text(
              'Location: ${data['location']}',
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'transaction':
        return AppColors.BUTTONCOLOR;
      case 'card':
        return AppColors.GREYCOLOR;
      case 'alert':
        return Colors.red;
      case 'document':
        return AppColors.DARKGREY;
      default:
        return Colors.blue;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'transaction':
        return Icons.payment;
      case 'promo':
        return Icons.local_offer;
      case 'alert':
        return Icons.warning;
      case 'card':
        return Icons.credit_card;
      case 'document':
        return Icons.document_scanner_outlined;
      default:
        return Icons.notifications;
    }
  }

  String _formatNotificationDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, y').format(date);
    }
  }

  String _formatNotificationTime(String dateString) {
    return DateFormat('h:mm a').format(DateTime.parse(dateString));
  }

  void _handleNotificationTap(NotificationData notification) {
    // Handle navigation based on notification type
    switch (notification.type) {
      case 'transaction':
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => TransactionDetailScreen(
      //       transactionId: notification.data['transaction_id'],
      //     ),
      //   ),
      // );
        break;
      case 'property':
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => PropertyDetailScreen(
      //       propertyId: notification.data['property_id'],
      //     ),
      //   ),
      // );
        break;
    // Add other cases as needed
    }
  }
}