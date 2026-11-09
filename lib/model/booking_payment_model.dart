// Module 2 — advance & milestone payments.
// Mirrors the JSON returned by:
//   POST /service/payment-plan/preview   -> PaymentQuote
//   GET  /service/bookings/{id}/payments -> BookingPaymentSummary

double _d(dynamic v) => v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
double? _dn(dynamic v) => v == null ? null : double.tryParse(v.toString());
int _i(dynamic v) => v == null ? 0 : int.tryParse(v.toString()) ?? 0;

/// One stage the user is building in the plan selector.
class PlanStageInput {
  String title;
  double percentage;

  PlanStageInput({required this.title, required this.percentage});

  Map<String, dynamic> toJson() => {'title': title, 'percentage': percentage};
}

/// What is sent to the backend as `payment_plan`.
class PaymentPlanRequest {
  final bool isMilestone;
  final bool payAdvanceOnly;
  final List<PlanStageInput> stages;

  const PaymentPlanRequest({
    required this.isMilestone,
    this.payAdvanceOnly = false,
    this.stages = const [],
  });

  const PaymentPlanRequest.fullEscrow()
      : isMilestone = false,
        payAdvanceOnly = false,
        stages = const [];

  Map<String, dynamic> toJson() => isMilestone
      ? {
          'type': 'milestone',
          'funding': payAdvanceOnly ? 'advance_only' : 'upfront',
          'has_advance': true,
          'stages': stages.map((s) => s.toJson()).toList(),
        }
      : {'type': 'full_escrow'};
}

class PlanRules {
  final int maxStages;
  final double maxAdvancePercent;
  final double minStagePercent;
  final double commissionRate;
  final double? serviceMaxAdvancePercent;

  PlanRules({
    required this.maxStages,
    required this.maxAdvancePercent,
    required this.minStagePercent,
    required this.commissionRate,
    this.serviceMaxAdvancePercent,
  });

  /// The advance cap that actually applies to this service.
  double get advanceCap => serviceMaxAdvancePercent ?? maxAdvancePercent;

  factory PlanRules.fromMap(Map<String, dynamic>? m) {
    m ??= {};
    return PlanRules(
      maxStages: _i(m['max_stages']) == 0 ? 4 : _i(m['max_stages']),
      maxAdvancePercent: _dn(m['max_advance_percent']) ?? 50,
      minStagePercent: _dn(m['min_stage_percent']) ?? 10,
      commissionRate: _dn(m['commission_rate']) ?? 0.05,
      serviceMaxAdvancePercent: _dn(m['service_max_advance_percent']),
    );
  }
}

class QuoteStage {
  final int sequence;
  final String title;
  final double percentage;
  final bool isAdvance;
  final double amount;
  final double userAmount;
  final bool paidNow;

  QuoteStage({
    required this.sequence,
    required this.title,
    required this.percentage,
    required this.isAdvance,
    required this.amount,
    required this.userAmount,
    required this.paidNow,
  });

  factory QuoteStage.fromMap(Map<String, dynamic> m) => QuoteStage(
        sequence: _i(m['sequence']),
        title: m['title']?.toString() ?? '',
        percentage: _d(m['percentage']),
        isAdvance: m['is_advance'] == true,
        amount: _d(m['amount']),
        userAmount: _d(m['user_amount']),
        paidNow: m['paid_now'] == true,
      );
}

class PaymentQuote {
  final String planType;
  final String fundingMode;
  final double totalAmount;
  final String currency;
  final String userCurrency;
  final double userTotal;
  final double dueNow;
  final List<QuoteStage> stages;
  final PlanRules rules;

  PaymentQuote({
    required this.planType,
    required this.fundingMode,
    required this.totalAmount,
    required this.currency,
    required this.userCurrency,
    required this.userTotal,
    required this.dueNow,
    required this.stages,
    required this.rules,
  });

  double get payLater => (userTotal - dueNow).clamp(0, double.infinity).toDouble();

  factory PaymentQuote.fromMap(Map<String, dynamic> m) => PaymentQuote(
        planType: m['plan_type']?.toString() ?? 'FULL_ESCROW',
        fundingMode: m['funding_mode']?.toString() ?? 'UPFRONT',
        totalAmount: _d(m['total_amount']),
        currency: m['currency']?.toString() ?? 'NGN',
        userCurrency: m['user_currency']?.toString() ?? 'NGN',
        userTotal: _d(m['user_total']),
        dueNow: _d(m['due_now']),
        stages: ((m['stages'] as List?) ?? [])
            .map((e) => QuoteStage.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        rules: PlanRules.fromMap(m['rules'] == null ? null : Map<String, dynamic>.from(m['rules'])),
      );
}

class Milestone {
  final int id;
  final int sequence;
  final String title;
  final double percentage;
  final bool isAdvance;
  final String status; // UNFUNDED FUNDED SUBMITTED RELEASED REFUNDED CANCELLED
  final double amount;
  final double escrowAmount;
  final double? paidAmount;
  final String? paidCurrency;
  final double? amountToPay;
  final double? commissionAmount;
  final double? netAmount;
  final String? submissionNote;
  final String? fundedAt;
  final String? submittedAt;
  final String? releasedAt;
  final String? refundedAt;

  Milestone({
    required this.id,
    required this.sequence,
    required this.title,
    required this.percentage,
    required this.isAdvance,
    required this.status,
    required this.amount,
    required this.escrowAmount,
    this.paidAmount,
    this.paidCurrency,
    this.amountToPay,
    this.commissionAmount,
    this.netAmount,
    this.submissionNote,
    this.fundedAt,
    this.submittedAt,
    this.releasedAt,
    this.refundedAt,
  });

