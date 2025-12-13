import 'dart:convert';

import 'package:soundhive2/model/user_model.dart';

import 'creator_model.dart';

// Main response model for conversation threads
class ConversationThreadResponse {
  final bool success;
  final String message;
  final ConversationPaginatedData data;

  ConversationThreadResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ConversationThreadResponse.fromJson(String source) =>
      ConversationThreadResponse.fromMap(json.decode(source));

  factory ConversationThreadResponse.fromMap(Map<String, dynamic> json) {
    return ConversationThreadResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: ConversationPaginatedData.fromMap(json['data'] ?? {}),
    );
  }
}

// Paginated conversation data
class ConversationPaginatedData {
  final int currentPage;
  final List<AiChatConversation> data;
  final String? firstPageUrl;
  final int? from;
  final int lastPage;
  final String? lastPageUrl;
  final List<Link> links;
  final String? nextPageUrl;
  final String path;
  final int perPage;
  final String? prevPageUrl;
  final int? to;
  final int total;

  ConversationPaginatedData({
    required this.currentPage,
    required this.data,
    this.firstPageUrl,
    this.from,
    required this.lastPage,
    this.lastPageUrl,
    required this.links,
    this.nextPageUrl,
    required this.path,
    required this.perPage,
    this.prevPageUrl,
    this.to,
    required this.total,
  });

  factory ConversationPaginatedData.fromJson(String source) =>
      ConversationPaginatedData.fromMap(json.decode(source));

  factory ConversationPaginatedData.fromMap(Map<String, dynamic> json) {
    return ConversationPaginatedData(
      currentPage: json['current_page'] ?? 1,
      data: List<AiChatConversation>.from(
          (json['data'] ?? []).map((x) => AiChatConversation.fromMap(x))),
      firstPageUrl: json['first_page_url'],
      from: json['from'],
      lastPage: json['last_page'] ?? 1,
      lastPageUrl: json['last_page_url'],
      links: List<Link>.from((json['links'] ?? []).map((x) => Link.fromMap(x))),
      nextPageUrl: json['next_page_url'],
      path: json['path'] ?? '',
      perPage: json['per_page'] is String
          ? int.tryParse(json['per_page']) ?? 0
          : (json['per_page'] ?? 0),
      prevPageUrl: json['prev_page_url'],
      to: json['to'],
      total: json['total'] ?? 0,
    );
  }
}

// AI Chat Conversation model
class AiChatConversation {
  final int id;
  final String userId;
  final String? title;
  final String userMessage;
  final String aiResponse;
  final Map<String, dynamic> suggestedCreators;
  final Metadata metadata;
  final String apiCost;
  final String apiModel;
  final int tokensUsed;
  final bool isThreadStarter;
  final dynamic parentConversationId;
  final int threadPosition;
  final String createdAt;
  final String updatedAt;
  final int repliesCount;
  final List<CreatorData> creators;
  final User? user;

  AiChatConversation({
    required this.id,
    required this.userId,
    this.title,
    required this.userMessage,
    required this.aiResponse,
    required this.suggestedCreators,
    required this.metadata,
    required this.apiCost,
    required this.apiModel,
    required this.tokensUsed,
    required this.isThreadStarter,
    this.parentConversationId,
    required this.threadPosition,
    required this.createdAt,
    required this.updatedAt,
    required this.repliesCount,
    required this.creators,
    this.user
  });

  factory AiChatConversation.fromJson(Map<String, dynamic> json) =>
      AiChatConversation.fromMap(json);

  factory AiChatConversation.fromMap(Map<String, dynamic> json) {
    // Parse suggested_creators - could be map or empty array
    dynamic suggestedCreatorsData = json['suggested_creators'];
    Map<String, dynamic> suggestedCreators = {};

    if (suggestedCreatorsData is Map) {
      suggestedCreators = Map<String, dynamic>.from(suggestedCreatorsData);
    } else if (suggestedCreatorsData is List && suggestedCreatorsData.isNotEmpty) {
      // If it's a list, convert to map
      suggestedCreators = {'creators': suggestedCreatorsData};
    }

    return AiChatConversation(
      id: json['id'] ?? 0,
      userId: json['user_id']?.toString() ?? '',
      title: json['title'],
      userMessage: json['user_message'] ?? '',
      aiResponse: json['ai_response'] ?? '',
      suggestedCreators: suggestedCreators,
      metadata: Metadata.fromMap(json['metadata'] ?? {}),
      apiCost: json['api_cost']?.toString() ?? '0',
      apiModel: json['api_model'] ?? '',
      tokensUsed: json['tokens_used'] is String
          ? int.tryParse(json['tokens_used']) ?? 0
          : (json['tokens_used'] ?? 0),
      isThreadStarter: json['is_thread_starter'] ?? false,
      parentConversationId: json['parent_conversation_id'],
      threadPosition: json['thread_position'] is String
          ? int.tryParse(json['thread_position']) ?? 0
          : (json['thread_position'] ?? 0),
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      repliesCount: json['replies_count'] is String
          ? int.tryParse(json['replies_count']) ?? 0
          : (json['replies_count'] ?? 0),
      creators: json['creators'] != null
          ? List<CreatorData>.from(
          (json['creators'] as List).map((x) => CreatorData.fromJson(x)))
          : [],
      user: json['user'] != null
          ? User.fromJson(json['user'])
          : null,
    );
  }
}

// Metadata from AI response
class Metadata {
  final String timeline;
  final String costRange;
  final List<String> steps;

  Metadata({
    required this.timeline,
    required this.costRange,
    required this.steps,
  });

  factory Metadata.fromJson(Map<String, dynamic> json) => Metadata.fromMap(json);

  factory Metadata.fromMap(Map<String, dynamic> json) {
    // Handle steps which could be List<dynamic> or List<String>
    List<String> stepsList = [];
    if (json['steps'] != null) {
      final stepsData = json['steps'];
      if (stepsData is List) {
        stepsList = stepsData.map((step) => step.toString()).toList();
      }
    }

    return Metadata(
      timeline: json['timeline']?.toString() ?? '2-4 weeks',
      costRange: json['cost_range']?.toString() ?? 'Varies based on requirements',
      steps: stepsList,
    );
  }
}

// Link model for pagination (keep your existing Link model)
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

class ConversationSingleThreadResponse {
  final bool success;
  final String message;
  final ConversationPaginatedData data;
  final ThreadInfo? threadInfo;

  ConversationSingleThreadResponse({
    required this.success,
    required this.message,
    required this.data,
    this.threadInfo,
  });

  factory ConversationSingleThreadResponse.fromJson(String source) =>
      ConversationSingleThreadResponse.fromMap(json.decode(source));

  factory ConversationSingleThreadResponse.fromMap(Map<String, dynamic> json) {
    return ConversationSingleThreadResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: ConversationPaginatedData.fromMap(json['data'] ?? {}),
      threadInfo: json['thread_info'] != null
          ? ThreadInfo.fromMap(json['thread_info'])
          : null,
    );
  }
}

class ThreadInfo {
  final AiChatConversation? threadStarter;
  final int threadId;

  ThreadInfo({
    this.threadStarter,
    required this.threadId,
  });

  factory ThreadInfo.fromMap(Map<String, dynamic> json) {
    return ThreadInfo(
      threadStarter: json['thread_starter'] != null
          ? AiChatConversation.fromMap(json['thread_starter'])
          : null,
      threadId: json['thread_id'] ?? 0,
    );
  }
}