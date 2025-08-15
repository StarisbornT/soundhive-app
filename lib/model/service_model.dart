import 'dart:convert';

class ServiceResponse {
  final bool status;
  final bool paginated;
  final List<ServiceItem> data;

  ServiceResponse({
    required this.status,
    required this.paginated,
    required this.data,
  });

  factory ServiceResponse.fromJson(String source) =>
      ServiceResponse.fromMap(json.decode(source));

  factory ServiceResponse.fromMap(Map<String, dynamic> map) {
    return ServiceResponse(
      status: map['status'] ?? false,
      paginated: map['paginated'] ?? false,
      data: List<ServiceItem>.from(
        map['data']?.map((x) => ServiceItem.fromMap(x)) ?? [],
      ),
    );
  }
}

class ServiceItem {
  final int id;
  final String memberId;
  final String status;
  final String serviceName;
  final String serviceAmount;
  final String serviceImage;
  final String servicePortfolioFormat;
  final String? servicePortfolioImage;
  final String? servicePortfolioLink;
  final String? servicePortfolioAudio;
  final String createdAt;
  final String updatedAt;

  ServiceItem({
    required this.id,
    required this.memberId,
    required this.status,
    required this.serviceName,
    required this.serviceAmount,
    required this.serviceImage,
    required this.servicePortfolioFormat,
    this.servicePortfolioImage,
    this.servicePortfolioLink,
    this.servicePortfolioAudio,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceItem.fromMap(Map<String, dynamic> map) {
    return ServiceItem(
      id: map['id'] ?? 0,
      memberId: map['member_id'] ?? '',
      status: map['status'] ?? '',
      serviceName: map['service_name'] ?? '',
      serviceAmount: map['service_amount'] ?? '',
      serviceImage: map['service_image'] ?? '',
      servicePortfolioFormat: map['service_portfolio_format'] ?? '',
      servicePortfolioImage: map['service_portfolio_image'],
      servicePortfolioLink: map['service_portfolio_link'],
      servicePortfolioAudio: map['service_portfolio_audio'],
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
    );
  }
}
