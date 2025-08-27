import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';

import '../screens/non_creator/chat_screen.dart';

class FirebaseChatService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  String _getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Stream<List<Message>> getMessagesStream(String currentUserId, String otherUserId) {
    final chatId = _getChatId(currentUserId, otherUserId);

    return _dbRef
        .child('chats/$chatId/messages')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return [];

      final Map<dynamic, dynamic> messagesMap =
      event.snapshot.value as Map<dynamic, dynamic>;

      return messagesMap.entries.map((entry) {
        return Message.fromMap(entry.value, entry.key);
      }).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });
  }

  Future<void> sendMessage(Message message) async {
    final chatId = _getChatId(message.senderId, message.receiverId);
    final messageRef = _dbRef.child('chats/$chatId/messages').push();

    await messageRef.set(message.toMap());
  }

  Future<List<FileData>> processFiles(List<File> files) async {
    final List<FileData> fileDataList = [];

    for (final file in files) {
      try {
        // Read file as bytes and encode as base64
        final bytes = await file.readAsBytes();
        final base64Data = base64Encode(bytes);

        // Determine file type
        final String type = _getFileType(file.path);

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