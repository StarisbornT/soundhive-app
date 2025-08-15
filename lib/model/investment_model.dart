import 'dart:convert';

class InvestmentResponse {
  final String message;
  final List<Investment> data;

  InvestmentResponse({
    required this.message,
    required this.data,
  });

  factory InvestmentResponse.fromJson(String source) =>
      InvestmentResponse.fromMap(json.decode(source));

  factory InvestmentResponse.fromMap(Map<String, dynamic> map) {
    return InvestmentResponse(
      message: map['message'] ?? '',
      data: List<Investment>.from(map['data']?.map((x) => Investment.fromMap(x)) ?? []),
    );
  }
}

class Investment {
  final int id;
  final String adminId;
  final String investmentId;
  final String imageUrl;
  final String status;
  final String investmentName;
  final String minimumAmount;
  final String roi;
  final String duration;
  final String investmentNote;
  final String createdAt;
  final String updatedAt;

  Investment({
    required this.id,
    required this.adminId,
    required this.investmentId,
    required this.imageUrl,
    required this.status,
    required this.investmentName,
    required this.minimumAmount,
    required this.roi,
    required this.duration,
    required this.investmentNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Investment.fromJson(String source) =>
      Investment.fromMap(json.decode(source));

  factory Investment.fromMap(Map<String, dynamic> map) {
    return Investment(
      id: map['id'] ?? 0,
      adminId: map['admin_id'] ?? '',
      investmentId: map['investment_id'] ?? '',
      imageUrl: map['image_url'] ?? '',
      status: map['status'] ?? '',
      investmentName: map['investment_name'] ?? '',
      minimumAmount: map['minimum_amount'] ?? '',
      roi: map['roi'] ?? '',
      duration: map['duration'] ?? '',
      investmentNote: map['investment_note'] ?? '',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
    );
  }
}
