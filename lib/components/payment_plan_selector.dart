import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../lib/dashboard_provider/booking_payment_provider.dart';
import '../model/booking_payment_model.dart';
import '../utils/app_colors.dart';
import '../utils/utils.dart';

/// Module 2 — lets the client choose how to pay for a booking:
///   1. Full escrow (default)
///   2. Advance + milestones (only if the creator enabled it on the service)
///
/// Reports the chosen plan, whether it is valid, and the server's exact
/// breakdown, through [onChanged].
class PaymentPlanSelector extends ConsumerStatefulWidget {
  final int serviceId;
  final bool allowsMilestones;
  final double? creatorAdvanceCap;
  final List<PlanStageInput>? template;
  final ThemeData theme;
  final bool isDark;
  final void Function(PaymentPlanRequest plan, bool isValid, PaymentQuote? quote) onChanged;

  const PaymentPlanSelector({
    super.key,
    required this.serviceId,
    required this.allowsMilestones,
    required this.onChanged,
    required this.theme,
    required this.isDark,
    this.creatorAdvanceCap,
    this.template,
  });

  @override
  ConsumerState<PaymentPlanSelector> createState() => _PaymentPlanSelectorState();
}

class _PaymentPlanSelectorState extends ConsumerState<PaymentPlanSelector> {
  bool _milestone = false;
  bool _advanceOnly = false;
  late List<PlanStageInput> _stages;
  final List<TextEditingController> _titleCtrls = [];
  final List<TextEditingController> _pctCtrls = [];

