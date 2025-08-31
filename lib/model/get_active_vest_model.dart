import 'dart:convert';

import 'package:soundhive2/model/user_model.dart';

import 'investment_model.dart';

class ActiveVestResponse {
  final bool status;
  final PaginatedActiveInvestmentData data;

  ActiveVestResponse({
    required this.status,
    required this.data,
  });

  factory ActiveVestResponse.fromJson(String source) =>
      ActiveVestResponse.fromMap(json.decode(source));

  factory ActiveVestResponse.fromMap(Map<String, dynamic> map) {
    return ActiveVestResponse(
      status: map['status'] ?? false,
      data: PaginatedActiveInvestmentData.fromMap(map['data'] ?? {}),
    );
  }
}

class PaginatedActiveInvestmentData {
  final int currentPage;
  final List<ActiveVest> data;
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

  PaginatedActiveInvestmentData({
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

  factory PaginatedActiveInvestmentData.fromMap(Map<String, dynamic> map) {
    return PaginatedActiveInvestmentData(
      currentPage: map['current_page'] ?? 0,
      data: List<ActiveVest>.from(
          map['data']?.map((x) => ActiveVest.fromMap(x)) ?? []),
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

class ActiveVest {
  final int id;
  final String userId;
  final String vestId;
  final String amount;
  final String expectedRepayment;
  final String interest;
  final String maturityDate;
  final String status;
  final String createdAt;
  final String updatedAt;
  final Investment? vest;
  final User? user;

  ActiveVest({
    required this.id,
    required this.userId,
    required this.vestId,
    required this.amount,
    required this.expectedRepayment,
    required this.interest,
    required this.maturityDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.vest,
    this.user,
  });

  factory ActiveVest.fromJson(String source) =>
      ActiveVest.fromMap(json.decode(source));

  factory ActiveVest.fromMap(Map<String, dynamic> map) {
    return ActiveVest(
      id: map['id'] ?? 0,
      userId: map['user_id']?.toString() ?? '',
      vestId: map['vest_id']?.toString() ?? '',
      amount: map['amount']?.toString() ?? '',
      expectedRepayment: map['expected_repayment']?.toString() ?? '',
      interest: map['interest']?.toString() ?? '',
      maturityDate: map['maturity_date']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? '',
      updatedAt: map['updated_at']?.toString() ?? '',
      vest: map['vest'] != null ? Investment.fromMap(map['vest']) : null,
      user: map['user'] != null ? User.fromJson(map['user']) : null,
    );
  }
}