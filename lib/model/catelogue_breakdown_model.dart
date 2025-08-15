import 'dart:convert';

class CatalogueBreakdownModel {
  final String message;
  final BreakDown data;
  final bool status;

  CatalogueBreakdownModel({
    required this.message,
    required this.data,
    required this.status,
  });

  factory CatalogueBreakdownModel.fromJson(String source) =>
      CatalogueBreakdownModel.fromMap(json.decode(source));

  factory CatalogueBreakdownModel.fromMap(Map<String, dynamic> map) {
    return CatalogueBreakdownModel(
      message: map['message'] ?? '',
      data: BreakDown.fromMap(map['data'] ?? {}),
      status: map['status'] ?? false,
    );
  }
}

class BreakDown {
  final int hiveAssetPurchaseCount;
  final int hiveAssetPurchaseAmount;
  final int hiveServicePurchaseCount;
  final int hiveServicePurchaseAmount;

  BreakDown({
    required this.hiveAssetPurchaseCount,
    required this.hiveAssetPurchaseAmount,
    required this.hiveServicePurchaseCount,
    required this.hiveServicePurchaseAmount,
  });

  factory BreakDown.fromJson(String source) =>
      BreakDown.fromMap(json.decode(source));

  factory BreakDown.fromMap(Map<String, dynamic> map) {
    return BreakDown(
      hiveAssetPurchaseCount: map['hive_asset_purchase_count'] ?? 0,
      hiveAssetPurchaseAmount: map['hive_asset_purchase_amount'] ?? 0,
      hiveServicePurchaseCount: map['hive_service_purchase_count'] ?? 0,
      hiveServicePurchaseAmount: map['hive_service_purchase_amount'] ?? 0,
    );
  }
}
