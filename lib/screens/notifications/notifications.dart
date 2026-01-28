import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:soundhive2/lib/dashboard_provider/notification_api_provider.dart';
import 'package:soundhive2/model/user_model.dart';
import 'package:soundhive2/screens/creator/creator_dashboard.dart';
import 'package:soundhive2/screens/non_creator/marketplace/marketplace_details.dart';
import 'package:soundhive2/screens/non_creator/non_creator.dart';
import '../../lib/dashboard_provider/user_provider.dart';
import '../../lib/navigator_provider.dart';
import '../../model/active_investment_model.dart';
import '../../model/market_orders_service_model.dart';
import '../../model/notification_model.dart';
import '../../model/offerFromUserModel.dart';
import '../../utils/app_colors.dart';
import '../creator/services/offer_details.dart';
import '../non_creator/marketplace/mark_as_completed.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
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
     
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle( fontSize: 18),
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
    final user = ref.watch(userProvider);
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
                    // color: Colors.white
                  ),
                ),
              ),
              ...entry.value.map((notification) =>
                  _buildNotificationItem(notification, user.value!)
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

  Widget _buildNotificationItem(NotificationData notification, MemberCreatorResponse user) {
    return InkWell(
      onTap: () {
        // Mark as read when tapped
        ref.read(notificationApiProvider.notifier)
            .markAsRead(notification.id);

        // Handle navigation based on notification type
        _handleNotificationTap(notification, user);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
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
                color: AppColors.PRIMARYCOLOR,
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            // color: notification.isRead ? Colors.white70: Colors.white,
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
                          // color: Colors.white,
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
        color: AppColors.PRIMARYCOLOR,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data['amount'] != null)
            Text(
              'Amount: ${data['currency'] ?? data['service_currency'] ?? data['original_currency']}${data['amount']}',
              style: const TextStyle(fontSize: 12, fontFamily: 'Roboto',),
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
      case 'fund_wallet':
        return Icons.payment;
      case 'book':
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

  void _handleNotificationTap(NotificationData notification, MemberCreatorResponse user) {

    // Handle navigation based on notification type
    switch (notification.type) {
      case 'fund_wallet':
        Navigator.pushNamed(context, NonCreatorDashboard.id);
        ref
            .read(bottomNavigationProvider.notifier)
            .state = 1;
        break;
      case 'book':
        final data = ActiveInvestment.fromMap(notification.data['booking']);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MarkAsCompletedScreen(
              services: data,
            ),
          ),
        );
        break;
      case 'creator_booking':
        Navigator.pushNamed(context, CreatorDashboard.id);
        break;
      case 'new_offer':
        if (notification.data['offer'] != null) {
          // Convert Map to OfferFromUser object
          final offerData = notification.data['offer'];
          final offer = OfferFromUser.fromMap(offerData);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OfferDetailScreen(
                offer: offer,
              ),
            ),
          );
        } else {
          // Fallback: Show error or navigate differently
          print('Offer data not available in notification');
        }
        break;
      case 'offer_sent':
        if (notification.data['service'] != null) {
          // Convert Map to OfferFromUser object
          final offerData = notification.data['service'];
          final offer = MarketOrder.fromMap(offerData);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MarketplaceDetails(
                service: offer,
                user: user,
              ),
            ),
          );
        } else {
          // Fallback: Show error or navigate differently
          print('Offer data not available in notification');
        }
        break;
    // Add other cases as needed
    }
  }
}