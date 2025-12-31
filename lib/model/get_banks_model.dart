import 'dart:convert';

class GetBanksResponseModel {
  final bool status;
  final List<BankData> data;

  GetBanksResponseModel({
    required this.status,
    required this.data,
  });

  factory GetBanksResponseModel.fromJson(String source) =>
      GetBanksResponseModel.fromMap(json.decode(source));

  factory GetBanksResponseModel.fromMap(Map<String, dynamic> map) {
    return GetBanksResponseModel(
      status: map['status'] ?? false,
      data: List<BankData>.from(
        (map['data'] ?? []).map((x) => BankData.fromMap(x)),
      ),
    );
  }
}

class BankData {
  final String id;
  final String code;
  final String name;
  final String nibssCode;
  final bool isCashPickUp;
  final bool? isMobileVerified;
  final List<dynamic> branches;

  BankData({
    required this.id,
    required this.code,
    required this.name,
    required this.nibssCode,
    required this.isCashPickUp,
    required this.isMobileVerified,
    required this.branches,
  });

  factory BankData.fromMap(Map<String, dynamic> map) {
    return BankData(
      id: map['id']?.toString() ?? '',
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      nibssCode: map['nibssCode'] ?? '',
      isCashPickUp: map['isCashPickUp'] ?? false,
      isMobileVerified: map['isMobileVerified'],
      branches: List<dynamic>.from(map['branches'] ?? []),
    );
  }
}
