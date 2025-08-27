import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:soundhive2/utils/app_colors.dart';
import '../../../model/user_model.dart';

class Message {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final String receiverId;
  final DateTime timestamp;
  final List<FileData> files;
  final bool isSystem;
  final List<String> participants;

  Message({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.timestamp,
    this.files = const [],
    this.isSystem = false,
    required this.participants,
  });

  factory Message.fromMap(Map<dynamic, dynamic> map, String id) {
    return Message(
      id: id,
      text: map['text'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      receiverId: map['receiverId'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      files: List<FileData>.from((map['files'] ?? []).map((f) => FileData.fromMap(f))),
      isSystem: map['isSystem'] ?? false,
      participants: List<String>.from(map['participants'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'timestamp': timestamp.toIso8601String(),
      'files': files.map((f) => f.toMap()).toList(),
      'isSystem': isSystem,
      'participants': participants,
    };
  }
}

class FileData {
  final String name;
  final String type; // 'image', 'video', 'pdf', 'document'
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

class DisputeChatScreen extends ConsumerStatefulWidget {
  final String sellerId;
  final String disputeId;
  final String sellerName;
  final User user;

  const DisputeChatScreen({
    super.key,
    required this.sellerId,
    required this.disputeId,
    required this.user,
    required this.sellerName,
  });

  @override
  _DisputeChatScreenState createState() => _DisputeChatScreenState();
}

class _DisputeChatScreenState extends ConsumerState<DisputeChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<File> _pendingFiles = [];
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  late StreamSubscription<DatabaseEvent> _messageSubscription;
  final ScrollController _scrollController = ScrollController();
  String? adminId;

  String _getChatId(String disputeId) {
    return 'dispute_$disputeId';
  }

  List<Message> _messages = [];

  Future<Map<String, dynamic>> _getAdminDetails() async {
    try {
      final snapshot = await _dbRef.child('soundhive/admin').once();
      if (snapshot.snapshot.value != null) {
        return Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      }
      setState(() {
        adminId = "soundhive_admin";
      });
      return {'id': 'soundhive_admin', 'name': 'SoundHive Support'};
    } catch (e) {
      print('Error fetching admin details: $e');
      return {'id': 'soundhive_admin', 'name': 'SoundHive Support'};
    }
  }

  @override
  void initState() {
    super.initState();
    _getAdminDetails();
    _setupRealtimeListener();
    _loadInitialMessages();
  }

  @override
  void dispose() {
    _messageSubscription.cancel();
    _scrollController.dispose();
    super.dispose();
  }
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  void _setupRealtimeListener() {
    final chatId = _getChatId(widget.disputeId);

    _messageSubscription = _dbRef
        .child('chats/$chatId/messages')
        .orderByChild('timestamp')
        .onValue
        .listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> messagesMap =
        event.snapshot.value as Map<dynamic, dynamic>;

        final List<Message> messages = [];

        messagesMap.forEach((key, value) {
          messages.add(Message.fromMap(value, key));
        });

        // Sort by timestamp
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        setState(() {
          _messages = messages;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    }, onError: (error) {
      print('Error in message stream: $error');
    });
  }

  Future<void> _loadInitialMessages() async {
    // Add system message
    setState(() {
      _messages.insert(0, Message(
        id: 'system',
        text: "Do not mark this job as completed if your job has not been completed",
        senderId: 'system',
        senderName: 'System',
        receiverId: widget.user.id.toString(),
        timestamp: DateTime.now(),
        isSystem: true,
        participants: []
      ));
    });
  }


  Future<List<FileData>> _processFiles(List<File> files) async {
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

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty && _pendingFiles.isEmpty) return;

    final adminDetails = await _getAdminDetails();
    final adminId = adminDetails['id'];

    final chatId = _getChatId(widget.disputeId);
    final messageRef = _dbRef.child('chats/$chatId/messages').push();

    // Process files first
    List<FileData> fileData = [];
    if (_pendingFiles.isNotEmpty) {
      fileData = await _processFiles(_pendingFiles);
    }

    final message = Message(
      id: messageRef.key!,
      text: text,
      senderId: widget.user.id.toString(),
      senderName: widget.user.firstName,
      receiverId: '', // Not needed in group chat
      timestamp: DateTime.now(),
      files: fileData,
      participants: [widget.user.id.toString(), widget.sellerId, adminId],
    );

    try {
      await messageRef.set(message.toMap());
      _controller.clear();
      setState(() {
        _pendingFiles.clear();
      });
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  void _handleFilesSelected(List<File> files) {
    setState(() {
      _pendingFiles.addAll(files);
    });
  }

  void _removeFile(int index) {
    setState(() {
      _pendingFiles.removeAt(index);
    });
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '${hour}:${timestamp.minute.toString().padLeft(2, '0')} $period';
  }

  void _handleAttachment(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            color: AppColors.BACKGROUNDCOLOR,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.image, color: Colors.white),
                  title: const Text('Photo & Video', style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context);
                    final files = await ImagePicker().pickMultiImage();
                    if (files.isNotEmpty) {
                      _handleFilesSelected(files.map((f) => File(f.path)).toList());
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.insert_drive_file, color: Colors.white),
                  title: const Text('Document', style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await FilePicker.platform.pickFiles(
                      allowMultiple: true,
                    );
                    if (result != null) {
                      _handleFilesSelected(result.paths.map((p) => File(p!)).toList());
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.white),
                  title: const Text('Camera', style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context);
                    final file = await ImagePicker().pickImage(source: ImageSource.camera);
                    if (file != null) _handleFilesSelected([File(file.path)]);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF050110),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A191E),
        title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Dispute Resolution with ${widget.user.firstName}", style: const TextStyle(color: Colors.white, fontSize: 14)),
              ]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                if (message.isSystem) {
                  return _SystemMessage(message: message);
                }
                final isMe = message.senderId == widget.user.id.toString();
                final isAdmin = message.senderId == adminId;
                return _GroupChatBubble(
                  message: message,
                  isMe: isMe,
                  isAdmin: isAdmin,
                  formatTime: _formatTime,
                );
              },
            ),
          ),
          _MessageInput(
            controller: _controller,
            onSend: (text) {
              _sendMessage(text);
              // Scroll to bottom after sending a message
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });
            },
            onFilesSelected: _handleFilesSelected,
            onRemoveFile: _removeFile,
            pendingFiles: _pendingFiles,
            onAttachment: _handleAttachment,
          )
        ],
      ),
    );
  }
}

