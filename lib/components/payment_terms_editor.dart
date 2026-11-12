import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/booking_payment_model.dart';
import '../utils/app_colors.dart';

/// Module 2 — the creator's payment terms for one service.
///
/// Used in three places: Add service (step 3), Edit service (step 3) and the
/// Payment terms screen. Clients book with exactly this split; they only
/// choose whether to pay everything now or the advance now and the rest later.
class PaymentTerms {
  bool enabled;
  List<PlanStageInput> stages;

  PaymentTerms({required this.enabled, required this.stages});

  static const double platformMaxAdvance = 50;
  static const double minStage = 10;
  static const int maxStages = 4;

  factory PaymentTerms.defaults() => PaymentTerms(enabled: false, stages: defaultStages());

  static List<PlanStageInput> defaultStages() => [
        PlanStageInput(title: 'Advance payment', percentage: 30),
        PlanStageInput(title: 'First draft', percentage: 30),
        PlanStageInput(title: 'Revisions', percentage: 20),
        PlanStageInput(title: 'Final delivery', percentage: 20),
      ];

  /// From a service as loaded from the API.
  factory PaymentTerms.fromService({required bool allowsMilestones, List<PlanStageInput>? template}) {
    final stages = (template != null && template.length >= 2)
        ? template.map((s) => PlanStageInput(title: s.title, percentage: s.percentage)).toList()
        : defaultStages();
    return PaymentTerms(enabled: allowsMilestones, stages: stages);
  }

  double get advance => stages.isEmpty ? 0 : stages.first.percentage;
  double get sum => stages.fold(0.0, (a, s) => a + s.percentage);

  String? get error {
    if (!enabled) return null;
    if (stages.length < 2) return 'Add at least one stage after the advance.';
    if (stages.length > maxStages) return 'Use at most $maxStages stages.';
    if (stages.any((s) => s.title.trim().isEmpty)) return 'Give every stage a name.';
    if (stages.any((s) => s.percentage < minStage)) return 'Each stage must be at least ${minStage.toInt()}%.';
    if (advance > platformMaxAdvance) return 'The advance can be at most ${platformMaxAdvance.toInt()}%.';
    if ((sum - 100).abs() > 0.01) return 'Stages add up to ${_fmt(sum)}%. They must total 100%.';
    return null;
  }

  bool get isValid => error == null;

  /// Fields for POST /create-service, PUT /services/{id} and PUT /services/{id}/payment-terms.
  Map<String, dynamic> toPayload() => enabled
      ? {
          'allows_milestones': true,
          'max_advance_percent': advance,
          'milestone_template': stages.map((s) => {'title': s.title.trim(), 'percentage': s.percentage}).toList(),
        }
      : {'allows_milestones': false};

  /// One-line summary, e.g. "30% advance + 3 stages" or "Full payment into escrow".
  String get summary {
    if (!enabled) return 'Full payment into escrow only';
    final rest = stages.length - 1;
    return '${_fmt(advance)}% advance + $rest more stage${rest == 1 ? '' : 's'}';
  }

  static String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

class PaymentTermsEditor extends StatefulWidget {
  final PaymentTerms terms;
  final ValueChanged<PaymentTerms> onChanged;

  /// Optional price, so the creator sees what each stage is worth.
  final double? price;
  final String Function(double amount)? formatMoney;
  final bool isDark;

  const PaymentTermsEditor({
    super.key,
    required this.terms,
    required this.onChanged,
    this.price,
    this.formatMoney,
    this.isDark = true,
  });

  @override
  State<PaymentTermsEditor> createState() => _PaymentTermsEditorState();
}

class _PaymentTermsEditorState extends State<PaymentTermsEditor> {
  final List<TextEditingController> _titles = [];
  final List<TextEditingController> _pcts = [];

  PaymentTerms get t => widget.terms;

  @override
  void initState() {
    super.initState();
    _rebuildControllers();
  }

