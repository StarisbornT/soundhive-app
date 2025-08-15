import 'dart:convert';
class ChatResponse {
  final String message;
  final List<ChatData> data;

  ChatResponse({required this.message, required this.data});

  factory ChatResponse.fromJson(Map<String, dynamic> json) => ChatResponse(
    message: json['message'],
    data: List<ChatData>.from(
        json['data'].map((x) => ChatData.fromMap(x))),
  );
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
      id: map['id'] as int,
      senderId: map['sender_id'] as String,
      receiverId: map['receiver_id'] as String,
      message: map['message'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      sender: ChatUser.fromMap(map['sender'] as Map<String, dynamic>),
      receiver: ChatUser.fromMap(map['receiver'] as Map<String, dynamic>),
    );
  }
}

class ChatUser {
  final String email;
  final String firstName;
  final String lastName;

  ChatUser({
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  factory ChatUser.fromMap(Map<String, dynamic> map) {
    return ChatUser(
      email: map['email'] as String,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
    );
  }
}