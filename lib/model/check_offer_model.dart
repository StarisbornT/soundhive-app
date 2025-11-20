import 'dart:convert';

import 'offerFromUserModel.dart';

class CheckOfferModel {
  final bool status;
  final bool hasActiveOffer;
  final OfferFromUser? offer;

  CheckOfferModel({
    required this.status,
    required this.hasActiveOffer,
    this.offer
  });

  factory CheckOfferModel.fromJson(String source) =>
      CheckOfferModel.fromMap(json.decode(source));

  factory CheckOfferModel.fromMap(Map<String, dynamic> map) {
    return CheckOfferModel(
      status: map['status'] ?? false,
      hasActiveOffer: map['has_active_offer'] ?? false,
      offer: map['offer'] != null ? OfferFromUser.fromMap(map['offer']) : null,
    );
  }
}