import 'dart:convert';

class TransactionHistoryResponse {
  final String message;
  final TransactionData data;

  TransactionHistoryResponse({
    required this.message,
    required this.data,
  });

  factory TransactionHistoryResponse.fromJson(String source) =>
      TransactionHistoryResponse.fromMap(json.decode(source));

  factory TransactionHistoryResponse.fromMap(Map<String, dynamic> map) {
    return TransactionHistoryResponse(
      message: map['message'] ?? '',
      data: TransactionData.fromMap(map['data']),
    );
  }
}

class TransactionData {
  final int statusCode;
  final String message;
  final List<Transaction> data;
  final Pagination pagination;

  TransactionData({
    required this.statusCode,
    required this.message,
    required this.data,
    required this.pagination,
  });

  factory TransactionData.fromMap(Map<String, dynamic> map) {
    return TransactionData(
      statusCode: map['statusCode'] ?? 0,
      message: map['message'] ?? '',
      data: List<Transaction>.from(
        map['data']?.map((x) => Transaction.fromMap(x)) ?? [],
      ),
      pagination: Pagination.fromMap(map['pagination']),
    );
  }
}

class Transaction {
  final bool isReversal;
  final String id;
  final String? cbaTransactionId;
  final String client;
  final Account account;
  final String paymentReference;
  final String type;
  final String provider;
  final String providerChannel;
  final String? paymentServices;
  final String narration;
  final num amount;
  final num runningBalance;
  final String transactionDate;
  final String valueDate;
  final int v;

  Transaction({
    required this.isReversal,
    required this.id,
    this.cbaTransactionId,
    required this.client,
    required this.account,
    required this.paymentReference,
    required this.type,
    required this.provider,
    required this.providerChannel,
    this.paymentServices,
    required this.narration,
    required this.amount,
    required this.runningBalance,
    required this.transactionDate,
    required this.valueDate,
    required this.v,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      isReversal: map['isReversal'] ?? false,
      id: map['_id'] ?? '',
      cbaTransactionId: map['cbaTransactionId'],
      client: map['client'] ?? '',
      account: Account.fromMap(map['account']),
      paymentReference: map['paymentReference'] ?? '',
      type: map['type'] ?? '',
      provider: map['provider'] ?? '',
      providerChannel: map['providerChannel'] ?? '',
      paymentServices: map['paymentServices'],
      narration: map['narration'] ?? '',
      amount: map['amount'] ?? 0,
      runningBalance: map['runningBalance'] ?? 0,
      transactionDate: map['transactionDate'] ?? '',
      valueDate: map['valueDate'] ?? '',
      v: map['__v'] ?? 0,
    );
  }
}

class Account {
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
  final String? nin;
  final int v;
  final String cbaAccountId;

  Account({
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
    this.nin,
    required this.v,
    required this.cbaAccountId,
  });

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
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
      notificationSettings: NotificationSettings.fromMap(map['notificationSettings']),
      isSubAccount: map['isSubAccount'] ?? false,
      subAccountDetails: SubAccountDetails.fromMap(map['subAccountDetails']),
      externalReference: map['externalReference'] ?? '',
      isDeleted: map['isDeleted'] ?? false,
      createdAt: map['createdAt'] ?? '',
      updatedAt: map['updatedAt'] ?? '',
      nin: map['nin'],
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

class Pagination {
  final int total;
  final int pages;
  final int page;
  final int limit;

  Pagination({
    required this.total,
    required this.pages,
    required this.page,
    required this.limit,
  });

  factory Pagination.fromMap(Map<String, dynamic> map) {
    return Pagination(
      total: map['total'] ?? 0,
      pages: map['pages'] ?? 0,
      page: map['page'] ?? 0,
      limit: map['limit'] ?? 0,
    );
  }
}