class _SystemMessage extends StatelessWidget {
  final Message message;

  const _SystemMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 271,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        width: 271,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 221, 118, 0.1),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning, color: Color(0xFFFFDD76), size: 12),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFFFDD76),
                    fontSize: 10
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupChatBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isAdmin;
  final String Function(DateTime) formatTime;

  const _GroupChatBubble({
    required this.message,
    required this.isMe,
    required this.isAdmin,
    required this.formatTime,
  });

  Widget _buildFilePreview(FileData fileData) {
    final bytes = base64Decode(fileData.base64Data);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: fileData.type == 'pdf'
            ? Container(
          width: 200,
          height: 200,
          color: Colors.grey[800],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf, size: 48, color: Colors.white),
              const Text('PDF Document', style: TextStyle(color: Colors.white)),
              Text(fileData.name, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        )
            : fileData.type == 'image'
            ? Image.memory(
          bytes,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
        )
            : Container(
          width: 200,
          height: 200,
          color: Colors.grey[800],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.insert_drive_file, size: 48, color: Colors.white),
                const Text('Download File', style: TextStyle(color: Colors.white)),
                Text(fileData.name, style: const TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isAdmin
              ? const Color(0xFF2A5C3F) // Different color for admin
              : isMe
              ? const Color(0xFF4D3490)
              : const Color(0xFF1A191E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Show sender name if not current user
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                child: Text(
                  isAdmin ? "SoundHive Support" : message.senderName,
                  style: TextStyle(
                    color: isAdmin ? Colors.green[200] : Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (message.files.isNotEmpty)
              ...message.files.map((file) => _buildFilePreview(file)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: const TextStyle(color: Colors.white),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    formatTime(message.timestamp),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final Function(List<File>) onFilesSelected;
  final Function(int) onRemoveFile;
  final Function(BuildContext) onAttachment;
  final List<File> pendingFiles;

  const _MessageInput({
    required this.controller,
    required this.onSend,
    required this.onFilesSelected,
    required this.onRemoveFile,
    required this.onAttachment,
    required this.pendingFiles,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          if (pendingFiles.isNotEmpty)
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: pendingFiles.length,
                itemBuilder: (context, index) {
                  final file = pendingFiles[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[800],
                          ),
                          child: file.path.toLowerCase().endsWith('.pdf')
                              ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.picture_as_pdf, color: Colors.white, size: 40),
                              Text('PDF', style: TextStyle(color: Colors.white)),
                            ],
                          )
                              : Image.file(file, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => onRemoveFile(index),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.white),
                    onPressed: () => onAttachment(context),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: pendingFiles.isEmpty
                            ? 'Type something'
                            : 'Add a caption',
                        hintStyle: const TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onSubmitted: onSend,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => onSend(controller.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}