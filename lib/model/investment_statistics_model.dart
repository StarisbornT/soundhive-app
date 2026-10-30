import 'dart:convert';

import '../utils/json_parse.dart';
import 'user_model.dart';

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
      investmentId: asInt(map['investment_id']),
      user: User.fromJson(map['user'] ?? {}),
      vest: Vest.fromMap(map['vest'] ?? {}),
      investmentDetails: InvestmentDetails.fromMap(map['investment_details'] ?? {}),
      performanceMetrics: PerformanceMetrics.fromMap(map['performance_metrics'] ?? {}),
      timeMetrics: TimeMetrics.fromMap(map['time_metrics'] ?? {}),
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
      id: asInt(map['id']),
      investmentName: asString(map['investment_name']),
      beneficiaryName: asString(map['beneficiary_name']),
      roiPercentage: asString(map['roi_percentage'], '0'),
      durationMonths: asString(map['duration_months'], '0'),
      status: asString(map['status']),
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
      investedAmount: asDouble(map['invested_amount']),
      interestRate: asDouble(map['interest_rate']),
      expectedRepayment: asDouble(map['expected_repayment']),
      maturityDate: asString(map['maturity_date']),
      formattedMaturityDate: asString(map['formatted_maturity_date']),
      createdAt: asString(map['created_at']),
      status: asString(map['status']),
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
      roiSoFar: asDouble(map['roi_so_far']),
      totalExpectedRoi: asDouble(map['total_expected_roi']),
      progressPercentage: asDouble(map['progress_percentage']),
      daysSinceInvestment: asInt(map['days_since_investment']),
      totalInvestmentDays: asInt(map['total_investment_days']),
      currentValue: asDouble(map['current_value']),
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
      timeToMaturityDays: asInt(map['time_to_maturity_days']),
      timeToMaturityHuman: asString(map['time_to_maturity_human']),
      isMatured: asBool(map['is_matured']),
      isMaturingSoon: asBool(map['is_maturing_soon']),
      statusCategory: asString(map['status_category']),
    );
  }
}
