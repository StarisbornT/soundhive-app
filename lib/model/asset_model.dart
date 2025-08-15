import 'dart:convert';

class AssetResponse {
  final String message;
  final List<Asset> data;
  final List<String> statuses;

  AssetResponse({
    required this.message,
    required this.data,
    required this.statuses,
  });

  factory AssetResponse.fromJson(String source) =>
      AssetResponse.fromMap(json.decode(source));

  factory AssetResponse.fromMap(Map<String, dynamic> map) {
    return AssetResponse(
      message: map['message'] ?? '',
      data: List<Asset>.from(map['data']?.map((x) => Asset.fromMap(x)) ?? []),
      statuses: List<String>.from(map['statuses'] ?? []),
    );
  }
}

class Asset {
  final int id;
  final String hiveAssetId;
  final String memberID;
  final String assetType;
  final String assetName;
  final String price;
  final String status;
  final String assetDescription;
  final String assetUrl;
  final String? imageUrl;
  final String createdAt;
  final String updatedAt;
  final Seller? seller;

  Asset({
    required this.id,
    required this.hiveAssetId,
    required this.memberID,
    required this.assetType,
    required this.assetName,
    required this.price,
    required this.status,
    required this.assetDescription,
    required this.assetUrl,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.seller,
  });

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] ?? 0,
      hiveAssetId: map['hive_asset_id'] ?? '',
      memberID: map['member_id'] ?? '',
      assetType: map['asset_type'] ?? '',
      assetName: map['asset_name'] ?? '',
      price: map['price']?.toString() ?? '',
      status: map['status'] ?? '',
      assetDescription: map['asset_description'] ?? '',
      assetUrl: map['asset_url'] ?? '',
      imageUrl: map['image_url'],
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
      seller: map['seller'] != null ? Seller.fromMap(map['seller']) : null,
    );
  }
}

class Seller {
  final String memberId;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String imageUrl;

  Seller({
    required this.memberId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.imageUrl,
  });

  factory Seller.fromMap(Map<String, dynamic> map) {
    return Seller(
      memberId: map['member_id'] ?? '',
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phone_number'] ?? '',
      imageUrl: map['image_url'] ?? '',
    );
  }
}
