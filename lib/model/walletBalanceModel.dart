import 'dart:convert';

class WalletBalanceModel {
  final String message;
  final AccountData data;

  WalletBalanceModel({
    required this.message,
    required this.data,
  });

  factory WalletBalanceModel.fromJson(String source) =>
      WalletBalanceModel.fromMap(json.decode(source));

  factory WalletBalanceModel.fromMap(Map<String, dynamic> map) {
    return WalletBalanceModel(
      message: map['message'] ?? '',
      data: AccountData.fromMap(map['data'] ?? {}),
    );
  }
}

class AccountData {
  final bool canDebit;
  final bool canCredit;
  final String id;
  final String client;
  final String accountProduct;
  final String accountNumber;
  final String accountName;
  final String accountType;
  final String currencyCode;
  final String bvn;
  final String identityId;
  final num accountBalance;
  final num bookBalance;
  final num interestBalance;
  final num withHoldingTaxBalance;
  final String status;
  final bool isDefault;
  final num nominalAnnualInterestRate;
  final String interestCompoundingPeriod;
  final String interestPostingPeriod;
  final String interestCalculationType;
  final String interestCalculationDaysInYearType;
  final num minRequiredOpeningBalance;
  final num lockinPeriodFrequency;
  final String lockinPeriodFrequencyType;
  final bool allowOverdraft;
  final num overdraftLimit;
  final bool chargeWithHoldingTax;
  final bool chargeValueAddedTax;
  final bool chargeStampDuty;
  final NotificationSettings notificationSettings;
  final bool isSubAccount;
  final SubAccountDetails subAccountDetails;
  final String externalReference;
  final bool isDeleted;
  final String createdAt;
  final String updatedAt;
  final String nin;
  final int v;
  final String cbaAccountId;

  AccountData({
    required this.canDebit,
    required this.canCredit,
    required this.id,
    required this.client,
    required this.accountProduct,
    required this.accountNumber,
    required this.accountName,
    required this.accountType,
    required this.currencyCode,
    required this.bvn,
    required this.identityId,
    required this.accountBalance,
    required this.bookBalance,
    required this.interestBalance,
    required this.withHoldingTaxBalance,
    required this.status,
    required this.isDefault,
    required this.nominalAnnualInterestRate,
    required this.interestCompoundingPeriod,
    required this.interestPostingPeriod,
    required this.interestCalculationType,
    required this.interestCalculationDaysInYearType,
    required this.minRequiredOpeningBalance,
    required this.lockinPeriodFrequency,
    required this.lockinPeriodFrequencyType,
    required this.allowOverdraft,
    required this.overdraftLimit,
    required this.chargeWithHoldingTax,
    required this.chargeValueAddedTax,
    required this.chargeStampDuty,
    required this.notificationSettings,
    required this.isSubAccount,
    required this.subAccountDetails,
    required this.externalReference,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    required this.nin,
    required this.v,
    required this.cbaAccountId,
  });

  factory AccountData.fromMap(Map<String, dynamic> map) {
    return AccountData(
      canDebit: map['canDebit'] ?? false,
      canCredit: map['canCredit'] ?? false,
      id: map['_id'] ?? '',
      client: map['client'] ?? '',
      accountProduct: map['accountProduct'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      accountName: map['accountName'] ?? '',
      accountType: map['accountType'] ?? '',
      currencyCode: map['currencyCode'] ?? '',
      bvn: map['bvn'] ?? '',
      identityId: map['identityId'] ?? '',
      accountBalance: map['accountBalance'] ?? 0,
      bookBalance: map['bookBalance'] ?? 0,
      interestBalance: map['interestBalance'] ?? 0,
      withHoldingTaxBalance: map['withHoldingTaxBalance'] ?? 0,
      status: map['status'] ?? '',
      isDefault: map['isDefault'] ?? false,
      nominalAnnualInterestRate: map['nominalAnnualInterestRate'] ?? 0,
      interestCompoundingPeriod: map['interestCompoundingPeriod'] ?? '',
      interestPostingPeriod: map['interestPostingPeriod'] ?? '',
      interestCalculationType: map['interestCalculationType'] ?? '',
      interestCalculationDaysInYearType: map['interestCalculationDaysInYearType'] ?? '',
      minRequiredOpeningBalance: map['minRequiredOpeningBalance'] ?? 0,
      lockinPeriodFrequency: map['lockinPeriodFrequency'] ?? 0,
      lockinPeriodFrequencyType: map['lockinPeriodFrequencyType'] ?? '',
      allowOverdraft: map['allowOverdraft'] ?? false,
      overdraftLimit: map['overdraftLimit'] ?? 0,
      chargeWithHoldingTax: map['chargeWithHoldingTax'] ?? false,
      chargeValueAddedTax: map['chargeValueAddedTax'] ?? false,
      chargeStampDuty: map['chargeStampDuty'] ?? false,
      notificationSettings:
      NotificationSettings.fromMap(map['notificationSettings'] ?? {}),
      isSubAccount: map['isSubAccount'] ?? false,
      subAccountDetails:
      SubAccountDetails.fromMap(map['subAccountDetails'] ?? {}),
      externalReference: map['externalReference'] ?? '',
      isDeleted: map['isDeleted'] ?? false,
      createdAt: map['createdAt'] ?? '',
      updatedAt: map['updatedAt'] ?? '',
      nin: map['nin'] ?? '',
      v: map['__v'] ?? 0,
      cbaAccountId: map['cbaAccountId'] ?? '',
    );
  }
}

class NotificationSettings {
  final bool smsNotification;
  final bool emailNotification;
  final bool emailMonthlyStatement;
  final bool smsMonthlyStatement;

  NotificationSettings({
    required this.smsNotification,
    required this.emailNotification,
    required this.emailMonthlyStatement,
    required this.smsMonthlyStatement,
  });

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      smsNotification: map['smsNotification'] ?? false,
      emailNotification: map['emailNotification'] ?? false,
      emailMonthlyStatement: map['emailMonthlyStatement'] ?? false,
      smsMonthlyStatement: map['smsMonthlyStatement'] ?? false,
    );
  }
}

class SubAccountDetails {
  final String firstName;
  final String lastName;
  final String emailAddress;
  final String bvn;
  final String nin;
  final String accountType;

  SubAccountDetails({
    required this.firstName,
    required this.lastName,
    required this.emailAddress,
    required this.bvn,
    required this.nin,
    required this.accountType,
  });

  factory SubAccountDetails.fromMap(Map<String, dynamic> map) {
    return SubAccountDetails(
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      emailAddress: map['emailAddress'] ?? '',
      bvn: map['bvn'] ?? '',
      nin: map['nin'] ?? '',
      accountType: map['accountType'] ?? '',
    );
  }
}
