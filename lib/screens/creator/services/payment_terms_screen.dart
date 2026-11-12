import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/payment_terms_editor.dart';
import '../../../components/rounded_button.dart';
import '../../../lib/dashboard_provider/booking_payment_provider.dart';
import '../../../model/service_model.dart';
import '../../../utils/alert_helper.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/utils.dart';

/// Module 2 — creator sets how clients pay for this service: full escrow, or
/// an advance plus payment stages. Returns the saved [PaymentTerms] when popped
/// after a save, so the service page can update without a reload.
class PaymentTermsScreen extends ConsumerStatefulWidget {
  final ServiceItem service;
  final PaymentTerms? current; // latest terms if the service page already changed them

  const PaymentTermsScreen({super.key, required this.service, this.current});

  @override
  ConsumerState<PaymentTermsScreen> createState() => _PaymentTermsScreenState();
}

class _PaymentTermsScreenState extends ConsumerState<PaymentTermsScreen> {
  late PaymentTerms _terms;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _terms = widget.current ??
        PaymentTerms.fromService(
          allowsMilestones: widget.service.allowsMilestones,
          template: widget.service.milestoneTemplate,
        );
  }

  Future<void> _save() async {
    if (!_terms.isValid || _saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(bookingPaymentApiProvider).updatePaymentTerms(
            serviceId: widget.service.id,
            allowsMilestones: _terms.enabled,
            maxAdvancePercent: _terms.enabled ? _terms.advance : null,
            template: _terms.enabled ? _terms.stages : null,
          );
      if (!mounted) return;
      showCustomAlert(context: context, isSuccess: true, title: 'Saved', message: 'New bookings will use these payment terms.');
      Navigator.pop(context, _terms);
    } on BookingPaymentError catch (e) {
      if (mounted) showCustomAlert(context: context, isSuccess: false, title: 'Could not save', message: e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final on = theme.colorScheme.onSurface;
    final price = double.tryParse(widget.service.rate.replaceAll(',', ''));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: on), onPressed: () => Navigator.pop(context)),
        title: Text('Payment terms', style: TextStyle(color: on, fontSize: 18)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(widget.service.serviceName, style: TextStyle(color: on, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('How should clients pay you for this service?',
                      style: TextStyle(color: on.withOpacity(0.6), fontSize: 13)),
                  const SizedBox(height: 16),
                  PaymentTermsEditor(
                    terms: _terms,
                    isDark: isDark,
                    price: price,
                    formatMoney: (v) => Utils.formatCurrency(v, currencyCode: widget.service.currency),
                    onChanged: (t) => setState(() => _terms = t),
                  ),
                  const SizedBox(height: 12),
                  Text('Changes apply to new bookings. Existing bookings keep the terms they were booked with.',
                      style: TextStyle(color: on.withOpacity(0.5), fontSize: 11)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: RoundedButton(
                title: _saving ? 'Saving…' : 'Save payment terms',
                color: _terms.isValid ? AppColors.BUTTONCOLOR : AppColors.INACTIVEBUTTONCOLOR,
                borderWidth: 0,
                borderRadius: 25,
                onPressed: (_saving || !_terms.isValid) ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