  @override
  void didUpdateWidget(covariant PaymentTermsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.terms, widget.terms)) _rebuildControllers();
  }

  @override
  void dispose() {
    for (final c in [..._titles, ..._pcts]) {
      c.dispose();
    }
    super.dispose();
  }

  void _rebuildControllers() {
    // Dispose the old controllers after the frame: the fields still hold them until then.
    final old = [..._titles, ..._pcts];
    if (old.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final c in old) {
          c.dispose();
        }
      });
    }
    _titles
      ..clear()
      ..addAll(t.stages.map((s) => TextEditingController(text: s.title)));
    _pcts
      ..clear()
      ..addAll(t.stages.map((s) => TextEditingController(text: PaymentTerms._fmt(s.percentage))));
  }

  /// Puts the stage percentages back into the % fields after a programmatic change.
  void _refreshPercentFields() {
    for (var i = 0; i < t.stages.length; i++) {
      final text = PaymentTerms._fmt(t.stages[i].percentage);
      if (_pcts[i].text != text) _pcts[i].text = text;
    }
  }

  void _emit() {
    setState(() {});
    widget.onChanged(t);
  }

  /// Slider: sets the advance and shares what is left across the other
  /// stages in their current proportions (whole percentages, each ≥ 10%).
  void _setAdvance(double advance) {
    advance = advance.roundToDouble();
    final others = t.stages.skip(1).toList();
    final remaining = 100 - advance;
    final weight = others.fold(0.0, (a, s) => a + (s.percentage > 0 ? s.percentage : 1));

    final shares = others.map((s) => ((s.percentage > 0 ? s.percentage : 1) / weight * remaining).floorToDouble()).toList();
    if (shares.isNotEmpty) shares[shares.length - 1] += remaining - shares.fold(0.0, (a, b) => a + b);

    if (shares.any((v) => v < PaymentTerms.minStage)) {
      // fall back to an even split
      final even = (remaining / others.length).floorToDouble();
      for (var i = 0; i < shares.length; i++) {
        shares[i] = even;
      }
      shares[shares.length - 1] += remaining - even * others.length;
    }

    t.stages.first.percentage = advance;
    for (var i = 0; i < others.length; i++) {
      others[i].percentage = shares[i];
    }
    _refreshPercentFields();
    _emit();
  }

  void _addStage() {
    if (t.stages.length >= PaymentTerms.maxStages) return;
    t.stages.insert(t.stages.length - 1, PlanStageInput(title: 'Stage ${t.stages.length}', percentage: PaymentTerms.minStage));
    _rebuildControllers();
    _setAdvance(t.advance); // rebalance so the total stays 100%
  }

  void _removeStage(int i) {
    if (i == 0 || t.stages.length <= 2) return;
    t.stages.removeAt(i);
    _rebuildControllers();
    _setAdvance(t.advance);
  }

  Color get _on => widget.isDark ? Colors.white : Colors.black87;
  Color get _card => widget.isDark ? const Color(0xFF1A191E) : Colors.grey[100]!;

  @override
  Widget build(BuildContext context) {
    final error = t.error;
    final sliderValue = t.advance.clamp(PaymentTerms.minStage, PaymentTerms.platformMaxAdvance).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Full escrow vs advance + stages
        _choice(
          selected: !t.enabled,
          title: 'Full payment into escrow',
          subtitle: 'The client pays the full fee upfront. Cre8Hive holds it and releases it to you when they mark the job complete.',
          onTap: () {
            t.enabled = false;
            _emit();
          },
        ),
        const SizedBox(height: 10),
        _choice(
          selected: t.enabled,
          title: 'Advance + payment stages',
          subtitle: 'You get an advance straight into your wallet to start the work. The rest is paid in stages the client approves as you deliver.',
          onTap: () {
            t.enabled = true;
            _emit();
          },
        ),

        if (t.enabled) ...[
          const SizedBox(height: 18),

          // 2. Advance slider (drives the stage split below)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Advance paid upfront', style: TextStyle(color: _on, fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${PaymentTerms._fmt(t.advance)}%',
                    style: const TextStyle(color: AppColors.BUTTONCOLOR, fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
              Slider(
                value: sliderValue,
                min: PaymentTerms.minStage,
                max: PaymentTerms.platformMaxAdvance,
                divisions: ((PaymentTerms.platformMaxAdvance - PaymentTerms.minStage) / 5).round(),
                label: '${sliderValue.toInt()}%',
                activeColor: AppColors.BUTTONCOLOR,
                onChanged: _setAdvance,
              ),
              Text('Drag to change the advance. The other stages adjust automatically. Maximum ${PaymentTerms.platformMaxAdvance.toInt()}%.',
                  style: TextStyle(color: _on.withOpacity(0.55), fontSize: 11, height: 1.4)),
            ]),
          ),
          const SizedBox(height: 14),

          // 3. Stages
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Payment stages', style: TextStyle(color: _on, fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${PaymentTerms._fmt(t.sum)}% of 100%',
                    style: TextStyle(
                      color: (t.sum - 100).abs() <= 0.01 ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    )),
              ]),
              const SizedBox(height: 4),
              Text('Name what you deliver at each stage. Clients book with exactly this split.',
                  style: TextStyle(color: _on.withOpacity(0.55), fontSize: 11)),
              const SizedBox(height: 12),
              for (var i = 0; i < t.stages.length; i++) _stageRow(i),
              if (t.stages.length < PaymentTerms.maxStages)
                TextButton.icon(
                  onPressed: _addStage,
                  icon: const Icon(Icons.add, size: 18, color: AppColors.BUTTONCOLOR),
                  label: const Text('Add a stage', style: TextStyle(color: AppColors.BUTTONCOLOR)),
                ),
              if (error != null) ...[
                const SizedBox(height: 4),
                Text(error, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
            ]),
          ),
        ],
      ],
    );
  }

  Widget _choice({required bool selected, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.BUTTONCOLOR : Colors.transparent, width: 1.5),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.BUTTONCOLOR : _on.withOpacity(0.4), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: _on, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: _on.withOpacity(0.65), fontSize: 12, height: 1.4)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _stageRow(int i) {
    final isAdvance = i == 0;
    final price = widget.price;
    final amount = price == null ? null : price * t.stages[i].percentage / 100;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isAdvance ? AppColors.BUTTONCOLOR : _on.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Text('${i + 1}', style: TextStyle(color: isAdvance ? Colors.white : _on, fontSize: 11)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(
              controller: _titles[i],
              style: TextStyle(color: _on, fontSize: 13),
              decoration: _input(isAdvance ? 'Advance' : 'What you deliver'),
              onChanged: (v) {
                t.stages[i].title = v;
                widget.onChanged(t);
              },
            ),
            if (amount != null && widget.formatMoney != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 2),
                child: Text(
                  isAdvance ? '${widget.formatMoney!(amount)} paid to you upfront' : widget.formatMoney!(amount),
                  style: TextStyle(color: _on.withOpacity(0.5), fontSize: 11),
                ),
              ),
          ]),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 68,
          child: TextField(
            controller: _pcts[i],
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
            textAlign: TextAlign.center,
            style: TextStyle(color: _on, fontSize: 13),
            decoration: _input('%').copyWith(suffixText: '%'),
            onChanged: (v) {
              t.stages[i].percentage = double.tryParse(v) ?? 0;
              _emit();
            },
          ),
        ),
        SizedBox(
          width: 34,
          child: (isAdvance || t.stages.length <= 2)
              ? const SizedBox.shrink()
              : IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.close, size: 18, color: _on.withOpacity(0.5)),
                  onPressed: () => _removeStage(i),
                ),
        ),
      ]),
    );
  }

  InputDecoration _input(String hint) => InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(color: _on.withOpacity(0.35), fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _on.withOpacity(0.15))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _on.withOpacity(0.15))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.BUTTONCOLOR)),
      );
}

/// Card on the creator's service page: shows the current terms and opens the
/// editor. Much easier to find than the old icon in the title bar.
class PaymentTermsCard extends StatelessWidget {
  final PaymentTerms terms;
  final VoidCallback onTap;

  const PaymentTermsCard({super.key, required this.terms, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final stages = terms.enabled ? terms.stages : const <PlanStageInput>[];

    return Material(
      color: const Color(0xFF1A191E),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.BUTTONCOLOR.withOpacity(0.5)),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.BUTTONCOLOR.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.payments_outlined, color: AppColors.BUTTONCOLOR),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Payment terms', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(terms.summary, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                if (stages.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    stages.map((s) => '${s.title} ${PaymentTerms._fmt(s.percentage)}%').join('  ·  '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ]),
            ),
            const SizedBox(width: 8),
            Text(terms.enabled ? 'Edit' : 'Set up',
                style: const TextStyle(color: AppColors.BUTTONCOLOR, fontSize: 13, fontWeight: FontWeight.w600)),
            const Icon(Icons.chevron_right, color: AppColors.BUTTONCOLOR, size: 20),
          ]),
        ),
      ),
    );
  }
}
