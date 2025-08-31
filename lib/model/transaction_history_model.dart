import 'dart:convert';

class TransactionHistoryResponse {
  final bool success;
  final String message;
  final TransactionPagination data;

  TransactionHistoryResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory TransactionHistoryResponse.fromJson(String source) =>
      TransactionHistoryResponse.fromMap(json.decode(source));

  factory TransactionHistoryResponse.fromMap(Map<String, dynamic> map) {
    return TransactionHistoryResponse(
      success: map['success'] ?? false,
      message: map['message'] ?? '',
      data: TransactionPagination.fromMap(map['data'] ?? {}),
    );
  }
}

class TransactionPagination {
  final int currentPage;
  final List<Transaction> data;
  final String? firstPageUrl;
  final int? from;
  final int lastPage;
  final String? lastPageUrl;
  final List<PageLink> links;
  final String? nextPageUrl;
  final String? path;
  final int perPage;
  final String? prevPageUrl;
  final int? to;
  final int total;

  TransactionPagination({
    required this.currentPage,
    required this.data,
    this.firstPageUrl,
    this.from,
    required this.lastPage,
    this.lastPageUrl,
    required this.links,
    this.nextPageUrl,
    this.path,
    required this.perPage,
    this.prevPageUrl,
    this.to,
    required this.total,
  });

  factory TransactionPagination.fromMap(Map<String, dynamic> map) {
    return TransactionPagination(
      currentPage: map['current_page'] ?? 1,
      data: List<Transaction>.from(
        (map['data'] ?? []).map((x) => Transaction.fromMap(x)),
      ),
      firstPageUrl: map['first_page_url'],
      from: map['from'],
      lastPage: map['last_page'] ?? 1,
      lastPageUrl: map['last_page_url'],
      links: List<PageLink>.from(
        (map['links'] ?? []).map((x) => PageLink.fromMap(x)),
      ),
      nextPageUrl: map['next_page_url'],
      path: map['path'],
      perPage: map['per_page'] is int
          ? map['per_page']
          : int.tryParse(map['per_page'].toString()) ?? 0,
      prevPageUrl: map['prev_page_url'],
      to: map['to'],
      total: map['total'] ?? 0,
    );
  }
}

class Transaction {
  final int id;
  final String? type;
  final String userId;
  final String walletId;
  final String title;
  final String? bookingId;
  final String reference;
  final String amount;
  final String totalAmount;
  final String totalCharge;
  final String transactionStatus;
  final String? approvedForReversal;
  final String? dateApprovedForReversal;
  final String? dateMarkedForReversal;
  final String? dateReversed;
  final String narration;
  final String? otherInfo;
  final String? sourceBankName;
  final String? currency;
  final String? feeAmount;
  final String? feePercent;
  final String createdAt;
  final String updatedAt;
  final String vestId;

  Transaction({
    required this.id,
    this.type,
    required this.userId,
    required this.walletId,
    required this.title,
    this.bookingId,
    required this.reference,
    required this.amount,
    required this.totalAmount,
    required this.totalCharge,
    required this.transactionStatus,
    this.approvedForReversal,
    this.dateApprovedForReversal,
    this.dateMarkedForReversal,
    this.dateReversed,
    required this.narration,
    this.otherInfo,
    this.sourceBankName,
    this.currency,
    this.feeAmount,
    this.feePercent,
    required this.createdAt,
    required this.updatedAt,
    required this.vestId,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] ?? 0,
      type: map['type'],
      userId: map['user_id'] ?? '',
      walletId: map['wallet_id'] ?? '',
      title: map['title'] ?? '',
      bookingId: map['booking_id'],
      reference: map['reference'] ?? '',
      amount: map['amount'] ?? '0.00',
      totalAmount: map['total_amount'] ?? '0.00',
      totalCharge: map['total_charge'] ?? '0.00',
      transactionStatus: map['transaction_status'] ?? '',
      approvedForReversal: map['approved_for_reversal'],
      dateApprovedForReversal: map['date_approved_for_reversal'],
      dateMarkedForReversal: map['date_marked_for_reversal'],
      dateReversed: map['date_reversed'],
      narration: map['narration'] ?? '',
      otherInfo: map['other_info'],
      sourceBankName: map['source_bank_name'],
      currency: map['currency'],
      feeAmount: map['fee_amount'],
      feePercent: map['fee_percent'],
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
      vestId: map['vest_id'] ?? '',
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
