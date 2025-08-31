import 'dart:convert';

class InvestmentStatisticsModel {
  final bool status;
  final InvestmentData data;

  InvestmentStatisticsModel({
    required this.status,
    required this.data,
  });

  factory InvestmentStatisticsModel.fromJson(String source) =>
      InvestmentStatisticsModel.fromMap(json.decode(source));

  factory InvestmentStatisticsModel.fromMap(Map<String, dynamic> map) {
    return InvestmentStatisticsModel(
      status: map['status'] ?? false,
      data: InvestmentData.fromMap(map['data'] ?? {}),
    );
  }
}

class InvestmentData {
  final int investmentId;
  final User user;
  final Vest vest;
  final InvestmentDetails investmentDetails;
  final PerformanceMetrics performanceMetrics;
  final TimeMetrics timeMetrics;

  InvestmentData({
    required this.investmentId,
    required this.user,
    required this.vest,
    required this.investmentDetails,
    required this.performanceMetrics,
    required this.timeMetrics,
  });

  factory InvestmentData.fromMap(Map<String, dynamic> map) {
    return InvestmentData(
      investmentId: map['investment_id'] ?? 0,
      user: User.fromMap(map['user'] ?? {}),
      vest: Vest.fromMap(map['vest'] ?? {}),
      investmentDetails: InvestmentDetails.fromMap(map['investment_details'] ?? {}),
      performanceMetrics: PerformanceMetrics.fromMap(map['performance_metrics'] ?? {}),
      timeMetrics: TimeMetrics.fromMap(map['time_metrics'] ?? {}),
    );
  }
}

class User {
  final int id;
  final String? name;

  User({required this.id, this.name});

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? 0,
      name: map['name'],
    );
  }
}

class Vest {
  final int id;
  final String investmentName;
  final String beneficiaryName;
  final String roiPercentage;
  final String durationMonths;
  final String status;

  Vest({
    required this.id,
    required this.investmentName,
    required this.beneficiaryName,
    required this.roiPercentage,
    required this.durationMonths,
    required this.status,
  });

  factory Vest.fromMap(Map<String, dynamic> map) {
    return Vest(
      id: map['id'] ?? 0,
      investmentName: map['investment_name'] ?? '',
      beneficiaryName: map['beneficiary_name'] ?? '',
      roiPercentage: map['roi_percentage'] ?? '0',
      durationMonths: map['duration_months'] ?? '0',
      status: map['status'] ?? '',
    );
  }
}

class InvestmentDetails {
  final double investedAmount;
  final double interestRate;
  final double expectedRepayment;
  final String maturityDate;
  final String formattedMaturityDate;
  final String createdAt;
  final String status;

  InvestmentDetails({
    required this.investedAmount,
    required this.interestRate,
    required this.expectedRepayment,
    required this.maturityDate,
    required this.formattedMaturityDate,
    required this.createdAt,
    required this.status,
  });

  factory InvestmentDetails.fromMap(Map<String, dynamic> map) {
    return InvestmentDetails(
      investedAmount: (map['invested_amount'] ?? 0).toDouble(),
      interestRate: (map['interest_rate'] ?? 0).toDouble(),
      expectedRepayment: (map['expected_repayment'] ?? 0).toDouble(),
      maturityDate: map['maturity_date'] ?? '',
      formattedMaturityDate: map['formatted_maturity_date'] ?? '',
      createdAt: map['created_at'] ?? '',
      status: map['status'] ?? '',
    );
  }
}

class PerformanceMetrics {
  final double roiSoFar;
  final double totalExpectedRoi;
  final double progressPercentage;
  final int daysSinceInvestment;
  final int totalInvestmentDays;
  final double currentValue;

  PerformanceMetrics({
    required this.roiSoFar,
    required this.totalExpectedRoi,
    required this.progressPercentage,
    required this.daysSinceInvestment,
    required this.totalInvestmentDays,
    required this.currentValue,
  });

  factory PerformanceMetrics.fromMap(Map<String, dynamic> map) {
    return PerformanceMetrics(
      roiSoFar: (map['roi_so_far'] ?? 0).toDouble(),
      totalExpectedRoi: (map['total_expected_roi'] ?? 0).toDouble(),
      progressPercentage: (map['progress_percentage'] ?? 0).toDouble(),
      daysSinceInvestment: map['days_since_investment'] ?? 0,
      totalInvestmentDays: map['total_investment_days'] ?? 0,
      currentValue: (map['current_value'] ?? 0).toDouble(),
    );
  }
}

class TimeMetrics {
  final int timeToMaturityDays;
  final String timeToMaturityHuman;
  final bool isMatured;
  final bool isMaturingSoon;
  final String statusCategory;

  TimeMetrics({
    required this.timeToMaturityDays,
    required this.timeToMaturityHuman,
    required this.isMatured,
    required this.isMaturingSoon,
    required this.statusCategory,
  });

  factory TimeMetrics.fromMap(Map<String, dynamic> map) {
    return TimeMetrics(
      timeToMaturityDays: map['time_to_maturity_days'] ?? 0,
      timeToMaturityHuman: map['time_to_maturity_human'] ?? '',
      isMatured: map['is_matured'] ?? false,
      isMaturingSoon: map['is_maturing_soon'] ?? false,
      statusCategory: map['status_category'] ?? '',
    );
  }
}
