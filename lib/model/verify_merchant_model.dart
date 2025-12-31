class VerifyMerchantResponse {
  final bool success;
  final String message;
  final VerifyMerchantModel data;

  VerifyMerchantResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory VerifyMerchantResponse.fromJson(Map<String, dynamic> json) {
    return VerifyMerchantResponse(
      success: json['status'] ?? false,
      message: json['message'] ?? '',
      data: VerifyMerchantModel.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.toJson(),
    };
  }
}

class VerifyMerchantModel {
  final String customerName;
  final String? address;
  final String meterNumber;
  final String customerArrears;
  final double minimumAmount;
  final double minPurchaseAmount;
  final String? businessUnit;
  final String meterType;
  final bool wrongBillersCode;

  VerifyMerchantModel({
    required this.customerName,
    this.address,
    required this.meterNumber,
    required this.customerArrears,
    required this.minimumAmount,
    required this.minPurchaseAmount,
    this.businessUnit,
    required this.meterType,
    required this.wrongBillersCode,
  });

  factory VerifyMerchantModel.fromJson(Map<String, dynamic> json) {
    return VerifyMerchantModel(
      customerName: json['Customer_Name'] ?? '',
      address: json['Address'],
      meterNumber: json['Meter_Number'] ?? '',
      customerArrears: json['Customer_Arrears'] ?? '0',
      minimumAmount: (json['Minimum_Amount'] is num)
          ? (json['Minimum_Amount'] as num).toDouble()
          : double.tryParse(json['Minimum_Amount']?.toString() ?? '0') ?? 0.0,
      minPurchaseAmount: (json['Min_Purchase_Amount'] is num)
          ? (json['Min_Purchase_Amount'] as num).toDouble()
          : double.tryParse(json['Min_Purchase_Amount']?.toString() ?? '0') ?? 0.0,
      businessUnit: json['Business_Unit'],
      meterType: json['Meter_Type'] ?? '',
      wrongBillersCode: json['WrongBillersCode'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Customer_Name': customerName,
      'Address': address,
      'Meter_Number': meterNumber,
      'Customer_Arrears': customerArrears,
      'Minimum_Amount': minimumAmount,
      'Min_Purchase_Amount': minPurchaseAmount,
      'Business_Unit': businessUnit,
      'Meter_Type': meterType,
      'WrongBillersCode': wrongBillersCode,
    };
  }
}
