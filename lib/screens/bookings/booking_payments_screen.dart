import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../components/rounded_button.dart';
import '../../lib/dashboard_provider/booking_payment_provider.dart';
import '../../lib/dashboard_provider/user_provider.dart';
import '../../model/booking_payment_model.dart';
import '../../utils/alert_helper.dart';
import '../../utils/app_colors.dart';
import '../../utils/utils.dart';

/// Module 2 — payment schedule for one booking.
/// The same screen serves the client and the creator; the server says which
/// one is looking (viewer_role) and what they can do next.
class BookingPaymentsScreen extends ConsumerStatefulWidget {
  final int bookingId;
  final String? serviceName;

  const BookingPaymentsScreen({super.key, required this.bookingId, this.serviceName});

  @override
  ConsumerState<BookingPaymentsScreen> createState() => _BookingPaymentsScreenState();
}

class _BookingPaymentsScreenState extends ConsumerState<BookingPaymentsScreen> {
  bool _busy = false;

  ThemeData get _theme => Theme.of(context);
  bool get _isDark => _theme.brightness == Brightness.dark;
  Color get _onSurface => _theme.colorScheme.onSurface;
  Color get _card => _isDark ? const Color(0xFF1A191E) : Colors.grey[100]!;

  void _refresh() => ref.invalidate(bookingPaymentSummaryProvider(widget.bookingId));

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(bookingPaymentSummaryProvider(widget.bookingId));

