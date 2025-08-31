import 'dart:convert';

class InvestmentResponse {
  final bool status;
  final PaginatedData data;

  InvestmentResponse({
    required this.status,
    required this.data,
  });

  factory InvestmentResponse.fromJson(String source) =>
      InvestmentResponse.fromMap(json.decode(source));

  factory InvestmentResponse.fromMap(Map<String, dynamic> map) {
    return InvestmentResponse(
      status: map['status'] ?? false,
      data: PaginatedData.fromMap(map['data'] ?? {}),
    );
  }
}

class PaginatedData {
  final int currentPage;
  final List<Investment> data;
  final String? firstPageUrl;
  final int from;
  final int lastPage;
  final String? lastPageUrl;
  final List<Link> links;
  final String? nextPageUrl;
  final String path;
  final int perPage;
  final String? prevPageUrl;
  final int to;
  final int total;

  PaginatedData({
    required this.currentPage,
    required this.data,
    this.firstPageUrl,
    required this.from,
    required this.lastPage,
    this.lastPageUrl,
    required this.links,
    this.nextPageUrl,
    required this.path,
    required this.perPage,
    this.prevPageUrl,
    required this.to,
    required this.total,
  });

  factory PaginatedData.fromMap(Map<String, dynamic> map) {
    return PaginatedData(
      currentPage: map['current_page'] ?? 1,
      data: List<Investment>.from(
        (map['data'] ?? []).map((x) => Investment.fromMap(x)),
      ),
      firstPageUrl: map['first_page_url'],
      from: map['from'] ?? 0,
      lastPage: map['last_page'] ?? 0,
      lastPageUrl: map['last_page_url'],
      links: List<Link>.from(
        (map['links'] ?? []).map((x) => Link.fromMap(x)),
      ),
      nextPageUrl: map['next_page_url'],
      path: map['path'] ?? '',
      perPage: map['per_page'] is String
          ? int.tryParse(map['per_page']) ?? 0
          : (map['per_page'] ?? 0),
      prevPageUrl: map['prev_page_url'],
      to: map['to'] ?? 0,
      total: map['total'] ?? 0,
    );
  }
}

class Investment {
  final int id;
  final String vestFor;
  final String beneficiaryName;
  final String investmentName;
  final String minimumAmount;
  final String roi;
  final String duration;
  final String description;
  final List<String> images;
  final String riskAssessment;
  final List<String> news;
  final String status;
  final String createdAt;
  final String updatedAt;

  Investment({
    required this.id,
    required this.vestFor,
    required this.beneficiaryName,
    required this.investmentName,
    required this.minimumAmount,
    required this.roi,
    required this.duration,
    required this.description,
    required this.images,
    required this.riskAssessment,
    required this.news,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Investment.fromMap(Map<String, dynamic> map) {
    return Investment(
      id: map['id'] ?? 0,
      vestFor: map['vest_for'] ?? '',
      beneficiaryName: map['beneficiary_name'] ?? '',
      investmentName: map['investment_name'] ?? '',
      minimumAmount: map['minimum_amount'] ?? '',
      roi: map['roi'] ?? '',
      duration: map['duration'] ?? '',
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      riskAssessment: map['risk_assessment'] ?? '',
      news: List<String>.from(map['news'] ?? []),
      status: map['status'] ?? '',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
    );
  }
}

class Link {
  final String? url;
  final String label;
  final bool active;

  Link({
    this.url,
    required this.label,
    required this.active,
  });

  factory Link.fromMap(Map<String, dynamic> map) {
    return Link(
      url: map['url'],
      label: map['label'] ?? '',
      active: map['active'] ?? false,
    );
  }
}
