import 'dart:convert';

import 'investment_model.dart';
import 'market_orders_service_model.dart';

class ActiveInvestmentResponse {
  final String message;
  final List<ActiveInvestment> data;
  final bool status;

  ActiveInvestmentResponse({
    required this.message,
    required this.data,
    required this.status,
  });

  factory ActiveInvestmentResponse.fromJson(String source) =>
      ActiveInvestmentResponse.fromMap(json.decode(source));

  factory ActiveInvestmentResponse.fromMap(Map<String, dynamic> map) {
    return ActiveInvestmentResponse(
      message: map['message'] ?? '',
      data: List<ActiveInvestment>.from(
          map['data']?.map((x) => ActiveInvestment.fromMap(x)) ?? []),
      status: map['status'] ?? false,
    );
  }
}

class ActiveInvestment {
  final int id;
  final String memberServiceId;
  final String memberId;
  final String serviceId;
  final List<String> startDate;
  final String? endDate;
  final String amount;
  final String status;
  final String? nameReference;
  final String paymentReference;
  final String paymentType;
  final MemberServiceData memberServiceData;
  final dynamic memberServiceTransferData;
  final String createdAt;
  final String updatedAt;
  final MarketOrder? service;

  ActiveInvestment({
    required this.id,
    required this.memberServiceId,
    required this.memberId,
    required this.serviceId,
    required this.startDate,
    this.endDate,
    required this.amount,
    required this.status,
    this.nameReference,
    required this.paymentReference,
    required this.paymentType,
    required this.memberServiceData,
    this.memberServiceTransferData,
    required this.createdAt,
    required this.updatedAt,
    this.service
  });

  factory ActiveInvestment.fromJson(String source) =>
      ActiveInvestment.fromMap(json.decode(source));

  factory ActiveInvestment.fromMap(Map<String, dynamic> map) {
    return ActiveInvestment(
      id: map['id'] ?? 0,
      memberServiceId: map['member_service_id'] ?? '',
      memberId: map['member_id'] ?? '',
      serviceId: map['service_id']?.toString() ?? '',
      startDate: map['start_date'] is List
          ? List<String>.from(map['start_date'])
          : [map['start_date']?.toString() ?? ''],
      endDate: map['end_date'],
      amount: map['amount'] ?? '',
      status: map['status'] ?? '',
      nameReference: map['name_reference'],
      paymentReference: map['payment_reference'] ?? '',
      paymentType: map['payment_type'] ?? '',
      memberServiceData: MemberServiceData.fromMap(map['member_service_data'] ?? {}),
      memberServiceTransferData: map['member_service_transfer_data'],
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
      service: map['service'] != null ? MarketOrder.fromMap(map['service']) : null,
    );
  }
}
class MemberServiceData {
  final int serviceId;
  final List<String> startDate;
  final String paymentType;

  MemberServiceData({
    required this.serviceId,
    required this.startDate,
    required this.paymentType,
  });

  factory MemberServiceData.fromMap(Map<String, dynamic> map) {
    return MemberServiceData(
      serviceId: map['service_id'] ?? 0,
      startDate: map['start_date'] is List
          ? List<String>.from(map['start_date'])
          : [map['start_date']?.toString() ?? ''],
      paymentType: map['payment_type'] ?? '',
    );
  }
}


