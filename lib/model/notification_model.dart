import 'dart:convert';

class NotificationModel {
  final bool success;
  final PaginatedNotifications data;

  NotificationModel({
    required this.success,
    required this.data,
  });

  factory NotificationModel.fromJson(String source) =>
      NotificationModel.fromMap(json.decode(source));

  factory NotificationModel.fromMap(Map<String, dynamic> json) {
    return NotificationModel(
      success: json['success'] ?? false,
      data: PaginatedNotifications.fromMap(json['data']),
    );
  }
}

class PaginatedNotifications {
  final int currentPage;
  final List<NotificationData> notifications;
  final String firstPageUrl;
  final int? from; // nullable
  final int lastPage;
  final String lastPageUrl;
  final List<PageLink> links;
  final String? nextPageUrl;
  final String path;
  final int perPage;
  final String? prevPageUrl;
  final int? to;   // nullable
  final int total;

  PaginatedNotifications({
    required this.currentPage,
    required this.notifications,
    required this.firstPageUrl,
    required this.from,
    required this.lastPage,
    required this.lastPageUrl,
    required this.links,
    required this.nextPageUrl,
    required this.path,
    required this.perPage,
    required this.prevPageUrl,
    required this.to,
    required this.total,
  });

  factory PaginatedNotifications.fromMap(Map<String, dynamic> json) {
    return PaginatedNotifications(
      currentPage: json['current_page'] ?? 1,
      notifications: List<NotificationData>.from(
        (json['data'] as List).map((e) => NotificationData.fromMap(e)),
      ),
      firstPageUrl: json['first_page_url'] ?? '',
      from: json['from'] != null ? int.tryParse(json['from'].toString()) : null,
      lastPage: json['last_page'] ?? 1,
      lastPageUrl: json['last_page_url'] ?? '',
      links: List<PageLink>.from(
        (json['links'] as List).map((e) => PageLink.fromMap(e)),
      ),
      nextPageUrl: json['next_page_url'],
      path: json['path'] ?? '',
      perPage: int.tryParse(json['per_page'].toString()) ?? 0,
      prevPageUrl: json['prev_page_url'],
      to: json['to'] != null ? int.tryParse(json['to'].toString()) : null,
      total: int.tryParse(json['total'].toString()) ?? 0,
    );
  }
}

class NotificationData {
  final int id;
  final String userId;
  final String title;
  final String message;
  final bool isRead;
  final String type;
  final dynamic data;
  final String createdAt;
  final String updatedAt;

  NotificationData({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.type,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationData.fromMap(Map<String, dynamic> json) {
    return NotificationData(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      message: json['message'],
      isRead: json['is_read'],
      type: json['type'],
      data: json['data'] is List
          ? List.from(json['data'])
          : Map<String, dynamic>.from(json['data'] ?? {}),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class PageLink {
  final String? url;
  final String label;
  final bool active;

  PageLink({
    required this.url,
    required this.label,
    required this.active,
  });

  factory PageLink.fromMap(Map<String, dynamic> json) {
    return PageLink(
      url: json['url'],
      label: json['label'],
      active: json['active'],
    );
  }
}

extension PaginatedNotificationsCopyWith on PaginatedNotifications {
  PaginatedNotifications copyWith({
    List<NotificationData>? notifications,
  }) {
    return PaginatedNotifications(
      currentPage: currentPage,
      notifications: notifications ?? this.notifications,
      firstPageUrl: firstPageUrl,
      from: from,
      lastPage: lastPage,
      lastPageUrl: lastPageUrl,
      links: links,
      nextPageUrl: nextPageUrl,
      path: path,
      perPage: perPage,
      prevPageUrl: prevPageUrl,
      to: to,
      total: total,
    );
  }
}

extension NotificationDataCopyWith on NotificationData {
  NotificationData copyWith({
    bool? isRead,
  }) {
    return NotificationData(
      id: id,
      userId: userId,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      type: type,
      data: data,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
