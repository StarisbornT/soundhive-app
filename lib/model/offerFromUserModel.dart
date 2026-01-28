import 'dart:convert';

import 'market_orders_service_model.dart';

class OfferFromUserModel {
  final bool status;
  final PaginatedBookingData data;

  OfferFromUserModel({
    required this.status,
    required this.data,
  });

  factory OfferFromUserModel.fromJson(String source) =>
      OfferFromUserModel.fromMap(json.decode(source));

  factory OfferFromUserModel.fromMap(Map<String, dynamic> map) {
    return OfferFromUserModel(
      status: map['status'] ?? false,
      data: PaginatedBookingData.fromMap(map['offers'] ?? {}),
    );
  }
}

class PaginatedBookingData {
  final int currentPage;
  final List<OfferFromUser> data;
  final String firstPageUrl;
  final int from;
  final int lastPage;
  final String lastPageUrl;
  final List<PageLink> links;
  final String? nextPageUrl;
  final String path;
  final int perPage;
  final String? prevPageUrl;
  final int to;
  final int total;

  PaginatedBookingData({
    required this.currentPage,
    required this.data,
    required this.firstPageUrl,
    required this.from,
    required this.lastPage,
    required this.lastPageUrl,
    required this.links,
    this.nextPageUrl,
    required this.path,
    required this.perPage,
    this.prevPageUrl,
    required this.to,
    required this.total,
  });

  factory PaginatedBookingData.fromMap(Map<String, dynamic> map) {
    return PaginatedBookingData(
      currentPage: map['current_page'] ?? 0,
      data: List<OfferFromUser>.from(
          map['data']?.map((x) => OfferFromUser.fromMap(x)) ?? []),
      firstPageUrl: map['first_page_url'] ?? '',
      from: map['from'] ?? 0,
      lastPage: map['last_page'] ?? 0,
      lastPageUrl: map['last_page_url'] ?? '',
      links: List<PageLink>.from(
          map['links']?.map((x) => PageLink.fromMap(x)) ?? []),
      nextPageUrl: map['next_page_url'],
      path: map['path'] ?? '',
      perPage: map['per_page'] ?? 0,
      prevPageUrl: map['prev_page_url'],
      to: map['to'] ?? 0,
      total: map['total'] ?? 0,
    );
  }
}

class PageLink {
  final String? url;
  final String label;
  final bool active;

  PageLink({
    this.url,
    required this.label,
    required this.active,
  });

  factory PageLink.fromMap(Map<String, dynamic> map) {
    return PageLink(
      url: map['url'],
      label: map['label'] ?? '',
      active: map['active'] ?? false,
    );
  }
}

class OfferFromUser {
  final int id;
  final String serviceId;
  final String userId;
  final String amount;
  final String status;
  final String createdAt;
  final String updatedAt;
  final BookingUser? user;
  final MarketOrder? service;
  final dynamic convertedAmount;
  final String? counterAmount;
  final String? counterCurrency;
  final String? counterMessage;
  final String? counterExpiresAt;

  OfferFromUser({
    required this.convertedAmount,
    required this.id,
    required this.serviceId,
    required this.userId,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.service,
    this.user,
    this.counterAmount,
    this.counterCurrency,
    this.counterMessage,
    this.counterExpiresAt,
  });

  factory OfferFromUser.fromMap(Map<String, dynamic> map) {
    return OfferFromUser(
      id: map['id'] ?? 0,
      serviceId: map['service_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      status: map['status'] ?? '',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
      amount: map['amount'],
      convertedAmount: map['converted_amount'] ?? 0.0,
      service: map['service'] != null ? MarketOrder.fromMap(map['service']) : null,
      user: map['user'] != null ? BookingUser.fromMap(map['user']) : null,
      counterAmount: map['counter_amount']?.toString(),
      counterCurrency: map['counter_currency'],
      counterMessage: map['counter_message'],
      counterExpiresAt: map['counter_expires_at'],
    );
  }
}

class Service {
  final int id;
  final String userId;
  final String serviceName;
  final String categoryId;
  final String subCategoryId;
  final String rate;
  final String? coverImage;
  final String? link;
  final String? serviceImage;
  final String? serviceAudio;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String currency;
  final String? serviceDescription;

  Service({
    required this.id,
    required this.userId,
    required this.serviceName,
    required this.categoryId,
    required this.subCategoryId,
    required this.rate,
    this.coverImage,
    this.link,
    this.serviceImage,
    this.serviceAudio,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.currency,
    this.serviceDescription,
  });

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'] ?? 0,
      userId: map['user_id']?.toString() ?? '',
      serviceName: map['service_name'] ?? '',
      categoryId: map['category_id']?.toString() ?? '',
      subCategoryId: map['sub_category_id']?.toString() ?? '',
      rate: map['rate']?.toString() ?? '',
      coverImage: map['cover_image'],
      link: map['link'],
      serviceImage: map['service_image'],
      serviceAudio: map['service_audio'],
      status: map['status'] ?? '',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
      currency: map['currency'] ?? '',
      serviceDescription: map['service_description'],
    );
  }
}

