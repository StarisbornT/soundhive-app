
import 'package:soundhive2/model/user_model.dart';

class CreatorListResponse {
  final String message;
  final CreatorPaginatedData? data;

  CreatorListResponse({required this.message, this.data});

  factory CreatorListResponse.fromMap(Map<String, dynamic> json) {
    return CreatorListResponse(
      message: json['message'],
      data: json['data'] != null ? CreatorPaginatedData.fromMap(json['data']) : null,
    );
  }
}

class CreatorPaginatedData {
  final int currentPage;
  final List<CreatorData> data;

  CreatorPaginatedData({required this.currentPage, required this.data});

  factory CreatorPaginatedData.fromMap(Map<String, dynamic> json) {
    return CreatorPaginatedData(
      currentPage: json['current_page'],
      data: json['data'] != null
          ? List<CreatorData>.from(json['data'].map((x) => CreatorData.fromJson(x)))
          : [],
    );
  }
}

class CreatorData {
  final int id;
  final String? profileImage;
  final String? memberId;
  final String? gender;
  final String? bvn;
  final String? status;
  final String? nin;
  final String? idType;
  final String? copyIdType;
  final String? copyUtilityBill;
  final String? jobTitle;
  final String? bioDescription;
  final String? location;
  final List<String>? typeOfService;
  final List<Rate>? rates;
  final List<String>? availabilityCalendar;
  final String? linkedin;
  final String? x;
  final String? instagram;
  final String? createdAt;
  final String? updatedAt;
  final User? member;

  CreatorData({
    required this.id,
    this.memberId,
    this.gender,
    this.bvn,
    this.profileImage,
    this.status,
    this.nin,
    this.idType,
    this.copyIdType,
    this.copyUtilityBill,
    this.jobTitle,
    this.bioDescription,
    this.location,
    this.typeOfService,
    this.rates,
    this.availabilityCalendar,
    this.linkedin,
    this.x,
    this.instagram,
    this.createdAt,
    this.updatedAt,
    this.member
  });

  factory CreatorData.fromJson(Map<String, dynamic> json) {
    return CreatorData(
      id: json['id'],
      memberId: json['member_id'],
      profileImage: json['profile_image'],
      gender: json['gender'],
      status: json['status'],
      bvn: json['bvn'],
      nin: json['nin'],
      idType: json['id_type'],
      copyIdType: json['copy_id_type'],
      copyUtilityBill: json['copy_utility_bill'],
      jobTitle: json['job_title'],
      bioDescription: json['bio_description'],
      location: json['location'],
      typeOfService: json['type_of_service'] != null
          ? List<String>.from(json['type_of_service'].map((e) => e.toString()))
          : null,
      rates: json['rates'] != null
          ? List<Rate>.from(json['rates'].map((x) => Rate.fromJson(x)))
          : null,
      availabilityCalendar: json['availability_calendar'] != null
          ? List<String>.from(json['availability_calendar'].map((x) => x.toString()))
          : null,
      linkedin: json['linkedin'],
      x: json['x'],
      instagram: json['instagram'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      member: json['member'] != null ? User.fromJson(json['member']) : null,
    );
  }
}

class Rate {
  final String productName;
  final String amount;

  Rate({required this.productName, required this.amount});

  factory Rate.fromJson(Map<String, dynamic> json) {
    return Rate(
      productName: json['product_name'] ?? '',
      amount: json['amount'] ?? '0',
    );
  }
}
