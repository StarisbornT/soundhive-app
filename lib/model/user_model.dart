class MemberCreatorResponse {
  final User? user;

  MemberCreatorResponse({this.user});

  factory MemberCreatorResponse.fromJson(Map<String, dynamic> json) {
    return MemberCreatorResponse(
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}

class User {
  final int id;
  final String firstName;
  final String lastName;
  final String dob;
  final String phoneNumber;
  final String pin;
  final String? image;
  final String role;
  final String email;
  final String? emailVerifiedAt;
  final String? bvn;
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
  final bool? acceptedTerms;
  final String createdAt;
  final String updatedAt;
  final Creator? creator;
  final Wallet? wallet;
  final Artist? artist;
  final List<dynamic>? interests;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dob,
    required this.phoneNumber,
    required this.pin,
    this.image,
    required this.role,
    required this.email,
    this.emailVerifiedAt,
    this.bvn,
    this.nin,
    this.gender,
    this.surname,
    this.faceImage,
    this.middleName,
    this.nameOnCard,
    this.lgaOfOrigin,
    this.acceptedTerms,
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
    this.creator,
    this.wallet,
    this.artist,
    this.interests
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      dob: json['dob'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      pin: json['pin'] ?? '',
      image: json['image'],
      role: json['role'] ?? '',
      email: json['email'] ?? '',
      emailVerifiedAt: json['email_verified_at'],
      bvn: json['bvn'],
      nin: json['nin'],
      gender: json['gender'],
      acceptedTerms: json['accepted_terms'],
      surname: json['surname'],
      faceImage: json['face_image'],
      middleName: json['middle_name'],
      nameOnCard: json['name_on_card'],
      lgaOfOrigin: json['lga_of_origin'],
      stateOfOrigin: json['state_of_origin'],
      lgaOfCapture: json['lga_of_capture'],
      stateOfCapture: json['state_of_capture'],
      lgaOfResidence: json['lga_of_residence'],
      stateOfResidence: json['state_of_residence'],
      phoneNumber1: json['phone_number1'],
      phoneNumber2: json['phone_number2'],
      maritalStatus: json['marital_status'],
      enrollBankCode: json['enroll_bank_code'],
      enrollUserName: json['enroll_user_name'],
      productReference: json['product_reference'],
      watchlisted: json['watchlisted'],
      enrollmentDate: json['enrollment_date'],
      branchName: json['branch_name'],
      landmarks: json['landmarks'],
      additionalInfo1: json['additional_info1'],
      bvnReference: json['bvn_reference'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      interests: (json['interests'] is List)
          ? json['interests']
          : (json['interests'] is String && json['interests'].isNotEmpty)
          ? [json['interests']]
          : [],
      creator: json['creator'] != null ? Creator.fromJson(json['creator']) : null,
      wallet: json['wallet'] != null ? Wallet.fromJson(json['wallet']) : null,
      artist: json['artist'] != null ? Artist.fromJson(json['artist']) : null,
    );
  }
}

// Placeholder classes for now
class Creator {
  final int id;
  final String userId;
  final String? gender;
  final String? nin;
  final String? idType;
  final String? copyOfId;
  final String? utilityBill;
  final String? copyOfUtilityBill;
  final String? jobTitle;
  final String? bio;
  final bool? active;
  final String? location;
  final String? linkedin;
  final String? x;
  final String? instagram;
  final String createdAt;
  final String updatedAt;
  final String? baseCurrency;

  Creator({
    required this.id,
    required this.userId,
    this.gender,
    this.nin,
    this.idType,
    this.copyOfId,
    this.utilityBill,
    this.copyOfUtilityBill,
    this.jobTitle,
    this.bio,
    this.active,
    this.location,
    this.linkedin,
    this.x,
    this.instagram,
    required this.createdAt,
    required this.updatedAt,
    this.baseCurrency
  });

  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? '',
      gender: json['gender'],
      nin: json['nin'],
      idType: json['id_type'],
      copyOfId: json['copy_of_id'],
      utilityBill: json['utility_bill'],
      copyOfUtilityBill: json['copy_of_utility_bill'],
      jobTitle: json['job_title'],
      bio: json['bio'],
      active: json['active'],
      location: json['location'],
      linkedin: json['linkedin'],
      x: json['x'],
      instagram: json['instagram'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      baseCurrency: json['base_currency'] ?? '',
    );
  }
}

class Artist {
  final int id;
  final String userId;
  final String? userName;
  final String? profilePhoto;
  final String? coverPhoto;
  final bool? status;
  final String followers;
  final String createdAt;
  final String updatedAt;

  Artist({
    required this.id,
    required this.userId,
    required this.userName,
    required this.profilePhoto,
    required this.coverPhoto,
    required this.status,
    required this.followers,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? '',
      userName: json['username'],
      profilePhoto: json['profile_photo'],
      coverPhoto: json['cover_photo'],
      followers: json['followers'],
      status: json['status'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class Wallet {
  final int id;
  final String userId;
  final String? bankName;
  final String? accountNumber;
  final String? balance;
  final String createdAt;
  final String updatedAt;
  final String escrowBalance;
  final String amountEarned;
  final String currency;
  final String dollarBalance;
  final bool hasActivatedDollarWallet;
  Wallet({
    required this.id,
    required this.userId,
    this.bankName,
    this.accountNumber,
    this.balance,
    required this.createdAt,
    required this.updatedAt,
    required this.amountEarned,
    required this.currency,
    required this.escrowBalance,
    required this.dollarBalance,
    required this.hasActivatedDollarWallet
});

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? '',
      bankName: json['bank_name'],
      accountNumber: json['account_number'],
      balance: json['balance'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      escrowBalance: json['escrow_balance'] ?? '',
      amountEarned: json['amount_earned'] ?? '',
      currency: json['currency'] ?? '',
      dollarBalance: json['dollar_balance'] ?? '',
      hasActivatedDollarWallet: json['has_activated_dollar_wallet'] ?? '',
    );
  }
}
