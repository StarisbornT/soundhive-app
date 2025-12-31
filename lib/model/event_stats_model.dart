import 'dart:convert';

class EventStatsModel {
  final bool status;
  final String message;
  final EventStatData data;

  EventStatsModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory EventStatsModel.fromJson(String source) =>
      EventStatsModel.fromMap(json.decode(source));

  factory EventStatsModel.fromMap(Map<String, dynamic> map) {
    return EventStatsModel(
      status: map['status'] ?? false,
      message: map['message'] ?? '',
      data: EventStatData.fromMap(map['data'] ?? {}),
    );
  }
}

class EventStatData {
  final Events events;

  EventStatData({
    required this.events,
  });

  factory EventStatData.fromMap(Map<String, dynamic> map) {
    return EventStatData(
      events: Events.fromMap(map['events'] ?? {}),
    );
  }
}

class Events {
  final int approved;
  final int pending;

  Events({
    required this.approved,
    required this.pending,
  });

  factory Events.fromMap(Map<String, dynamic> map) {
    return Events(
      approved: map['approved'] ?? 0,
      pending: map['pending'] ?? 0,
    );
  }
}
