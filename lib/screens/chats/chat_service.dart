import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

// Models
class Message {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final String receiverName;
  final String serviceName;
  final String receiverId;
  final DateTime timestamp;
  final String customerName;
  final List<FileData> files;
  final bool isSystem;
  final Map<String, bool> readBy;

  Message({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.serviceName,
    required this.customerName,
    required this.receiverName,
    required this.timestamp,
    this.files = const [],
    this.isSystem = false,
    this.readBy = const {},
  });

  factory Message.fromMap(Map<dynamic, dynamic> map, String id) {
    DateTime timestamp;
    try {
      final timestampString = map['timestamp']?.toString();
      if (timestampString != null && timestampString.isNotEmpty) {
        timestamp = DateTime.parse(timestampString);
      } else {
        timestamp = DateTime.now();
      }
    } catch (e) {
      print('Error parsing timestamp: $e, using current time as fallback');
      timestamp = DateTime.now();
    }

    Map<String, bool> readByMap = {};
    try {
      final readByValue = map['readBy'];
      if (readByValue != null) {
        if (readByValue is Map<dynamic, dynamic>) {
          readByMap = Map<String, bool>.from(readByValue.map(
                (key, value) => MapEntry(
              key.toString(),
              value?.toString() == 'true',
            ),
          ));
        } else if (readByValue is List) {
          for (int i = 0; i < readByValue.length; i++) {
            if (readByValue[i] != null) {
              readByMap[i.toString()] = readByValue[i]?.toString() == 'true';
            }
          }
        }
      }
    } catch (e) {
      print('Error parsing readBy field: $e');
      readByMap = {};
    }

    return Message(
      id: id,
      text: map['text']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      senderName: map['senderName']?.toString() ?? '',
      receiverName: map['receiverName']?.toString() ?? '',
      receiverId: map['receiverId']?.toString() ?? '',
      serviceName: map['serviceName']?.toString() ?? '',
      customerName: map['customerName']?.toString() ?? '',
      timestamp: timestamp,
      files: List<FileData>.from((map['files'] ?? []).map((f) => FileData.fromMap(f))),
      isSystem: map['isSystem']?.toString() == 'true' || false,
      readBy: readByMap,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'receiverName': receiverName,
      'serviceName': serviceName,
      'receiverId': receiverId,
      'customerName': customerName,
      'timestamp': timestamp.toIso8601String(),
      'files': files.map((f) => f.toMap()).toList(),
      'isSystem': isSystem,
      'readBy': readBy,
    };
  }
}

class FileData {
  final String name;
  final String type;
  final String base64Data;
  final int size;

  FileData({
    required this.name,
    required this.type,
    required this.base64Data,
    required this.size,
  });

  factory FileData.fromMap(Map<dynamic, dynamic> map) {
    return FileData(
      name: map['name'],
      type: map['type'],
      base64Data: map['base64Data'],
      size: map['size'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'base64Data': base64Data,
      'size': size,
    };
  }
}

// Chat Service
class ChatService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  String getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Stream<List<Message>> getMessagesStream(String userId1, String userId2) {
    final chatId = getChatId(userId1, userId2);