  PaymentQuote? _quote;
  PlanRules? _rules;
  bool _loading = false;
  String? _serverError;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _stages = (widget.template != null && widget.template!.length >= 2)
        ? widget.template!.map((s) => PlanStageInput(title: s.title, percentage: s.percentage)).toList()
        : [
            PlanStageInput(title: 'Advance payment', percentage: 30),
            PlanStageInput(title: 'Milestone 2', percentage: 30),
            PlanStageInput(title: 'Milestone 3', percentage: 20),
            PlanStageInput(title: 'Final delivery', percentage: 20),
          ];
    _syncControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _changed());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [..._titleCtrls, ..._pctCtrls]) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncControllers() {
    for (final c in [..._titleCtrls, ..._pctCtrls]) {
      c.dispose();
    }
    _titleCtrls
      ..clear()
      ..addAll(_stages.map((s) => TextEditingController(text: s.title)));
    _pctCtrls
      ..clear()
      ..addAll(_stages.map((s) => TextEditingController(text: _fmtPct(s.percentage))));
  }

  String _fmtPct(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  // ── rules ────────────────────────────────────────────────────────────

  int get _maxStages => _rules?.maxStages ?? 4;
  double get _minStage => _rules?.minStagePercent ?? 10;
  double get _advanceCap {
    final platform = _rules?.maxAdvancePercent ?? 50;
    final creator = widget.creatorAdvanceCap;
    return creator == null ? platform : (creator < platform ? creator : platform);
  }

  double get _sum => _stages.fold(0.0, (a, s) => a + s.percentage);

  /// The creator set a stage split: clients book with exactly that split.
  bool get _locked => widget.template != null && widget.template!.length >= 2;

  String? get _localError {
    if (!_milestone) return null;
    if (_stages.length < 2 || _stages.length > _maxStages) return 'Use between 2 and $_maxStages stages.';
    if (_stages.any((s) => s.percentage < _minStage)) return 'Each stage must be at least ${_fmtPct(_minStage)}%.';
    if (_stages.first.percentage > _advanceCap) return 'The advance can be at most ${_fmtPct(_advanceCap)}%.';
    if ((_sum - 100).abs() > 0.01) return 'Stages add up to ${_fmtPct(_sum)}% — they must total 100%.';
    return null;
  }

  PaymentPlanRequest get _plan => _milestone
      ? PaymentPlanRequest(isMilestone: true, payAdvanceOnly: _advanceOnly, stages: _stages)
      : const PaymentPlanRequest.fullEscrow();

  // ── changes & preview ────────────────────────────────────────────────

  void _changed() {
    final error = _localError;
    widget.onChanged(_plan, error == null && _serverError == null, error == null ? _quote : null);

    _debounce?.cancel();
    if (error != null) {
      setState(() => _quote = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), _fetchPreview);
  }

  Future<void> _fetchPreview() async {
    final plan = _plan;
    setState(() {
      _loading = true;
      _serverError = null;
    });
    try {
      final quote = await ref.read(bookingPaymentApiProvider).preview(serviceId: widget.serviceId, plan: plan);
      if (!mounted) return;
      setState(() {
        _quote = quote;
        _rules = quote.rules;
        _loading = false;
      });
      widget.onChanged(plan, _localError == null, quote);
    } on BookingPaymentError catch (e) {
      if (!mounted) return;
      setState(() {
        _quote = null;
        _serverError = e.message;
        _loading = false;
      });
      widget.onChanged(plan, false, null);
    }
  }

  void _setMode(bool milestone) {
    if (_milestone == milestone) return;
    setState(() {
      _milestone = milestone;
      _serverError = null;
    });
    _changed();
  }

  void _addStage() {
    if (_stages.length >= _maxStages) return;
    setState(() {
      _stages.insert(_stages.length - 1, PlanStageInput(title: 'Milestone ${_stages.length}', percentage: _minStage));
      _syncControllers();
    });
    _changed();
  }

  void _removeStage(int i) {
    if (_stages.length <= 2 || i == 0) return;
    setState(() {
      _stages.removeAt(i);
      _syncControllers();
    });
    _changed();
  }

  // ── UI ───────────────────────────────────────────────────────────────

  Color get _surface => widget.isDark ? const Color(0xFF1A191E) : Colors.grey[100]!;
  Color get _onSurface => widget.theme.colorScheme.onSurface;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment arrangement',
            style: TextStyle(color: _onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _optionCard(
          selected: !_milestone,
          title: 'Full escrow payment',
          subtitle: 'Pay the full fee now. It is held safely and released to the creator when you mark the job complete.',
          onTap: () => _setMode(false),
        ),
        if (widget.allowsMilestones) ...[
          const SizedBox(height: 10),
          _optionCard(
            selected: _milestone,
            title: 'Advance + milestones',
            subtitle: 'Pay an advance straight to the creator to start the work. The rest is paid in up to $_maxStages stages you approve one by one.',
            onTap: () => _setMode(true),
          ),
        ],
        if (_milestone) ...[
          const SizedBox(height: 16),
          _stageEditor(),
          const SizedBox(height: 12),
          _fundingToggle(),
        ],
        const SizedBox(height: 16),
        _breakdown(),
      ],
    );
  }

  Widget _optionCard({required bool selected, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.BUTTONCOLOR : Colors.transparent, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.BUTTONCOLOR : _onSurface.withOpacity(0.4), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: _onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: _onSurface.withOpacity(0.65), fontSize: 12, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stageEditor() {
    final error = _localError ?? _serverError;

    if (_locked) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Creator's payment stages", style: TextStyle(color: _onSurface, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Set by the creator for this service.',
                style: TextStyle(color: _onSurface.withOpacity(0.55), fontSize: 11)),
            const SizedBox(height: 10),
            for (var i = 0; i < _stages.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == 0 ? AppColors.BUTTONCOLOR : _onSurface.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Text('${i + 1}', style: TextStyle(color: i == 0 ? Colors.white : _onSurface, fontSize: 11)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(i == 0 ? '${_stages[i].title} (advance)' : _stages[i].title,
                        style: TextStyle(color: _onSurface, fontSize: 13)),
                  ),
                  Text('${_fmtPct(_stages[i].percentage)}%',
                      style: TextStyle(color: _onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            if (error != null) ...[
              const SizedBox(height: 4),
              Text(error, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Payment stages', style: TextStyle(color: _onSurface, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${_fmtPct(_sum)}% of 100%',
                  style: TextStyle(
                    color: (_sum - 100).abs() <= 0.01 ? Colors.green : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < _stages.length; i++) _stageRow(i),
          if (_stages.length < _maxStages)
            TextButton.icon(
              onPressed: _addStage,
              icon: const Icon(Icons.add, size: 18, color: AppColors.BUTTONCOLOR),
              label: const Text('Add a stage', style: TextStyle(color: AppColors.BUTTONCOLOR)),
            ),
          Text(
            'Stage 1 is the advance (max ${_fmtPct(_advanceCap)}%) and goes straight to the creator. '
            'Each stage must be at least ${_fmtPct(_minStage)}%.',
            style: TextStyle(color: _onSurface.withOpacity(0.55), fontSize: 11, height: 1.4),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _stageRow(int i) {
    final isAdvance = i == 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isAdvance ? AppColors.BUTTONCOLOR : _onSurface.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Text('${i + 1}', style: TextStyle(color: isAdvance ? Colors.white : _onSurface, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _titleCtrls[i],
              style: TextStyle(color: _onSurface, fontSize: 13),
              decoration: _input(isAdvance ? 'Advance' : 'Stage title'),
              onChanged: (v) {
                _stages[i].title = v;
                _changed();
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: TextField(
              controller: _pctCtrls[i],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?'))],
              textAlign: TextAlign.center,
              style: TextStyle(color: _onSurface, fontSize: 13),
              decoration: _input('%').copyWith(suffixText: '%'),
              onChanged: (v) {
                _stages[i].percentage = double.tryParse(v) ?? 0;
                setState(() {});
                _changed();
              },
            ),
          ),
          SizedBox(
            width: 36,
            child: (i == 0 || _stages.length <= 2)
                ? const SizedBox.shrink()
                : IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.close, size: 18, color: _onSurface.withOpacity(0.5)),
                    onPressed: () => _removeStage(i),
                  ),
          ),
        ],
      ),
    );
  }

  InputDecoration _input(String hint) => InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(color: _onSurface.withOpacity(0.35), fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _onSurface.withOpacity(0.15))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _onSurface.withOpacity(0.15))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.BUTTONCOLOR)),
      );

  Widget _fundingToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          RadioListTile<bool>(
            value: false,
            groupValue: _advanceOnly,
            activeColor: AppColors.BUTTONCOLOR,
            dense: true,
            title: Text('Pay everything now', style: TextStyle(color: _onSurface, fontSize: 13)),
            subtitle: Text('Advance to the creator, the rest held in escrow until you approve each stage.',
                style: TextStyle(color: _onSurface.withOpacity(0.6), fontSize: 11)),
            onChanged: (v) {
              setState(() => _advanceOnly = false);
              _changed();
            },
          ),
          RadioListTile<bool>(
            value: true,
            groupValue: _advanceOnly,
            activeColor: AppColors.BUTTONCOLOR,
            dense: true,
            title: Text('Pay the advance now, the rest later', style: TextStyle(color: _onSurface, fontSize: 13)),
            subtitle: Text('Pay each later stage from your wallet before the creator starts it.',
                style: TextStyle(color: _onSurface.withOpacity(0.6), fontSize: 11)),
            onChanged: (v) {
              setState(() => _advanceOnly = true);
              _changed();
            },
          ),
        ],
      ),
    );
  }

  Widget _breakdown() {
    if (_loading && _quote == null) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    final q = _quote;
    if (q == null) return const SizedBox.shrink();

    String money(double v) => Utils.formatCurrency(v, currencyCode: q.userCurrency);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment breakdown', style: TextStyle(color: _onSurface, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          for (final s in q.stages)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${s.title} · ${_fmtPct(s.percentage)}%', style: TextStyle(color: _onSurface, fontSize: 13)),
                        Text(
                          s.isAdvance
                              ? 'Paid now, straight to the creator'
                              : (s.paidNow ? 'Paid now, held in escrow' : 'Pay later, before this stage starts'),
                          style: TextStyle(color: _onSurface.withOpacity(0.55), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Text(money(s.userAmount), style: TextStyle(color: _onSurface, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          Divider(color: _onSurface.withOpacity(0.1)),
          _totalRow('Total', money(q.userTotal)),
          _totalRow('Due now', money(q.dueNow), bold: true),
          if (q.payLater > 0) _totalRow('Pay later', money(q.payLater)),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: _onSurface.withOpacity(bold ? 1 : 0.7), fontSize: 13, fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
            const Spacer(),
            Text(value, style: TextStyle(color: _onSurface, fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      );
}