class BookingUser {
  final int id;
  final String firstName;
  final String lastName;
  final String dob;
  final String phoneNumber;
  final String pin;
  final String? image;
  final String? interest;
  final String role;
  final String email;
  final String? emailVerifiedAt;
  final String bvn;
  final String? nin;
  final String? gender;
  final String? surname;
  final String? faceImage;
  final String? middleName;
  final String? nameOnCard;
  final String? lgaOfOrigin;
  final String? stateOfOrigin;
  final String? lgaOfCapture;
  final String? stateOfCapture;
  final String? lgaOfResidence;
  final String? stateOfResidence;
  final String? phoneNumber1;
  final String? phoneNumber2;
  final String? maritalStatus;
  final String? enrollBankCode;
  final String? enrollUserName;
  final String? productReference;
  final String? watchlisted;
  final String? enrollmentDate;
  final String? branchName;
  final String? landmarks;
  final String? additionalInfo1;
  final String? bvnReference;
  final String createdAt;
  final String updatedAt;
  final bool isActive;
  final String country;
  final String? location;
  final String countryCode;
  final String? latitude;
  final String? longitude;
  final bool acceptedTerms;
  final Wallet? wallet;

  BookingUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dob,
    required this.phoneNumber,
    required this.pin,
    this.image,
    this.interest,
    required this.role,
    required this.email,
    this.emailVerifiedAt,
    required this.bvn,
    this.nin,
    this.gender,
    this.surname,
    this.faceImage,
    this.middleName,
    this.nameOnCard,
    this.lgaOfOrigin,
    this.stateOfOrigin,
    this.lgaOfCapture,
    this.stateOfCapture,
    this.lgaOfResidence,
    this.stateOfResidence,
    this.phoneNumber1,
    this.phoneNumber2,
    this.maritalStatus,
    this.enrollBankCode,
    this.enrollUserName,
    this.productReference,
    this.watchlisted,
    this.enrollmentDate,
    this.branchName,
    this.landmarks,
    this.additionalInfo1,
    this.bvnReference,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.country,
    this.location,
    required this.countryCode,
    this.latitude,
    this.longitude,
    required this.acceptedTerms,
    this.wallet,
  });

  factory BookingUser.fromMap(Map<String, dynamic> map) {
    return BookingUser(
      id: map['id'] ?? 0,
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      dob: map['dob'] ?? '',
      phoneNumber: map['phone_number'] ?? '',
      pin: map['pin'] ?? '',
      image: map['image'],
      interest: map['interest'],
      role: map['role'] ?? '',
      email: map['email'] ?? '',
      emailVerifiedAt: map['email_verified_at'],
      bvn: map['bvn'] ?? '',
      nin: map['nin'],
      gender: map['gender'],
      surname: map['surname'],
      faceImage: map['face_image'],
      middleName: map['middle_name'],
      nameOnCard: map['name_on_card'],
      lgaOfOrigin: map['lga_of_origin'],
      stateOfOrigin: map['state_of_origin'],
      lgaOfCapture: map['lga_of_capture'],
      stateOfCapture: map['state_of_capture'],
      lgaOfResidence: map['lga_of_residence'],
      stateOfResidence: map['state_of_residence'],
      phoneNumber1: map['phone_number1'],
      phoneNumber2: map['phone_number2'],
      maritalStatus: map['marital_status'],
      enrollBankCode: map['enroll_bank_code'],
      enrollUserName: map['enroll_user_name'],
      productReference: map['product_reference'],
      watchlisted: map['watchlisted'],
      enrollmentDate: map['enrollment_date'],
      branchName: map['branch_name'],
      landmarks: map['landmarks'],
      additionalInfo1: map['additional_info1'],
      bvnReference: map['bvn_reference'],
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
      isActive: map['is_active'] ?? false,
      country: map['country'] ?? '',
      location: map['location'],
      countryCode: map['country_code'] ?? '',
      latitude: map['latitude'],
      longitude: map['longitude'],
      acceptedTerms: map['accepted_terms'] ?? false,
      wallet: map['wallet'] != null ? Wallet.fromMap(map['wallet']) : null,
    );
  }
}

class Wallet {
  final int id;
  final String userId;
  final String? accountNumber;
  final String? bankName;
  final String balance;
  final String createdAt;
  final String updatedAt;
  final String escrowBalance;
  final String amountEarned;
  final String currency;

  Wallet({
    required this.id,
    required this.userId,
    this.accountNumber,
    this.bankName,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
    required this.escrowBalance,
    required this.amountEarned,
    required this.currency,
  });

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] ?? 0,
      userId: map['user_id']?.toString() ?? '',
      accountNumber: map['account_number'],
      bankName: map['bank_name'],
      balance: map['balance'] ?? '0.00',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
      escrowBalance: map['escrow_balance'] ?? '0.00',
      amountEarned: map['amount_earned'] ?? '0.00',
      currency: map['currency'] ?? '',
    );
  }
}

class BookingStats {
  final int totalBookings;
  final int pendingBookings;
  final int successfulBookings;
  final int reversedBookings;
  final int cancelledBookings;

  BookingStats({
    required this.totalBookings,
    required this.pendingBookings,
    required this.successfulBookings,
    required this.reversedBookings,
    required this.cancelledBookings,
  });

  factory BookingStats.fromMap(Map<String, dynamic> map) {
    return BookingStats(
      totalBookings: map['total_bookings'] ?? 0,
      pendingBookings: map['pending_bookings'] ?? 0,
      successfulBookings: map['successful_bookings'] ?? 0,
      reversedBookings: map['reversed_bookings'] ?? 0,
      cancelledBookings: map['cancelled_bookings'] ?? 0,
    );
  }
}
