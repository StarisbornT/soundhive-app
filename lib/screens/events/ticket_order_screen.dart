import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lib/dashboard_provider/ticketing_provider.dart';
import '../../model/ticketing_model.dart';
import '../../utils/utils.dart';

/// Module 3 — order status and the tickets themselves.
/// Polls while the organiser's system is issuing (usually a few seconds; if
/// their system is down the server keeps retrying and notifies the buyer).
class TicketOrderScreen extends ConsumerStatefulWidget {
  final String reference;
  final TicketOrderModel? initial;

  const TicketOrderScreen({super.key, required this.reference, this.initial});

  @override
  ConsumerState<TicketOrderScreen> createState() => _TicketOrderScreenState();
}

class _TicketOrderScreenState extends ConsumerState<TicketOrderScreen> {
  TicketOrderModel? _order;
  String? _error;
  Timer? _timer;
  int _polls = 0;
  static const _maxPolls = 40; // ~2 minutes at 3s

  ThemeData get _theme => Theme.of(context);
  Color get _on => _theme.colorScheme.onSurface;
  Color get _card => _theme.brightness == Brightness.dark ? const Color(0xFF1A191E) : Colors.grey[100]!;

  @override
  void initState() {
    super.initState();
    _order = widget.initial;
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final o = await ref.read(ticketingApiProvider).getOrder(widget.reference);
      if (!mounted) return;
      setState(() {
        _order = o;
        _error = null;
      });
      _schedule(o);
    } on TicketingError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      _schedule(_order);
    }
  }

  void _schedule(TicketOrderModel? o) {
    _timer?.cancel();
    if (o != null && o.isWaiting && _polls < _maxPolls) {
      _polls++;
      _timer = Timer(const Duration(seconds: 3), _load);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _order;

    return Scaffold(
      backgroundColor: _theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: _on), onPressed: () => Navigator.pop(context)),
        title: Text('Your tickets', style: TextStyle(color: _on, fontSize: 18)),
      ),
      body: o == null
          ? Center(child: _error == null ? const CircularProgressIndicator() : Text(_error!, style: TextStyle(color: _on)))
          : RefreshIndicator(
              onRefresh: () async {
                _polls = 0;
                await _load();
              },
              child: ListView(padding: const EdgeInsets.all(16), children: [
                _statusBanner(o),
                const SizedBox(height: 16),
                _summary(o),
                const SizedBox(height: 20),
                if (o.isIssued) ...[
                  Text('Show each QR code at the entrance', style: TextStyle(color: _on, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  for (final t in o.tickets) _ticketCard(t),
                ],
                const SizedBox(height: 30),
              ]),
            ),
    );
  }

  Widget _statusBanner(TicketOrderModel o) {
    final Color color;
    final IconData icon;
    if (o.isIssued) {
      color = const Color(0xFF4CAF50);
      icon = Icons.check_circle_outline;
    } else if (o.isWaiting) {
      color = const Color(0xFFFFC107);
      icon = Icons.hourglass_top;
    } else {
      color = Colors.redAccent;
      icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(o.statusLabel, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(o.message, style: TextStyle(color: _on.withOpacity(0.8), fontSize: 13, height: 1.4)),
            if (o.isWaiting && _polls >= _maxPolls)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Still working on it. You can leave this screen — we will notify you when your tickets are ready.',
                    style: TextStyle(color: _on.withOpacity(0.6), fontSize: 12)),
              ),
          ]),
        ),
        if (o.isWaiting && _polls < _maxPolls)
          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      ]),
    );
  }

  Widget _summary(TicketOrderModel o) {
    String money(double v, String c) => Utils.formatCurrency(v, currencyCode: c);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(o.eventTitle, style: TextStyle(color: _on, fontSize: 17, fontWeight: FontWeight.w600)),
        if (o.eventDate != null)
          Text('${o.eventDate}  ${(o.eventTime ?? '').length >= 5 ? o.eventTime!.substring(0, 5) : (o.eventTime ?? '')}',
              style: TextStyle(color: _on.withOpacity(0.6), fontSize: 12)),
        if (o.eventLocation != null) Text(o.eventLocation!, style: TextStyle(color: _on.withOpacity(0.6), fontSize: 12)),
        const SizedBox(height: 12),
        for (final i in o.items) _row('${i.quantity} × ${i.name}', money(i.lineTotal, o.currency)),
        Divider(color: _on.withOpacity(0.1)),
        _row('Total', o.paymentMethod == 'free' ? 'Free' : money(o.paidAmount ?? o.total, o.paidCurrency ?? o.currency), bold: true),
        if (o.refundedAmount > 0) _row('Refunded to wallet', money(o.refundedAmount, o.paidCurrency ?? o.currency)),
        const SizedBox(height: 6),
        Text('Order ${o.reference}', style: TextStyle(color: _on.withOpacity(0.4), fontSize: 11)),
      ]),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(child: Text(label, style: TextStyle(color: _on.withOpacity(0.75), fontSize: 13))),
          Text(value, style: TextStyle(color: _on, fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        ]),
      );

  Widget _ticketCard(IssuedTicketModel t) {
    final bytes = t.qrBytes;
    final statusText = switch (t.status) {
      'PAID' => t.checkinStatus == 'CHECKED_IN' ? 'Checked in' : 'Valid',
      'USED' => 'Checked in',
      'REFUNDED' || 'VOIDED' => 'Cancelled',
      _ => t.status,
    };
    final statusColor = t.isValid ? const Color(0xFF4CAF50) : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Row(children: [
          Expanded(child: Text(t.type ?? 'Ticket', style: TextStyle(color: _on, fontWeight: FontWeight.w600))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        if (t.attendeeName != null)
          Align(alignment: Alignment.centerLeft, child: Text(t.attendeeName!, style: TextStyle(color: _on.withOpacity(0.6), fontSize: 12))),
        const SizedBox(height: 12),
        Opacity(
          opacity: t.isValid ? 1 : 0.25,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: bytes != null
                ? Image.memory(bytes, width: 220, height: 220, fit: BoxFit.contain, filterQuality: FilterQuality.none)
                : const SizedBox(width: 220, height: 220, child: Center(child: Text('QR unavailable', style: TextStyle(color: Colors.black54)))),
          ),
        ),
        const SizedBox(height: 10),
        SelectableText(t.ticketNumber, style: TextStyle(color: _on, fontFamily: 'monospace', fontSize: 14, letterSpacing: 1)),
        Text('Code for manual entry', style: TextStyle(color: _on.withOpacity(0.45), fontSize: 10)),
      ]),
    );
  }
}
