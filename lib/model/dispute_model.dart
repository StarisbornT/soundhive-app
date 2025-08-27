import 'dart:convert';

class DisputeModel {
  final bool status;
  final DisputeData? data; // nullable

  DisputeModel({
    required this.status,
    required this.data,
  });

  factory DisputeModel.fromJson(String source) =>
      DisputeModel.fromMap(json.decode(source));

  factory DisputeModel.fromMap(Map<String, dynamic> map) {
    return DisputeModel(
      status: map['status'] ?? false,
      data: map['data'] == null ? null : DisputeData.fromMap(map['data']),
    );
  }
}

class DisputeData {
  final int id;
  final String userId;
  final String creatorId;
  final String bookingId;
  final String resolveStatus;
  final String status;
  final String createdAt;
  final String updatedAt;

  DisputeData({
    required this.id,
    required this.userId,
    required this.creatorId,
    required this.bookingId,
    required this.resolveStatus,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DisputeData.fromMap(Map<String, dynamic> map) {
    return DisputeData(
      id: map['id'] ?? 0,
      userId: map['user_id'] ?? '',
      creatorId: map['creator_id'] ?? '',
      bookingId: map['booking_id'] ?? '',
      resolveStatus: map['resolve_status'] ?? '',
      status: map['status'] ?? '',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
    );
  }
}
