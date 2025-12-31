class IdentifierModel {
  final String serviceId;
  final String name;
  final String minimumAmount;
  final dynamic maximumAmount;
  final String convinienceFee;
  final String productType;
  final String image;

  IdentifierModel({
    required this.serviceId,
    required this.name,
    required this.maximumAmount,
    required this.minimumAmount,
    required this.convinienceFee,
    required this.productType,
    required this.image,
  });

  factory IdentifierModel.fromJson(Map<String, dynamic> json) {
    return IdentifierModel(
      serviceId: json['serviceID'] as String,
      name: json['name'] as String,
      minimumAmount: json['minimium_amount'] as String,
      maximumAmount: json['maximum_amount'],
      convinienceFee: json['convinience_fee'] as String,
      productType: json['product_type'] as String,
      image: json['image'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceID': serviceId,
      'name': name,
      'minimium_amount': maximumAmount,
      'maximum_amount': minimumAmount,
      'convinience_fee': convinienceFee,
      'product_type': productType,
      'image': image,
    };
  }
}
