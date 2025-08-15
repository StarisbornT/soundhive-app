class MemberCreatorResponse {
  final User? member;
  final Creator? creator;

  MemberCreatorResponse({this.member, this.creator});

  factory MemberCreatorResponse.fromJson(Map<String, dynamic> json) {
    return MemberCreatorResponse(
      member: json['member'] != null ? User.fromJson(json['member']) : null,
      creator: json['creator'] != null ? Creator.fromJson(json['creator']) : null,
    );
  }
}

class User {
  final int id;
  final String memberId;
  final String? profileImage;
  final String email;
  final String phoneNumber;
  final String firstName;
  final String lastName;
  final String dob;
  final String pin;
  final dynamic interests; // Changed to dynamic since it could be null or other types
  final String status;
  final String password;
  final String? emailOtp;
  final String? emailVerifiedAt;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;
  final KycModel? kyc;
  final Account? account;

  User({
    required this.id,
    this.profileImage,
    required this.memberId,
    required this.email,
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
    required this.dob,
    required this.pin,
    this.interests,
    required this.status,
    required this.password,
    this.emailOtp,
    this.emailVerifiedAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    this.kyc,
    this.account,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      memberId: json['member_id'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      dob: json['dob'] ?? '',
      pin: json['pin'] ?? '',
      interests: json['interests'],
      status: json['status'] ?? '',
      password: json['password'] ?? '',
      emailOtp: json['email_otp'],
      profileImage: json['profile_image'],
      emailVerifiedAt: json['email_verified_at'],
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      kyc: json['kyc'] != null ? KycModel.fromJson(json['kyc']) : null,
      account: json['account'] != null ? Account.fromJson(json['account']) : null,
    );
  }
}

class Account {
  final int id;
  final String memberId;
  final String type;
  final String bank;
  final String accountId;
  final String accountNumber;
  final String accountName;
  final String accountType;
  final String externalReference;
  final String kycId;
  final String createdAt;
  final String updatedAt;

  Account({
    required this.id,
    required this.memberId,
    required this.type,
    required this.bank,
    required this.accountId,
    required this.accountNumber,
    required this.accountName,
    required this.accountType,
    required this.externalReference,
    required this.kycId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] ?? 0,
      memberId: json['member_id'] ?? '',
      type: json['type'] ?? '',
      bank: json['bank'] ?? '',
      accountId: json['account_id'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      accountName: json['accountName'] ?? '',
      accountType: json['accountType'] ?? '',
      externalReference: json['externalReference'] ?? '',
      kycId: json['kyc_id'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class KycModel {
  final int id;
  final String memberId;
  final String verifyId;
  final KycResponseModel response;

  KycModel({
    required this.id,
    required this.memberId,
    required this.verifyId,
    required this.response,
  });

  factory KycModel.fromJson(Map<String, dynamic> json) {
    return KycModel(
      id: json['id'],
      memberId: json['member_id'],
      verifyId: json['verify_id'],
      response: KycResponseModel.fromJson(json['response']),
    );
  }
}

class KycResponseModel {
  final String bvn;
  final String fullName;
  final String firstName;
  final String middleName;
  final String lastName;
  final String dateOfBirth;
  final String phoneNumber1;
  final String phoneNumber2;
  final String gender;
  final String? enrollmentBank;
  final String? enrollmentBranch;
  final String? email;
  final String lgaOfOrigin;
  final String? lgaOfResidence;
  final String maritalStatus;
  final String? nin;
  final String? nationality;
  final String? residentialAddress;
  final String stateOfOrigin;
  final String? stateOfResidence;
  final String? title;
  final String? watchListed;
  final String levelOfAccount;
  final String registrationDate;
  final String? imageBase64;

  KycResponseModel({
    required this.bvn,
    required this.fullName,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.dateOfBirth,
    required this.phoneNumber1,
    required this.phoneNumber2,
    required this.gender,
    this.enrollmentBank,
    this.enrollmentBranch,
    this.email,
    required this.lgaOfOrigin,
    this.lgaOfResidence,
    required this.maritalStatus,
    this.nin,
    this.nationality,
    this.residentialAddress,
    required this.stateOfOrigin,
    this.stateOfResidence,
    this.title,
    this.watchListed,
    required this.levelOfAccount,
    required this.registrationDate,
    this.imageBase64,
  });

  factory KycResponseModel.fromJson(Map<String, dynamic> json) {
    return KycResponseModel(
      bvn: json['bvn'] ?? '',
      fullName: json['fullName'] ?? '',
      firstName: json['firstName'] ?? '',
      middleName: json['middleName'] ?? '',
      lastName: json['lastName'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? '',
      phoneNumber1: json['phoneNumber1'] ?? '',
      phoneNumber2: json['phoneNumber2'] ?? '',
      gender: json['gender'] ?? '',
      enrollmentBank: json['enrollmentBank'],
      enrollmentBranch: json['enrollmentBranch'],
      email: json['email'],
      lgaOfOrigin: json['lgaOfOrigin'] ?? '',
      lgaOfResidence: json['lgaOfResidence'],
      maritalStatus: json['maritalStatus'] ?? '',
      nin: json['nin'],
      nationality: json['nationality'],
      residentialAddress: json['residentialAddress'],
      stateOfOrigin: json['stateOfOrigin'] ?? '',
      stateOfResidence: json['stateOfResidence'],
      title: json['title'],
      watchListed: json['watchListed'],
      levelOfAccount: json['levelOfAccount'] ?? '',
      registrationDate: json['registrationDate'] ?? '',
      imageBase64: json['imageBase64'],
    );
  }
}

class Creator {
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

  Creator({
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
  });

  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator(
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
