// add_money_model.dart
class AddMoneyResponse {
  final bool success;
  final String message;
  final AddMoneyData? data;

  AddMoneyResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory AddMoneyResponse.fromJson(Map<String, dynamic> json) {
    return AddMoneyResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? AddMoneyData.fromJson(json['data']) : null,
    );
  }
}

class AddMoneyData {
  final String? checkoutUrl;
  final String? reference;
  final dynamic accountNumber;
  final String? accountName;
  final String? bankName;
  final double? amount;
  final String? currency;
  final int? expiryInSeconds;
  final String? expiryDate;

  AddMoneyData({
    this.checkoutUrl,
    this.reference,
    this.accountNumber,
    this.accountName,
    this.bankName,
    this.amount,
    this.currency,
    this.expiryInSeconds,
    this.expiryDate,
  });

  factory AddMoneyData.fromJson(Map<String, dynamic> json) {
    // Handle account_number that could be int or String
    String? accountNumberStr;
    if (json['account_number'] != null) {
      accountNumberStr = json['account_number'].toString();
    }

    return AddMoneyData(
      checkoutUrl: json['checkout_url'],
      reference: json['reference'],
      accountNumber: accountNumberStr,
      accountName: json['account_name'],
      bankName: json['bank_name'],
      amount: json['amount']?.toDouble(),
      currency: json['currency'],
      expiryInSeconds: json['expiry_in_seconds'],
      expiryDate: json['expiry_date'],
    );
  }
}