  bool get isInEscrow => status == 'FUNDED' || status == 'SUBMITTED';

  factory Milestone.fromMap(Map<String, dynamic> m) => Milestone(
        id: _i(m['id']),
        sequence: _i(m['sequence']),
        title: m['title']?.toString() ?? '',
        percentage: _d(m['percentage']),
        isAdvance: m['is_advance'] == true,
        status: m['status']?.toString() ?? 'UNFUNDED',
        amount: _d(m['amount']),
        escrowAmount: _d(m['escrow_amount']),
        paidAmount: _dn(m['paid_amount']),
        paidCurrency: m['paid_currency']?.toString(),
        amountToPay: _dn(m['amount_to_pay']),
        commissionAmount: _dn(m['commission_amount']),
        netAmount: _dn(m['net_amount']),
        submissionNote: m['submission_note']?.toString(),
        fundedAt: m['funded_at']?.toString(),
        submittedAt: m['submitted_at']?.toString(),
        releasedAt: m['released_at']?.toString(),
        refundedAt: m['refunded_at']?.toString(),
      );
}

class NextAction {
  final String action; // fund approve submit wait view disputed completed cancelled
  final int? milestoneId;
  final String label;

  NextAction({required this.action, this.milestoneId, required this.label});

  factory NextAction.fromMap(Map<String, dynamic> m) => NextAction(
        action: m['action']?.toString() ?? 'view',
        milestoneId: m['milestone_id'] == null ? null : _i(m['milestone_id']),
        label: m['label']?.toString() ?? '',
      );
}

class BookingPaymentSummary {
  final int bookingId;
  final bool legacy;
  final String status;
  final String viewerRole; // customer creator admin
  final String? legacyMessage;

  // plan
  final String planType;
  final String fundingMode;
  final String planStatus;
  final String currency;
  final double totalAmount;
  final String escrowCurrency;
  final String userCurrency;
  final double commissionRate;

  // totals (service currency)
  final double paid;
  final double inEscrow;
  final double released;
  final double outstanding;
  final double refunded;
  final int stagesTotal;
  final int stagesReleased;

  // creator totals (creator wallet currency)
  final double receivedInWallet;
  final double commissionDeducted;
  final double heldInEscrow;
  final double notYetFunded;

  final List<Milestone> milestones;
  final NextAction? nextAction;
  final bool canCancel;

  BookingPaymentSummary({
    required this.bookingId,
    required this.legacy,
    required this.status,
    required this.viewerRole,
    this.legacyMessage,
    this.planType = 'FULL_ESCROW',
    this.fundingMode = 'UPFRONT',
    this.planStatus = 'ACTIVE',
    this.currency = 'NGN',
    this.totalAmount = 0,
    this.escrowCurrency = 'NGN',
    this.userCurrency = 'NGN',
    this.commissionRate = 0.05,
    this.paid = 0,
    this.inEscrow = 0,
    this.released = 0,
    this.outstanding = 0,
    this.refunded = 0,
    this.stagesTotal = 0,
    this.stagesReleased = 0,
    this.receivedInWallet = 0,
    this.commissionDeducted = 0,
    this.heldInEscrow = 0,
    this.notYetFunded = 0,
    this.milestones = const [],
    this.nextAction,
    this.canCancel = false,
  });

  bool get isCustomer => viewerRole == 'customer';
  bool get isCreator => viewerRole == 'creator';
  bool get isMilestonePlan => planType == 'MILESTONE';
  bool get isActive => planStatus == 'ACTIVE';

  factory BookingPaymentSummary.fromMap(Map<String, dynamic> m) {
    final legacy = m['legacy'] == true;
    if (legacy) {
      return BookingPaymentSummary(
        bookingId: _i(m['booking_id']),
        legacy: true,
        status: m['status']?.toString() ?? '',
        viewerRole: 'customer',
        legacyMessage: m['message']?.toString(),
      );
    }

    final plan = Map<String, dynamic>.from(m['plan'] ?? {});
    final totals = Map<String, dynamic>.from(m['totals'] ?? {});
    final ct = Map<String, dynamic>.from(m['creator_totals'] ?? {});

    return BookingPaymentSummary(
      bookingId: _i(m['booking_id']),
      legacy: false,
      status: m['status']?.toString() ?? '',
      viewerRole: m['viewer_role']?.toString() ?? 'customer',
      planType: plan['type']?.toString() ?? 'FULL_ESCROW',
      fundingMode: plan['funding_mode']?.toString() ?? 'UPFRONT',
      planStatus: plan['status']?.toString() ?? 'ACTIVE',
      currency: plan['currency']?.toString() ?? 'NGN',
      totalAmount: _d(plan['total_amount']),
      escrowCurrency: plan['escrow_currency']?.toString() ?? 'NGN',
      userCurrency: plan['user_currency']?.toString() ?? 'NGN',
      commissionRate: _d(plan['commission_rate']),
      paid: _d(totals['paid']),
      inEscrow: _d(totals['in_escrow']),
      released: _d(totals['released']),
      outstanding: _d(totals['outstanding']),
      refunded: _d(totals['refunded']),
      stagesTotal: _i(totals['stages_total']),
      stagesReleased: _i(totals['stages_released']),
      receivedInWallet: _d(ct['received_in_wallet']),
      commissionDeducted: _d(ct['commission_deducted']),
      heldInEscrow: _d(ct['held_in_escrow']),
      notYetFunded: _d(ct['not_yet_funded']),
      milestones: ((m['milestones'] as List?) ?? [])
          .map((e) => Milestone.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      nextAction: m['next_action'] == null
          ? null
          : NextAction.fromMap(Map<String, dynamic>.from(m['next_action'])),
      canCancel: m['can_cancel'] == true,
    );
  }
}