    return _dbRef
        .child('chats/$chatId/messages')
        .orderByChild('timestamp')
        .onValue
        .asyncMap((DatabaseEvent event) {
      if (event.snapshot.value == null) return [];

      final Map<dynamic, dynamic> messagesMap = event.snapshot.value as Map<dynamic, dynamic>;
      final List<Message> messages = [];

      messagesMap.forEach((key, value) {
        try {
          messages.add(Message.fromMap(value, key.toString()));
        } catch (e, stackTrace) {
          print('Error parsing message with key $key: $e');
          print('Stack trace: $stackTrace');

          messages.add(Message(
            id: key.toString(),
            text: 'Error loading message',
            senderId: 'system',
            senderName: 'System',
            customerName: 'System',
            receiverName: 'System',
            serviceName: 'System',
            receiverId: userId1,
            timestamp: DateTime.now(),
            isSystem: true,
          ));
        }
      });

      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  Future<void> sendMessage({
    required String text,
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required String serviceName,
    required String customerName,
    List<File>? files,
  }) async {
    if (text.isEmpty && (files == null || files.isEmpty)) return;

    final chatId = getChatId(senderId, receiverId);
    final messageRef = _dbRef.child('chats/$chatId/messages').push();

    List<FileData> fileData = [];
    if (files != null && files.isNotEmpty) {
      fileData = await _processFiles(files);
    }

    final message = Message(
      id: messageRef.key!,
      text: text,
      senderId: senderId,
      senderName: senderName,
      receiverName: receiverName,
      serviceName: serviceName,
      customerName: customerName,
      receiverId: receiverId,
      timestamp: DateTime.now(),
      files: fileData,
    );

    try {
      await messageRef.set(message.toMap());
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Failed to send message');
    }
  }

  Future<void> markMessagesAsRead({
    required String currentUserId,
    required String otherUserId,
    required List<Message> messages,
  }) async {
    final chatId = getChatId(currentUserId, otherUserId);

    for (final message in messages) {
      if (message.senderId != currentUserId && !message.readBy.containsKey(currentUserId)) {
        await _dbRef.child('chats/$chatId/messages/${message.id}/readBy/$currentUserId').set(true);
      }
    }

    await _dbRef.child('chats/$chatId/lastRead/$currentUserId').set(DateTime.now().toIso8601String());
  }

  Future<void> migrateOldMessages(String userId1, String userId2) async {
    final chatId = getChatId(userId1, userId2);

    try {
      final snapshot = await _dbRef.child('chats/$chatId/messages').get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> messagesMap = snapshot.value as Map<dynamic, dynamic>;
        final updates = <String, dynamic>{};

        messagesMap.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            final messageData = Map<String, dynamic>.from(value);

            if (key == 'system') {
              updates['chats/$chatId/messages/$key'] = null;
              return;
            }

            if (messageData['timestamp'] == null || messageData['timestamp'].toString().isEmpty) {
              updates['chats/$chatId/messages/$key/timestamp'] = DateTime.now().toIso8601String();
            }
          }
        });

        if (updates.isNotEmpty) {
          await _dbRef.update(updates);
          print('Migrated ${updates.length} messages with missing timestamps');
        }
      }
    } catch (e) {
      print('Error migrating messages: $e');
    }
  }

  Future<void> migrateReadByFields(String userId1, String userId2) async {
    final chatId = getChatId(userId1, userId2);

    try {
      final snapshot = await _dbRef.child('chats/$chatId/messages').get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> messagesMap = snapshot.value as Map<dynamic, dynamic>;
        final updates = <String, dynamic>{};

        messagesMap.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            final messageData = Map<String, dynamic>.from(value);

            if (messageData['readBy'] is List) {
              final List<dynamic> readByList = messageData['readBy'] as List<dynamic>;
              final Map<String, bool> readByMap = {};

              for (int i = 0; i < readByList.length; i++) {
                if (readByList[i] != null) {
                  readByMap[i.toString()] = readByList[i]?.toString() == 'true';
                }
              }

              updates['chats/$chatId/messages/$key/readBy'] = readByMap;
            }
          }
        });

        if (updates.isNotEmpty) {
          await _dbRef.update(updates);
          print('Migrated ${updates.length} messages with incorrect readBy format');
        }
      }
    } catch (e) {
      print('Error migrating readBy fields: $e');
    }
  }

  Future<List<FileData>> _processFiles(List<File> files) async {
    final List<FileData> fileDataList = [];

    for (final file in files) {
      try {
        final bytes = await file.readAsBytes();
        final base64Data = base64Encode(bytes);
        final type = _getFileType(file.path);

        fileDataList.add(FileData(
          name: file.path.split('/').last,
          type: type,
          base64Data: base64Data,
          size: bytes.length,
        ));
      } catch (e) {
        print('Error processing file: $e');
      }
    }

    return fileDataList;
  }

  String _getFileType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;

    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      return 'image';
    } else if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
      return 'video';
    } else if (extension == 'pdf') {
      return 'pdf';
    } else {
      return 'document';
    }
  }
}

// File Picker Service
class FilePickerService {
  final ImagePicker _imagePicker = ImagePicker();

  Future<List<File>> pickImages() async {
    final files = await _imagePicker.pickMultiImage();
    return files.map((f) => File(f.path)).toList();
  }

  Future<List<File>> pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      return result.paths.map((p) => File(p!)).toList();
    }
    return [];
  }

  Future<File?> takePhoto() async {
    final file = await _imagePicker.pickImage(source: ImageSource.camera);
    return file != null ? File(file.path) : null;
  }
}

// Provider
final chatServiceProvider = Provider<ChatService>((ref) => ChatService());
final filePickerServiceProvider = Provider<FilePickerService>((ref) => FilePickerService());