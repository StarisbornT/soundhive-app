import 'dart:convert';

class CreatorServiceStatisticsModel {
  final bool status;
  final String message;
  final ServiceData data;

  CreatorServiceStatisticsModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory CreatorServiceStatisticsModel.fromJson(String source) =>
      CreatorServiceStatisticsModel.fromMap(json.decode(source));

  factory CreatorServiceStatisticsModel.fromMap(Map<String, dynamic> map) {
    return CreatorServiceStatisticsModel(
      status: map['status'] ?? false,
      message: map['message'] ?? '',
      data: ServiceData.fromMap(map['data'] ?? {}),
    );
  }
}

class ServiceData {
  final Services services;
  final Earnings earnings;

  ServiceData({
    required this.services,
    required this.earnings,
  });

  factory ServiceData.fromMap(Map<String, dynamic> map) {
    return ServiceData(
      services: Services.fromMap(map['services'] ?? {}),
      earnings: Earnings.fromMap(map['earnings'] ?? {}),
    );
  }
}

class Services {
  final int approved;
  final int pending;

  Services({
    required this.approved,
    required this.pending,
  });

  factory Services.fromMap(Map<String, dynamic> map) {
    return Services(
      approved: map['approved'] ?? 0,
      pending: map['pending'] ?? 0,
    );
  }
}

class Earnings {
  final double totalEarned;
  final double escrowBalance;

  Earnings({
    required this.totalEarned,
    required this.escrowBalance,
  });

  factory Earnings.fromMap(Map<String, dynamic> map) {
    return Earnings(
      totalEarned: (map['total_earned'] ?? 0).toDouble(),
      escrowBalance: (map['escrow_balance'] ?? 0).toDouble(),
    );
  }
}
