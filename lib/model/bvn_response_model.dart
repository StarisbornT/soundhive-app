class BvnResponseModel {
  final String status;
  final String message;
  final PaymentData? data;

  BvnResponseModel({
    required this.status,
    required this.message,
    this.data,
  });

  factory BvnResponseModel.fromJson(Map<String, dynamic> json) {
    return BvnResponseModel(
      status: json['status'] ?? false,
      message: json['message'] ?? 'Something went wrong',
      data: json['data'] != null ? PaymentData.fromJson(json['data']) : null,
    );
  }
}

class PaymentData {
  final String authorizationUrl;
  final String accessCode;
  final String reference;

  PaymentData({
    required this.authorizationUrl,
    required this.accessCode,
    required this.reference,
  });

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    // Some APIs mistakenly double nest 'data', so we safeguard against that here:
    final actualData = json['data'] ?? json;

    return PaymentData(
      authorizationUrl: actualData['url'] ?? '',
      accessCode: actualData['access_code'] ?? '',
      reference: actualData['reference'] ?? '',
    );
  }
}
