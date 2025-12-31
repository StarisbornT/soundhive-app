import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../components/rounded_button.dart';
import '../../../model/active_investment_model.dart';
import '../../../utils/utils.dart';
import '../../non_creator/marketplace/mark_as_completed.dart';

class MarketplaceReceiptScreen extends ConsumerStatefulWidget {
  final ActiveInvestment service;
  final String paymentMethod;
  final String price;
  final List<DateTime> availability;
  const MarketplaceReceiptScreen({
    super.key,
    required this.service,
    required this.paymentMethod,
    required this.price,
    required this.availability
  });

  @override
  ConsumerState<MarketplaceReceiptScreen> createState() => _AssetScreenState();
}

class _AssetScreenState extends ConsumerState<MarketplaceReceiptScreen> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final service = widget.service;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Booking Details',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your service booking confirmation',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Receipt Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A191E) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.dividerColor,
                ),
                boxShadow: !isDark ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReceiptItem(
                    label: 'Service',
                    value: service.service?.serviceName ?? 'N/A',
                    theme: theme,
                  ),
                  const SizedBox(height: 20),
                  Divider(color: theme.dividerColor.withOpacity(0.3)),
                  _buildReceiptItem(
                    label: 'Price',
                    value: ref.formatUserCurrency(widget.price),
                    theme: theme,
                    isPrice: true,
                  ),
                  const SizedBox(height: 20),
                  Divider(color: theme.dividerColor.withOpacity(0.3)),
                  _buildReceiptItem(
                    label: 'Payment Method',
                    value: widget.paymentMethod,
                    theme: theme,
                  ),
                  const SizedBox(height: 20),
                  Divider(color: theme.dividerColor.withOpacity(0.3)),
                  _buildReceiptItem(
                    label: 'Start Date',
                    value: widget.availability.isNotEmpty
                        ? widget.availability
                        .map((date) => DateFormat('dd MMM yyyy').format(date))
                        .join(', ')
                        : 'No dates selected',
                    theme: theme,
                  ),
                  const SizedBox(height: 20),

                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: theme.colorScheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Successful',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Booking Info Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color.fromRGBO(255, 221, 118, 0.1)
                    : const Color.fromRGBO(217, 119, 6, 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFFFFDD76).withOpacity(0.3)
                      : const Color(0xFFD97706).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isDark ? const Color(0xFFFFDD76) : const Color(0xFFD97706),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can now communicate with the service provider and mark the job as completed when finished.',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFFFDD76) : const Color(0xFFD97706),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Continue Button
            RoundedButton(
              title: 'Continue',
              color: theme.colorScheme.primary,
              borderWidth: 0,
              borderRadius: 25.0,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MarkAsCompletedScreen(
                      services: widget.service, // Pass the ActiveInvestment
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptItem({
    required String label,
    required String value,
    required ThemeData theme,
    bool isPrice = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: isPrice ? 18 : 14,
            fontWeight: isPrice ? FontWeight.bold : FontWeight.normal,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// You'll also need to update the Utils.confirmRow method if it exists,
// or replace it with the _buildReceiptItem method above.
