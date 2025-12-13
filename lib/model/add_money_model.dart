class AddMoneyModel {
  final bool success;
  final String message;
  final AddMoneyData? data;

  AddMoneyModel({
    required this.success,
    required this.message,
    this.data,
  });

  factory AddMoneyModel.fromJson(Map<String, dynamic> json) {
    return AddMoneyModel(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Something went wrong',
      data: json['data'] != null
          ? AddMoneyData.fromJson(json['data'])
          : null,
    );
  }
}

class AddMoneyData {
  final String checkoutUrl;
  final String payCode;
  final String currency;
  final int amount;
  final String reference;

  AddMoneyData({
    required this.checkoutUrl,
    required this.payCode,
    required this.currency,
    required this.amount,
    required this.reference,
  });

  factory AddMoneyData.fromJson(Map<String, dynamic> json) {
    return AddMoneyData(
      checkoutUrl: json['checkout_url'] ?? '',
      payCode: json['pay_code'] ?? '',
      currency: json['currency'] ?? '',
      amount: json['amount'] ?? 0,
      reference: json['reference'] ?? '',
    );
  }
}
