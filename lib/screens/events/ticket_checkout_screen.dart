import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/rounded_button.dart';
import '../../components/widgets.dart';
import '../../lib/dashboard_provider/ticketing_provider.dart';
import '../../lib/dashboard_provider/user_provider.dart';
import '../../model/ticketing_model.dart';
import '../../utils/alert_helper.dart';
import '../../utils/app_colors.dart';
import '../../utils/utils.dart';
import '../dashboard/verification_webview.dart';
import 'ticket_order_screen.dart';

/// Module 3 — choose ticket categories and quantities, then pay.
/// Works for Cre8Hive events and partner events (e.g. Future Fest by Gbedu).
class TicketCheckoutScreen extends ConsumerStatefulWidget {
  final int eventId;

  const TicketCheckoutScreen({super.key, required this.eventId});

  @override
  ConsumerState<TicketCheckoutScreen> createState() => _TicketCheckoutScreenState();
}

class _TicketCheckoutScreenState extends ConsumerState<TicketCheckoutScreen> {
  final Map<int, int> _qty = {};
  String _method = 'wallet';
  bool _paying = false;

  ThemeData get _theme => Theme.of(context);
  Color get _on => _theme.colorScheme.onSurface;
  Color get _card => _theme.brightness == Brightness.dark ? const Color(0xFF1A191E) : Colors.grey[100]!;

  int get _totalQty => _qty.values.fold(0, (a, b) => a + b);

  double _total(EventTicketing t) =>
      t.categories.fold(0.0, (sum, c) => sum + c.userPrice * (_qty[c.id] ?? 0));

  void _change(TicketCategory c, int delta, int orderMax) {
    final current = _qty[c.id] ?? 0;
    int next = current + delta;

    // Jump straight to the category minimum, and back to zero below it.
    if (delta > 0 && current == 0) next = c.minPerOrder;
    if (delta < 0 && next < c.minPerOrder) next = 0;

    final cap = c.available == null ? c.maxPerOrder : (c.available! < c.maxPerOrder ? c.available! : c.maxPerOrder);
    if (next > cap) return;
    if (delta > 0 && _totalQty - current + next > orderMax) {
      showCustomAlert(context: context, isSuccess: false, title: 'Limit reached', message: 'You can buy at most $orderMax tickets in one order.');
      return;
    }
    setState(() => _qty[c.id] = next);
  }

