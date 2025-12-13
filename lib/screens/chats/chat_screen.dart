
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:soundhive2/utils/app_colors.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';

import 'package:soundhive2/lib/dashboard_provider/call_provider.dart';
import 'package:soundhive2/lib/provider.dart';
import 'call_screen.dart';

// Update your Message class
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
    // Handle timestamp with proper null checking
    DateTime timestamp;
    try {
      final timestampString = map['timestamp']?.toString();
      if (timestampString != null && timestampString.isNotEmpty) {
        timestamp = DateTime.parse(timestampString);
      } else {
        timestamp = DateTime.now(); // Fallback to current time
      }
    } catch (e) {
      print('Error parsing timestamp: $e, using current time as fallback');
      timestamp = DateTime.now(); // Fallback to current time
    }

    // Handle readBy field - it might be a List or a Map
    Map<String, bool> readByMap = {};
    try {
      final readByValue = map['readBy'];
      if (readByValue != null) {
        if (readByValue is Map<dynamic, dynamic>) {
          // Handle Map format: {"userId": true}
          readByMap = Map<String, bool>.from(readByValue.map(
                (key, value) => MapEntry(
              key.toString(),
              value?.toString() == 'true',
            ),
          ));
        } else if (readByValue is List) {
          // Handle List format: [null, true] - convert to Map
          // This is a workaround for the incorrect data format
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
      'readBy': readBy, // This will ensure correct Map format
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

class ChatScreen extends ConsumerStatefulWidget {
  final String sellerId;
  final String sellerName;
  final String sellerService;
  final String senderName;
  final String receiverId;

  const ChatScreen({
    super.key,
    required this.sellerId,
    required this.receiverId,
    required this.sellerName,
    required this.senderName,
    required this.sellerService
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<File> _pendingFiles = [];
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  late StreamSubscription<DatabaseEvent> _messageSubscription;
  final ScrollController _scrollController = ScrollController();
  bool _isCallActive = false;

  late StreamSubscription<DatabaseEvent> _callSubscription;
  List<Message> _messages = [];
  bool _isLoading = true;

  Future<void> _markMessagesAsRead() async {
    final currentUser = ref.read(userProvider).value?.user;
    if (currentUser == null) return;

    final userId = currentUser.id.toString();

    // Determine the other user ID
    final otherUserId = userId == widget.sellerId
        ? widget.receiverId  // Current user is seller, so other user is receiver
        : widget.sellerId;   // Current user is buyer, so other user is seller

    final chatId = _getChatId(userId, otherUserId);

    // Update each message's readBy field with correct Map format
    for (final message in _messages) {
      if (message.senderId != userId && !message.readBy.containsKey(userId)) {
        // Use correct Map format: {"userId": true}
        await _dbRef.child('chats/$chatId/messages/${message.id}/readBy/$userId').set(true);
      }
    }

    // Update the last read timestamp for this user
    await _dbRef.child('chats/$chatId/lastRead/$userId').set(DateTime.now().toIso8601String());
  }

  Future<void> _migrateOldMessages() async {
    final currentUser = ref.read(userProvider).value?.user;
    if (currentUser == null) return;

    final userId = currentUser.id.toString();

    // Determine the other user ID
    final otherUserId = userId == widget.sellerId
        ? widget.receiverId
        : widget.sellerId;

    final chatId = _getChatId(userId, otherUserId);

    try {
      final snapshot = await _dbRef.child('chats/$chatId/messages').get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> messagesMap =
        snapshot.value as Map<dynamic, dynamic>;

        final updates = <String, dynamic>{};

        messagesMap.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            final messageData = Map<String, dynamic>.from(value);

            print("Key $key, Value $value");

            // Skip system messages - they have different structure
            if (key == 'system') {
              // Delete system messages from database since they shouldn't be stored
              updates['chats/$chatId/messages/$key'] = null;
              return;
            }

            // Check if timestamp is missing or invalid
            if (messageData['timestamp'] == null ||
                messageData['timestamp'].toString().isEmpty) {

              // Create a fallback timestamp (current time)
              updates['chats/$chatId/messages/$key/timestamp'] =
                  DateTime.now().toIso8601String();
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

  Future<void> _migrateReadByFields() async {
    final currentUser = ref.read(userProvider).value?.user;
    if (currentUser == null) return;

    final userId = currentUser.id.toString();

    // Determine the other user ID
    final otherUserId = userId == widget.sellerId
        ? widget.receiverId
        : widget.sellerId;

    final chatId = _getChatId(userId, otherUserId);

    try {
      final snapshot = await _dbRef.child('chats/$chatId/messages').get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> messagesMap =
        snapshot.value as Map<dynamic, dynamic>;

        final updates = <String, dynamic>{};

        messagesMap.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            final messageData = Map<String, dynamic>.from(value);

            // Check if readBy is a List instead of a Map
            if (messageData['readBy'] is List) {
              final List<dynamic> readByList = messageData['readBy'] as List<dynamic>;

              // Convert List format to Map format
              final Map<String, bool> readByMap = {};
              for (int i = 0; i < readByList.length; i++) {
                if (readByList[i] != null) {
                  readByMap[i.toString()] = readByList[i]?.toString() == 'true';
                }
              }

              // Add to updates
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

  @override
  void initState() {
    super.initState();
    _setupRealtimeListener();
    _loadInitialMessages();
    _setupCallListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
      _migrateOldMessages();
      _migrateReadByFields();
    });
  }

  @override
  void dispose() {
    _messageSubscription.cancel();
    _callSubscription.cancel();
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
  void _setupCallListener() {
    final currentUser = ref.read(userProvider).value?.user;
    if (currentUser == null) return;

    final userId = currentUser.id.toString();
    final otherUserId = userId == widget.sellerId ? widget.receiverId : widget.sellerId;
    final chatId = _getChatId(userId, otherUserId);

    _callSubscription = _dbRef
        .child('calls/$chatId')
        .onValue
        .listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        final callData = event.snapshot.value as Map<dynamic, dynamic>;
        _handleIncomingCall(callData, userId);
      }
    });
  }

  void _handleIncomingCall(Map<dynamic, dynamic> callData, String userId) {
    final callStatus = callData['status']?.toString();
    final callerId = callData['callerId']?.toString();
    final channelName = callData['channelName']?.toString();

    if (callStatus == 'calling' && callerId != userId) {
      // Show incoming call dialog
      _showIncomingCallDialog(callData);
    } else if (callStatus == 'ended') {
      // End call if active
      if (_isCallActive) {
        ref.read(audioCallProvider.notifier).endCall();
        _isCallActive = false;
      }
    }
  }

  void _showIncomingCallDialog(Map<dynamic, dynamic> callData) {
    final callerName = callData['callerName']?.toString() ?? 'Unknown';
    final channelName = callData['channelName']?.toString() ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.BACKGROUNDCOLOR,
        title: const Text('Incoming Audio Call', style: TextStyle(color: Colors.white)),
        content: Text('$callerName is calling you...', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectCall();
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptCall(channelName);
            },
            child: const Text('Accept', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Future<void> _startCall(WidgetRef ref) async {
    final currentUser = ref.read(userProvider).value?.user;
    if (currentUser == null) return;

    final userId = currentUser.id.toString();
    final otherUserId = userId == widget.sellerId ? widget.receiverId : widget.sellerId;
    final chatId = _getChatId(userId, otherUserId);
    final channelName = 'audio_call_${DateTime.now().millisecondsSinceEpoch}';

    try {
      // 1. Create call in Firebase (for real-time sync)
      await _dbRef.child('calls/$chatId').set({
        'callerId': userId,
        'callerName': "${currentUser.firstName} ${currentUser.lastName}".trim(),
        'channelName': channelName,
        'status': 'calling',
        'timestamp': DateTime.now().toIso8601String(),
      });

      // 2. Send push notification via Laravel (for offline users)
      await _sendCallNotification(ref, otherUserId, channelName);

      // 3. Start the local call
      await ref.read(audioCallProvider.notifier).startCall(channelName, int.parse(userId));

      // 4. Show call screen
      _showCallScreen(ref);

    } catch (e) {
      debugPrint("Failed to start call: $e");

      // FIX: Check if context is mounted before showing SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start call')),
        );
      }
    }
  }

  // Add this method to your ChatScreen
  Future<void> _sendCallNotification(WidgetRef ref, String receiverId, String channelName) async {
    final currentUser = ref.read(userProvider).value?.user;
    final dio = ref.read(dioProvider);

    if (currentUser == null) return;

    try {
      final response = await dio.post(
        '/calls/notify-incoming',
        data: {
          'receiver_id': int.parse(receiverId),
          'caller_name': "${currentUser.firstName} ${currentUser.lastName}".trim(),
          'channel_name': channelName,
          'call_id': 'call_${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      if (response.statusCode == 200) {
        print('Call notification sent successfully');
      } else {
        print('Failed to send call notification: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending call notification: $e');
      // Don't throw error - call should continue even if notification fails
    }
  }

  void _showCallScreen(WidgetRef ref) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => Consumer(
          builder: (context, ref, child) {
            return AudioCallScreen(
              onEndCall: () {
                Navigator.pop(context);
                _endCall();
              },
            );
          },
        ),
      ),
    ).then((_) {
      _endCall();
    });
  }


  Future<void> _acceptCall(String channelName) async {
    final currentUser = ref.read(userProvider).value?.user;
    if (currentUser == null) return;

    final userId = currentUser.id.toString();
    final otherUserId = userId == widget.sellerId ? widget.receiverId : widget.sellerId;
    final chatId = _getChatId(userId, otherUserId);

    // Update call status
    await _dbRef.child('calls/$chatId/status').set('connected');

    // Join the call
    ref.read(audioCallProvider.notifier).joinCall(channelName, int.parse(userId));
    _isCallActive = true;

    // Show call screen
    _showCallScreen(ref);
  }

  Future<void> _rejectCall() async {
    final currentUser = ref.read(userProvider).value?.user;
    if (currentUser == null) return;

    final userId = currentUser.id.toString();
    final otherUserId = userId == widget.sellerId ? widget.receiverId : widget.sellerId;
    final chatId = _getChatId(userId, otherUserId);

    // End the call
    await _dbRef.child('calls/$chatId/status').set('ended');
  }

  Future<void> _endCall() async {
    final currentUser = ref.read(userProvider).value?.user;
    if (currentUser == null) return;

    final userId = currentUser.id.toString();
    final otherUserId = userId == widget.sellerId ? widget.receiverId : widget.sellerId;
    final chatId = _getChatId(userId, otherUserId);

    // End call in database
    await _dbRef.child('calls/$chatId/status').set('ended');

    // End call locally
    ref.read(audioCallProvider.notifier).endCall();
    _isCallActive = false;
  }
  void _setupRealtimeListener() {
    final currentUser = ref.read(userProvider).value?.user;
    if (currentUser == null) return;

    final userId = currentUser.id.toString();

    // Determine the other user ID
    final otherUserId = userId == widget.sellerId
        ? widget.receiverId
        : widget.sellerId;

    final chatId = _getChatId(userId, otherUserId);

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
          try {
            // Add detailed error logging
            print('Processing message with key: $key');
            print('Message data: $value');

            messages.add(Message.fromMap(value, key.toString()));
          } catch (e, stackTrace) {
            print('Error parsing message with key $key: $e');
            print('Stack trace: $stackTrace');
            print('Problematic message data: $value');

            // Create a fallback message instead of crashing
            messages.add(Message(
              id: key.toString(),
              text: 'Error loading message',
              senderId: 'system',
              senderName: 'System',
              customerName: 'System',
              receiverName: 'System',
              serviceName: 'System',
              receiverId: userId,
              timestamp: DateTime.now(),
              isSystem: true,
            ));
          }
        });

        // Sort by timestamp
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _markMessagesAsRead();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } else {
        setState(() => _isLoading = false);
      }
    }, onError: (error) {
      print('Error in message stream: $error');
      setState(() => _isLoading = false);
    });
  }

  Future<void> _loadInitialMessages() async {
    // REMOVE THIS: Don't add system message to _messages list
    // We'll handle system message display in the UI instead
    setState(() {
      _isLoading = false;
    });
  }

  String _getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
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

    final currentUser = ref.read(userProvider).value?.user;
    if (currentUser == null) return;

    final userId = currentUser.id.toString();

    // Determine the receiver ID - if current user is seller, receiver is the other user
    // If current user is buyer, receiver is the seller
    final receiverId = userId == widget.sellerId
        ? widget.receiverId  // Current user is seller, so receiver is the other user
        : widget.sellerId;   // Current user is buyer, so receiver is the seller

    final chatId = _getChatId(userId, receiverId);
    final messageRef = _dbRef.child('chats/$chatId/messages').push();

    // Process files first
    List<FileData> fileData = [];
    if (_pendingFiles.isNotEmpty) {
      fileData = await _processFiles(_pendingFiles);
    }

    final customerName = userId == widget.sellerId
        ? widget.sellerName // Current user is seller, so customer is the sender
        : widget.senderName;

    final message = Message(
      id: messageRef.key!,
      text: text,
      senderId: userId,
      senderName: "${currentUser.firstName} ${currentUser.lastName}".trim(),
      receiverName: userId == widget.sellerId ? widget.senderName : widget.sellerName,
      serviceName: widget.sellerService,
      customerName: customerName,
      receiverId: receiverId,  // Use the calculated receiverId
      timestamp: DateTime.now(),
      files: fileData,
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
    return '$hour:${timestamp.minute.toString().padLeft(2, '0')} $period';
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
    final currentUser = ref.watch(userProvider).value?.user;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('User not found')));
    }

    final currentUserId = currentUser.id.toString();
    final shouldShowSystemMessage = _messages.isEmpty && !_isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF050110),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A191E),
        title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.sellerName, style: const TextStyle(color: Colors.white, fontSize: 14)),
              Text(widget.sellerService,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70)),
            ]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.white),
            onPressed: () => _startCall(ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                if (shouldShowSystemMessage && index == 0) {
                  return _SystemMessage(
                    message: Message(
                      id: 'system',
                      text: "Do not mark this job as completed if your job has not been completed",
                      senderId: 'system',
                      senderName: 'System',
                      serviceName: 'System',
                      customerName: 'System',
                      receiverName: 'System',
                      receiverId: '',
                      timestamp: DateTime.now(),
                      isSystem: true,
                    ),
                  );
                }

                // Adjust index for real messages
                final messageIndex = shouldShowSystemMessage ? index - 1 : index;
                final message = _messages[messageIndex];

                if (message.isSystem) {
                  return _SystemMessage(message: message);
                }


                final isMe = message.senderId == currentUserId;

                return _ChatBubble(
                  message: message,
                  isMe: isMe,
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

class _ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final String Function(DateTime) formatTime;

  const _ChatBubble({
    required this.message,
    required this.isMe,
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
          color: isMe ? const Color(0xFF4D3490) : const Color(0xFF1A191E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
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