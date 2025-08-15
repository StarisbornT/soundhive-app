import 'dart:convert';

import 'asset_model.dart';

class AssetMarketResponse {
  final String message;
  final List<Asset> data;

  AssetMarketResponse({required this.message, required this.data});
  factory AssetMarketResponse.fromJson(String source) =>
      AssetMarketResponse.fromMap(json.decode(source));

  factory AssetMarketResponse.fromMap(Map<String, dynamic> map) {
    return AssetMarketResponse(
      message: map['message'] ?? '',
      data: List<Asset>.from(map['data']?.map((x) => Asset.fromMap(x)) ?? []),
    );
  }
}