  Future<void> _pay(EventTicketing t) async {
    if (_totalQty == 0) return;
    setState(() => _paying = true);

    try {
      final result = await ref.read(ticketingApiProvider).checkout(
            eventId: t.eventId,
            quantities: Map.of(_qty),
            paymentMethod: _method,
          );

      if (!mounted) return;

      if (result.paymentLink != null) {
        await Navigator.push<String>(
          context,
          MaterialPageRoute(builder: (_) => VerificationWebView(url: result.paymentLink!, title: 'Complete Payment')),
        );
      }

      try {
        await ref.read(userProvider.notifier).loadUserProfile();
      } catch (_) {}

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TicketOrderScreen(reference: result.order.reference, initial: result.order)),
      );
    } on TicketingError catch (e) {
      if (!mounted) return;
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: e.insufficientFunds ? 'Insufficient funds' : 'Could not complete purchase',
        message: e.insufficientFunds ? 'Your wallet balance is too low. Pay by card instead, or fund your wallet.' : e.message,
      );
      ref.invalidate(eventTicketingProvider(widget.eventId)); // refresh availability
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventTicketingProvider(widget.eventId));

    return Scaffold(
      backgroundColor: _theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: _on), onPressed: () => Navigator.pop(context)),
        title: Text('Get tickets', style: TextStyle(color: _on, fontSize: 18)),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(e.toString(), textAlign: TextAlign.center, style: TextStyle(color: _on.withOpacity(0.7))),
              TextButton(onPressed: () => ref.invalidate(eventTicketingProvider(widget.eventId)), child: const Text('Try again')),
            ]),
          ),
        ),
        data: (t) => _content(t),
      ),
    );
  }

  Widget _content(EventTicketing t) {
    final money = (double v) => Utils.formatCurrency(v, currencyCode: t.userCurrency);
    final total = _total(t);
    final balance = double.tryParse(ref.watch(userProvider).value?.user?.wallet?.balance?.toString() ?? '');

    return Column(children: [
      Expanded(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(eventTicketingProvider(widget.eventId)),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (t.image != null && t.image!.startsWith('http'))
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: NetworkImageWithLoader(imageUrl: t.image!, height: 160, width: double.infinity),
              ),
            const SizedBox(height: 12),
            Text(t.title, style: TextStyle(color: _on, fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('${t.date}  ${t.time.length >= 5 ? t.time.substring(0, 5) : t.time}', style: TextStyle(color: _on.withOpacity(0.6), fontSize: 13)),
            Text(t.location, style: TextStyle(color: _on.withOpacity(0.6), fontSize: 13)),
            if (t.ageRestriction != null) Text('Age: ${t.ageRestriction}', style: TextStyle(color: _on.withOpacity(0.6), fontSize: 13)),
            const SizedBox(height: 6),
            Text('Tickets issued by ${t.issuedBy}', style: const TextStyle(color: AppColors.PRIMARY_ACCENT, fontSize: 12)),
            const SizedBox(height: 20),

            if (!t.purchasable)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(t.closedReason ?? 'Tickets are not available right now.', style: const TextStyle(color: Colors.orange)),
              ),

            Text('Choose tickets', style: TextStyle(color: _on, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            for (final c in t.categories) _categoryCard(c, t, money),

            const SizedBox(height: 16),
            Text('Pay with', style: TextStyle(color: _on, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _methodTile('wallet', 'Cre8Pay wallet', balance == null ? null : 'Balance: ${money(balance)}'),
            _methodTile('flutterwave', 'Card / bank transfer', 'Secure payment via Flutterwave'),
            const SizedBox(height: 12),
            Text(
              'Each ticket has its own QR code. You will find them in My Tickets and in your email.',
              style: TextStyle(color: _on.withOpacity(0.5), fontSize: 11, height: 1.4),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),

      // Sticky total + pay
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(color: _card, border: Border(top: BorderSide(color: _on.withOpacity(0.08)))),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('$_totalQty ticket${_totalQty == 1 ? '' : 's'}', style: TextStyle(color: _on.withOpacity(0.6), fontSize: 12)),
              Text(money(total), style: TextStyle(color: _on, fontSize: 20, fontWeight: FontWeight.w700)),
            ]),
          ),
          SizedBox(
            width: 160,
            child: RoundedButton(
              title: _paying ? 'Please wait…' : (total == 0 && _totalQty > 0 ? 'Get tickets' : 'Pay now'),
              color: (_totalQty > 0 && t.purchasable && !_paying) ? AppColors.BUTTONCOLOR : AppColors.INACTIVEBUTTONCOLOR,
              borderWidth: 0,
              borderRadius: 25,
              minWidth: 140,
              onPressed: (_totalQty > 0 && t.purchasable && !_paying) ? () => _pay(t) : null,
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _categoryCard(TicketCategory c, EventTicketing t, String Function(double) money) {
    final q = _qty[c.id] ?? 0;
    final canBuy = c.onSale && t.purchasable;
    final label = c.soldOut ? 'Sold out' : (!c.onSale ? 'Not on sale' : (c.available != null && c.available! <= 10 ? '${c.available} left' : null));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: q > 0 ? AppColors.BUTTONCOLOR : Colors.transparent),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.name, style: TextStyle(color: canBuy ? _on : _on.withOpacity(0.4), fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(c.userPrice == 0 ? 'Free' : money(c.userPrice), style: TextStyle(color: canBuy ? _on : _on.withOpacity(0.4), fontSize: 15)),
            if ((c.perks ?? c.description) != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(c.perks ?? c.description!, style: TextStyle(color: _on.withOpacity(0.55), fontSize: 11)),
              ),
            if (label != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(label, style: TextStyle(color: c.soldOut || !c.onSale ? Colors.redAccent : Colors.orange, fontSize: 11)),
              ),
          ]),
        ),
        if (canBuy) ...[
          _stepButton(Icons.remove, q > 0 ? () => _change(c, -1, t.maxPerOrder) : null),
          SizedBox(width: 32, child: Text('$q', textAlign: TextAlign.center, style: TextStyle(color: _on, fontSize: 16))),
          _stepButton(Icons.add, () => _change(c, 1, t.maxPerOrder)),
        ],
      ]),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: onTap == null ? _on.withOpacity(0.15) : AppColors.BUTTONCOLOR),
          ),
          child: Icon(icon, size: 18, color: onTap == null ? _on.withOpacity(0.3) : AppColors.BUTTONCOLOR),
        ),
      );

  Widget _methodTile(String value, String title, String? subtitle) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
        child: RadioListTile<String>(
          value: value,
          groupValue: _method,
          activeColor: AppColors.BUTTONCOLOR,
          title: Text(title, style: TextStyle(color: _on, fontSize: 14)),
          subtitle: subtitle == null ? null : Text(subtitle, style: TextStyle(color: _on.withOpacity(0.6), fontSize: 12)),
          onChanged: (v) => setState(() => _method = v ?? 'wallet'),
        ),
      );
}
