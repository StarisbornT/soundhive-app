import 'dart:convert';

class ChatSendModel {
  final String message;
  final ChatData data;

  ChatSendModel({
    required this.message,
    required this.data,
  });

  factory ChatSendModel.fromJson(String source) =>
      ChatSendModel.fromMap(json.decode(source));

  factory ChatSendModel.fromMap(Map<String, dynamic> map) {
    return ChatSendModel(
      message: map['message'] ?? '',
      data: ChatData.fromMap(map['data'] ?? {}),
    );
  }
}

class ChatData {
  final int id;
  final String senderId;
  final String receiverId;
  final String message;
  final String createdAt;
  final String updatedAt;
  final ChatUser sender;
  final ChatUser receiver;

  ChatData({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
    required this.sender,
    required this.receiver,
  });

  factory ChatData.fromMap(Map<String, dynamic> map) {
    return ChatData(
      id: map['id'] ?? 0,
      senderId: map['sender_id'] ?? '',
      receiverId: map['receiver_id'] ?? '',
      message: map['message'] ?? '',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'] ?? '',
      sender: ChatUser.fromMap(map['sender'] ?? {}),
      receiver: ChatUser.fromMap(map['receiver'] ?? {}),
    );
  }
}

class ChatUser {
  final String email;
  final String firstName;
  final String lastName;
  final String? gender;

  ChatUser({
    required this.email,
    required this.firstName,
    required this.lastName,
    this.gender,
  });

  factory ChatUser.fromMap(Map<String, dynamic> map) {
    return ChatUser(
      email: map['email'] ?? '',
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      gender: map['gender'],
    );
  }
}
