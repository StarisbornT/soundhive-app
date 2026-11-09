import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/rounded_button.dart';
import '../../../lib/dashboard_provider/booking_payment_provider.dart';
import '../../../model/booking_payment_model.dart';
import '../../../model/service_model.dart';
import '../../../utils/alert_helper.dart';
import '../../../utils/app_colors.dart';

/// Module 2 — creator decides whether clients can book this service with an
/// advance + milestone payments, the largest advance they want, and a
/// suggested stage split clients start from.
class PaymentTermsScreen extends ConsumerStatefulWidget {
  final ServiceItem service;

  const PaymentTermsScreen({super.key, required this.service});

  @override
  ConsumerState<PaymentTermsScreen> createState() => _PaymentTermsScreenState();
}

class _PaymentTermsScreenState extends ConsumerState<PaymentTermsScreen> {
  static const double _platformMaxAdvance = 50; // the server enforces its own cap too
  static const int _maxStages = 4;

  late bool _enabled;
  late double _maxAdvance;
  late List<PlanStageInput> _template;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.service.allowsMilestones;
    _maxAdvance = (widget.service.maxAdvancePercent ?? 30).clamp(10, _platformMaxAdvance).toDouble();
    _template = (widget.service.milestoneTemplate?.isNotEmpty ?? false)
        ? widget.service.milestoneTemplate!.map((s) => PlanStageInput(title: s.title, percentage: s.percentage)).toList()
        : [
            PlanStageInput(title: 'Advance payment', percentage: 30),
            PlanStageInput(title: 'Milestone 2', percentage: 30),
            PlanStageInput(title: 'Milestone 3', percentage: 20),
            PlanStageInput(title: 'Final delivery', percentage: 20),
          ];
  }

  double get _sum => _template.fold(0.0, (a, s) => a + s.percentage);

  String? get _error {
    if (!_enabled) return null;
    if (_template.length < 2) return 'Use at least 2 stages.';
    if (_template.any((s) => s.percentage < 10)) return 'Each stage must be at least 10%.';
    if (_template.first.percentage > _maxAdvance) return 'The advance in your template is above your ${_maxAdvance.toInt()}% limit.';
    if ((_sum - 100).abs() > 0.01) return 'Stages add up to ${_sum.toStringAsFixed(0)}% — they must total 100%.';
    return null;
  }

  Future<void> _save() async {
    if (_error != null) return;
    setState(() => _saving = true);
    try {
      await ref.read(bookingPaymentApiProvider).updatePaymentTerms(
            serviceId: widget.service.id,
            allowsMilestones: _enabled,
            maxAdvancePercent: _enabled ? _maxAdvance : null,
            template: _enabled ? _template : null,
          );
      if (!mounted) return;
      showCustomAlert(context: context, isSuccess: true, title: 'Saved', message: 'Payment terms updated for this service.');
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
    final card = isDark ? const Color(0xFF1A191E) : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: on), onPressed: () => Navigator.pop(context)),
        title: Text('Payment terms', style: TextStyle(color: on, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.service.serviceName, style: TextStyle(color: on, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              value: _enabled,
              activeColor: AppColors.BUTTONCOLOR,
              title: Text('Accept advance + milestone payments', style: TextStyle(color: on, fontSize: 14)),
              subtitle: Text(
                'Clients can pay an advance that goes straight to your wallet, then pay the rest in stages they approve.',
                style: TextStyle(color: on.withOpacity(0.6), fontSize: 12),
              ),
              onChanged: (v) => setState(() => _enabled = v),
            ),
          ),
          if (_enabled) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Largest advance you accept', style: TextStyle(color: on, fontSize: 14)),
                  const Spacer(),
                  Text('${_maxAdvance.toInt()}%', style: TextStyle(color: on, fontWeight: FontWeight.w700)),
                ]),
                Slider(
                  value: _maxAdvance,
                  min: 10,
                  max: _platformMaxAdvance,
                  divisions: ((_platformMaxAdvance - 10) / 5).round(),
                  activeColor: AppColors.BUTTONCOLOR,
                  onChanged: (v) => setState(() => _maxAdvance = v),
                ),
                Text('Platform limit is ${_platformMaxAdvance.toInt()}%.',
                    style: TextStyle(color: on.withOpacity(0.5), fontSize: 11)),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Suggested stages', style: TextStyle(color: on, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Clients start from this split and can adjust it within your limits.',
                    style: TextStyle(color: on.withOpacity(0.55), fontSize: 11)),
                const SizedBox(height: 12),
                for (var i = 0; i < _template.length; i++) _stageRow(i, on),
                Row(children: [
                  if (_template.length < _maxStages)
                    TextButton.icon(
                      onPressed: () => setState(() => _template.insert(_template.length - 1, PlanStageInput(title: 'Milestone ${_template.length}', percentage: 10))),
                      icon: const Icon(Icons.add, size: 18, color: AppColors.BUTTONCOLOR),
                      label: const Text('Add stage', style: TextStyle(color: AppColors.BUTTONCOLOR)),
                    ),
                  const Spacer(),
                  Text('${_sum.toStringAsFixed(0)}% / 100%',
                      style: TextStyle(color: (_sum - 100).abs() <= 0.01 ? Colors.green : Colors.orange, fontSize: 12)),
                ]),
                if (_error != null) Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ]),
            ),
          ],
          const SizedBox(height: 28),
          RoundedButton(
            title: _saving ? 'Saving…' : 'Save payment terms',
            color: _error == null ? AppColors.BUTTONCOLOR : AppColors.INACTIVEBUTTONCOLOR,
            borderWidth: 0,
            borderRadius: 25,
            onPressed: (_saving || _error != null) ? null : _save,
          ),
        ],
      ),
    );
  }

  Widget _stageRow(int i, Color on) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Expanded(
          child: TextFormField(
            key: ValueKey('t$i${_template.length}'),
            initialValue: _template[i].title,
            style: TextStyle(color: on, fontSize: 13),
            decoration: InputDecoration(isDense: true, labelText: i == 0 ? 'Advance' : 'Stage ${i + 1}'),
            onChanged: (v) => _template[i].title = v,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: TextFormField(
            key: ValueKey('p$i${_template.length}'),
            initialValue: _template[i].percentage.toStringAsFixed(0),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: TextStyle(color: on, fontSize: 13),
            decoration: const InputDecoration(isDense: true, suffixText: '%'),
            onChanged: (v) => setState(() => _template[i].percentage = double.tryParse(v) ?? 0),
          ),
        ),
        SizedBox(
          width: 36,
          child: (i == 0 || _template.length <= 2)
              ? const SizedBox.shrink()
              : IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.close, size: 18, color: on.withOpacity(0.5)),
                  onPressed: () => setState(() => _template.removeAt(i)),
                ),
        ),
      ]),
    );
  }
}
