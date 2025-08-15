import 'dart:convert';

import 'package:soundhive2/model/asset_model.dart';

class MarketOrdersAssetPurchaseModel {
  final String message;
  final List<MarketOrderAsset> data;

  MarketOrdersAssetPurchaseModel({
    required this.message,
    required this.data,
  });

  factory MarketOrdersAssetPurchaseModel.fromJson(String source) =>
      MarketOrdersAssetPurchaseModel.fromMap(json.decode(source));

  factory MarketOrdersAssetPurchaseModel.fromMap(Map<String, dynamic> map) {
    return MarketOrdersAssetPurchaseModel(
      message: map['message'] ?? '',
      data: List<MarketOrderAsset>.from(
          map['data']?.map((x) => MarketOrderAsset.fromMap(x)) ?? []),
    );
  }
}

class MarketOrderAsset {
  final int id;
  final String memberId;
  final String hiveAssetPurchasesId;
  final String hiveAssetId;
  final String amountPaid;
  final String? purchaseApprovalAt;
  final String? review;
  final String? reviewMessage;
  final String createdAt;
  final String updatedAt;
  final Asset asset;

  MarketOrderAsset({
    required this.id,
    required this.memberId,
    required this.hiveAssetPurchasesId,
    required this.hiveAssetId,
    required this.amountPaid,
    this.purchaseApprovalAt,
    this.review,
    this.reviewMessage,
    required this.createdAt,
    required this.updatedAt,
    required this.asset,
  });

  factory MarketOrderAsset.fromMap(Map<String, dynamic> map) {
    return MarketOrderAsset(
      id: map['id'] ?? 0,
      memberId: map['member_id'] ?? '',
      hiveAssetPurchasesId: map['hive_asset_purchases_id'] ?? '',
      hiveAssetId: map['hive_asset_id'] ?? '',
      amountPaid: map['amount_paid'] ?? '',
      purchaseApprovalAt: map['purchase_approval_at'],
      review: map['review'],
      reviewMessage: map['review_message'],
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
      asset: Asset.fromMap(map['hiveasset']),
    );
  }
}




class Reviews {
  final int total;
  final List<dynamic> reviews;

  Reviews({
    required this.total,
    required this.reviews,
  });

  factory Reviews.fromMap(Map<String, dynamic> map) {
    return Reviews(
      total: map['total'] ?? 0,
      reviews: List<dynamic>.from(map['reviews'] ?? []),
    );
  }
}
