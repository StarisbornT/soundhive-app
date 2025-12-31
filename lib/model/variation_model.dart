class ServiceVariation {
  final String variationCode;
  final String name;
  final String variationAmount;
  final String fixedPrice;

  ServiceVariation({
    required this.variationCode,
    required this.name,
    required this.variationAmount,
    required this.fixedPrice,
  });

  factory ServiceVariation.fromJson(Map<String, dynamic> json) {
    return ServiceVariation(
      variationCode: json['variation_code'] as String,
      name: json['name'] as String,
      variationAmount: json['variation_amount'] as String,
      fixedPrice: json['fixedPrice'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'variation_code': variationCode,
      'name': name,
      'variation_amount': variationAmount,
      'fixedPrice': fixedPrice,
    };
  }
}