    return Scaffold(
      backgroundColor: _theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: _onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Payment schedule', style: TextStyle(color: _onSurface, fontSize: 18)),
      ),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _errorView(e.toString()),
        data: (s) => RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: s.legacy ? _legacyView(s) : _planView(s),
        ),
      ),
    );
  }

  // ── views ────────────────────────────────────────────────────────────

  Widget _errorView(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: _onSurface.withOpacity(0.7))),
            const SizedBox(height: 16),
            TextButton(onPressed: _refresh, child: const Text('Try again')),
          ]),
        ),
      );

  Widget _legacyView(BookingPaymentSummary s) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _box(Text(
            s.legacyMessage ?? 'This booking uses full escrow. Payment is released when the job is marked complete.',
            style: TextStyle(color: _onSurface.withOpacity(0.8), height: 1.5),
          )),
        ],
      );

  Widget _planView(BookingPaymentSummary s) {
    final money = (double v) => Utils.formatCurrency(v, currencyCode: s.currency);
    final creatorMoney = (double v) => Utils.formatCurrency(v, currencyCode: s.escrowCurrency);
    final progress = s.stagesTotal == 0 ? 0.0 : s.stagesReleased / s.stagesTotal;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        _box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(widget.serviceName ?? 'Booking #${s.bookingId}',
                  style: TextStyle(color: _onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            _chip(_planStatusLabel(s), _planStatusColor(s)),
          ]),
          const SizedBox(height: 6),
          Text(
            s.isMilestonePlan
                ? '${s.stagesTotal}-stage milestone plan${s.fundingMode == 'ADVANCE_ONLY' ? ' · pay as you go' : ' · paid upfront'}'
                : 'Full escrow payment',
            style: TextStyle(color: _onSurface.withOpacity(0.6), fontSize: 12),
          ),
          const SizedBox(height: 14),
          Text('Agreed fee', style: TextStyle(color: _onSurface.withOpacity(0.6), fontSize: 12)),
          Text(money(s.totalAmount), style: TextStyle(color: _onSurface, fontSize: 24, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: _onSurface.withOpacity(0.08),
              color: AppColors.BUTTONCOLOR,
            ),
          ),
          const SizedBox(height: 6),
          Text('${s.stagesReleased} of ${s.stagesTotal} stages paid out',
              style: TextStyle(color: _onSurface.withOpacity(0.6), fontSize: 11)),
        ])),
        const SizedBox(height: 12),

        // Totals
        _box(Column(children: s.isCreator
            ? [
                _row('Received in your wallet', creatorMoney(s.receivedInWallet), bold: true),
                _row('Platform commission', creatorMoney(s.commissionDeducted)),
                _row('Held in escrow', creatorMoney(s.heldInEscrow)),
                _row('Not yet paid by client', creatorMoney(s.notYetFunded)),
              ]
            : [
                _row('Paid so far', money(s.paid), bold: true),
                _row('Released to creator', money(s.released)),
                _row('Held in escrow', money(s.inEscrow)),
                _row('Still to pay', money(s.outstanding)),
                if (s.refunded > 0) _row('Refunded to you', money(s.refunded)),
              ])),
        const SizedBox(height: 8),
        Text(
          s.isCreator
              ? 'Escrowed money is released to your wallet when the client approves each stage. It cannot be withdrawn before then.'
              : 'Money in escrow is only released to the creator when you approve each stage.',
          style: TextStyle(color: _onSurface.withOpacity(0.5), fontSize: 11, height: 1.4),
        ),
        const SizedBox(height: 16),

        if (s.nextAction != null) ...[
          _nextActionBanner(s),
          const SizedBox(height: 16),
        ],

        Text('Stages', style: TextStyle(color: _onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        for (final m in s.milestones) _milestoneTile(s, m),

        if (s.canCancel) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : () => _cancel(s),
            child: const Text('Cancel booking', style: TextStyle(color: Colors.redAccent)),
          ),
          Text(
            'Cancelling returns money still in escrow to the client. Payments already released, including the advance, stay with the creator unless a dispute is decided otherwise.',
            style: TextStyle(color: _onSurface.withOpacity(0.5), fontSize: 11, height: 1.4),
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _nextActionBanner(BookingPaymentSummary s) {
    final a = s.nextAction!;
    Milestone? m;
    for (final x in s.milestones) {
      if (x.id == a.milestoneId) m = x;
    }
    final target = m;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.BUTTONCOLOR.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.BUTTONCOLOR.withOpacity(0.35)),
      ),
      child: Row(children: [
        const Icon(Icons.flag_outlined, color: AppColors.BUTTONCOLOR, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(a.label, style: TextStyle(color: _onSurface, fontSize: 13))),
        if (target != null && _actionFor(s, target) != null) ...[
          const SizedBox(width: 8),
          _actionButton(s, target),
        ],
      ]),
    );
  }

  Widget _milestoneTile(BookingPaymentSummary s, Milestone m) {
    final money = Utils.formatCurrency(s.isCreator ? m.escrowAmount : m.amount,
        currencyCode: s.isCreator ? s.escrowCurrency : s.currency);
    final action = _actionFor(s, m);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: m.isAdvance ? AppColors.BUTTONCOLOR : _onSurface.withOpacity(0.12),
            child: Text('${m.sequence}', style: TextStyle(color: m.isAdvance ? Colors.white : _onSurface, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.title, style: TextStyle(color: _onSurface, fontWeight: FontWeight.w600)),
              Text('${_pct(m.percentage)}% · $money${m.isAdvance ? ' · advance' : ''}',
                  style: TextStyle(color: _onSurface.withOpacity(0.6), fontSize: 12)),
            ]),
          ),
          _chip(_statusLabel(m.status), _statusColor(m.status)),
        ]),
        if (_detailLine(s, m) != null) ...[
          const SizedBox(height: 8),
          Text(_detailLine(s, m)!, style: TextStyle(color: _onSurface.withOpacity(0.55), fontSize: 11, height: 1.4)),
        ],
        if (m.submissionNote != null && m.submissionNote!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Creator\'s note: ${m.submissionNote}',
              style: TextStyle(color: _onSurface.withOpacity(0.75), fontSize: 12, fontStyle: FontStyle.italic)),
        ],
        if (action != null) ...[
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerRight, child: _actionButton(s, m)),
        ],
      ]),
    );
  }

  String? _detailLine(BookingPaymentSummary s, Milestone m) {
    final parts = <String>[];
    if (m.fundedAt != null) parts.add('Paid ${_date(m.fundedAt)}');
    if (m.submittedAt != null) parts.add('Delivered ${_date(m.submittedAt)}');
    if (m.releasedAt != null) {
      parts.add(s.isCreator && m.netAmount != null
          ? 'Released ${_date(m.releasedAt)} · ${Utils.formatCurrency(m.netAmount, currencyCode: s.escrowCurrency)} to your wallet'
          : 'Released ${_date(m.releasedAt)}');
    }
    if (m.refundedAt != null) parts.add('Refunded ${_date(m.refundedAt)}');
    if (m.status == 'UNFUNDED' && s.isCustomer && m.amountToPay != null) {
      parts.add('To pay: ${Utils.formatCurrency(m.amountToPay, currencyCode: s.userCurrency)}');
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  // ── actions ──────────────────────────────────────────────────────────

  /// fund / approve / submit — only for the next open stage, and only when the plan is active.
  String? _actionFor(BookingPaymentSummary s, Milestone m) {
    if (!s.isActive || s.status != 'PENDING') return null;
    final next = s.nextAction;
    if (next == null || next.milestoneId != m.id) return null;
    if (s.isCustomer && m.status == 'UNFUNDED') return 'fund';
    if (s.isCustomer && m.isInEscrow) return 'approve';
    if (s.isCreator && m.status == 'FUNDED') return 'submit';
    return null;
  }

  Widget _actionButton(BookingPaymentSummary s, Milestone m) {
    final action = _actionFor(s, m)!;
    final label = {'fund': 'Pay now', 'approve': 'Approve & release', 'submit': 'Mark delivered'}[action]!;

    return SizedBox(
      height: 36,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.BUTTONCOLOR,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: _busy
            ? null
            : () => switch (action) {
                  'fund' => _fund(s, m),
                  'approve' => _approve(s, m),
                  _ => _submit(s, m),
                },
        child: _busy
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  Future<void> _fund(BookingPaymentSummary s, Milestone m) async {
    final amount = Utils.formatCurrency(m.amountToPay ?? m.amount, currencyCode: s.userCurrency);
    final ok = await _confirm(
      'Pay "${m.title}"?',
      '$amount will be taken from your wallet and held in escrow. The creator is paid when you approve this stage.',
      'Pay $amount',
    );
    if (ok) await _run(() => ref.read(bookingPaymentApiProvider).fundMilestone(s.bookingId, m.id), 'Payment received and held in escrow.');
  }

  Future<void> _approve(BookingPaymentSummary s, Milestone m) async {
    final ok = await _confirm(
      'Approve "${m.title}"?',
      'Only approve if this stage has been delivered to your satisfaction. ${Utils.formatCurrency(m.amount, currencyCode: s.currency)} will be released to the creator. This cannot be undone.',
      'Approve & release',
    );
    if (ok) await _run(() => ref.read(bookingPaymentApiProvider).approveMilestone(s.bookingId, m.id), 'Payment released to the creator.');
  }

  Future<void> _submit(BookingPaymentSummary s, Milestone m) async {
    final note = await _textPrompt('Mark "${m.title}" as delivered', 'Add a short note for the client (optional)', required: false);
    if (note == null) return;
    await _run(() => ref.read(bookingPaymentApiProvider).submitMilestone(s.bookingId, m.id, note: note),
        'The client has been asked to review and approve.');
  }

  Future<void> _cancel(BookingPaymentSummary s) async {
    final reason = await _textPrompt('Cancel this booking?', 'Reason for cancelling', required: true, confirmLabel: 'Cancel booking');
    if (reason == null) return;
    await _run(() => ref.read(bookingPaymentApiProvider).cancelBooking(s.bookingId, reason), 'Booking cancelled. Escrowed funds have been returned to the client.');
  }

  Future<void> _run(Future<BookingPaymentSummary> Function() call, String successMessage) async {
    setState(() => _busy = true);
    try {
      await call();
      _refresh();
      // Wallet balance changed — reload it.
      try {
        await ref.read(userProvider.notifier).loadUserProfile();
      } catch (_) {}
      if (mounted) showCustomAlert(context: context, isSuccess: true, title: 'Done', message: successMessage);
    } on BookingPaymentError catch (e) {
      if (!mounted) return;
      showCustomAlert(
        context: context,
        isSuccess: false,
        title: e.insufficientFunds ? 'Insufficient funds' : 'Could not complete',
        message: e.insufficientFunds ? 'Your wallet balance is too low. Fund your wallet and try again.' : e.message,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── dialogs ──────────────────────────────────────────────────────────

  Future<bool> _confirm(String title, String body, String confirmLabel) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: _theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: _onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(body, style: TextStyle(color: _onSurface.withOpacity(0.7), height: 1.5)),
          const SizedBox(height: 20),
          RoundedButton(
            title: confirmLabel,
            color: AppColors.BUTTONCOLOR,
            borderWidth: 0,
            borderRadius: 25,
            onPressed: () => Navigator.pop(ctx, true),
          ),
          const SizedBox(height: 8),
          Center(child: TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now'))),
        ]),
      ),
    );
    return result == true;
  }

  Future<String?> _textPrompt(String title, String hint, {required bool required, String confirmLabel = 'Submit'}) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _theme.colorScheme.surface,
        title: Text(title, style: TextStyle(color: _onSurface, fontSize: 17)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: required ? 500 : 1000,
          style: TextStyle(color: _onSurface),
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back')),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (required && text.isEmpty) return;
              Navigator.pop(ctx, text);
            },
            child: Text(confirmLabel, style: const TextStyle(color: AppColors.BUTTONCOLOR)),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  // ── small UI helpers ─────────────────────────────────────────────────

  Widget _box(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
        child: child,
      );

  Widget _row(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Text(label, style: TextStyle(color: _onSurface.withOpacity(bold ? 0.9 : 0.65), fontSize: 13)),
          const Spacer(),
          Text(value, style: TextStyle(color: _onSurface, fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        ]),
      );

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
        child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      );

  String _pct(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  String _date(String? iso) {
    final d = iso == null ? null : DateTime.tryParse(iso);
    return d == null ? '' : DateFormat('d MMM yyyy').format(d.toLocal());
  }

  String _statusLabel(String s) => const {
        'UNFUNDED': 'Not paid',
        'FUNDED': 'In escrow',
        'SUBMITTED': 'Awaiting approval',
        'RELEASED': 'Paid out',
        'REFUNDED': 'Refunded',
        'CANCELLED': 'Cancelled',
      }[s] ??
      s;

  Color _statusColor(String s) => switch (s) {
        'RELEASED' => const Color(0xFF4CAF50),
        'FUNDED' => const Color(0xFF2196F3),
        'SUBMITTED' => const Color(0xFFFFC107),
        'REFUNDED' || 'CANCELLED' => Colors.grey,
        _ => const Color(0xFFFF9800),
      };

  String _planStatusLabel(BookingPaymentSummary s) => switch (s.planStatus) {
        'DISPUTED' => 'On hold',
        'COMPLETED' => 'Completed',
        'CANCELLED' => 'Cancelled',
        _ => 'Ongoing',
      };

  Color _planStatusColor(BookingPaymentSummary s) => switch (s.planStatus) {
        'DISPUTED' => Colors.redAccent,
        'COMPLETED' => const Color(0xFF4CAF50),
        'CANCELLED' => Colors.grey,
        _ => const Color(0xFFFFC107),
      };
}
