import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:soundhive2/model/user_model.dart';

import '../../chats/chat_screen.dart';
import '../../non_creator/disputes/dispute_chat_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  final MemberCreatorResponse user;

  const ChatListScreen({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  StreamSubscription<DatabaseEvent>? _userChatsSubscription;
  final Map<String, StreamSubscription<DatabaseEvent>> _chatSubscriptions = {};
  final Map<String, Map<dynamic, dynamic>> _chatsData = {};

  List<String> _chatIds = [];
  bool _isLoading = true;

  String? get _currentUserId => widget.user.user?.id.toString();

  @override
  void initState() {
    super.initState();
    _listenToUserChatsIndex();
  }

  @override
  void dispose() {
    _userChatsSubscription?.cancel();
    for (final sub in _chatSubscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }

  // Listen to this user's own chat index: userChats/{uid}/{chatId} = true
  // This is what the security rules actually allow us to read at scale
  // (we can never read the whole /chats collection).
  void _listenToUserChatsIndex() {
    final userId = _currentUserId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    _userChatsSubscription =
        _dbRef.child('userChats/$userId').onValue.listen((event) {
          final value = event.snapshot.value;
          final Set<String> newChatIds = {};

          if (value is Map<dynamic, dynamic>) {
            newChatIds.addAll(value.keys.map((k) => k.toString()));
          }
          print('=== ALL CHAT IDS FOR USER $userId: $newChatIds ===');

          // Stop listening to chats that dropped out of the index
          final removed = _chatSubscriptions.keys
              .where((id) => !newChatIds.contains(id))
              .toList();
          for (final id in removed) {
            _chatSubscriptions[id]?.cancel();
            _chatSubscriptions.remove(id);
            _chatsData.remove(id);
          }

          // Start listening to any newly indexed chats (live updates for
          // last message / previews)
          for (final chatId in newChatIds) {
            if (!_chatSubscriptions.containsKey(chatId)) {
              _chatSubscriptions[chatId] =
                  _dbRef.child('chats/$chatId').onValue.listen((chatEvent) {
                    final chatValue = chatEvent.snapshot.value;
                    if (chatValue is Map<dynamic, dynamic>) {
                      print('=== CHAT DATA [$chatId]: $chatValue ===');
                      if (mounted) {
                        setState(() {
                          _chatsData[chatId] = chatValue;
                        });
                      }
                    } else {
                      if (mounted) {
                        setState(() {
                          _chatsData.remove(chatId);
                        });
                      }
                    }
                  }, onError: (e) {
                    print('Error listening to chat $chatId: $e');
                  });
            }
          }

          if (mounted) {
            setState(() {
              _chatIds = newChatIds.toList();
              _isLoading = false;
            });
          }
        }, onError: (e) {
          print('Error listening to userChats index: $e');
          if (mounted) setState(() => _isLoading = false);
        });
  }

  // Helper function to extract the last message from a chat
  Map<String, dynamic>? _getLastMessage(Map<dynamic, dynamic> chatData) {
    try {
      final messages = chatData['messages'];
      if (messages is Map<dynamic, dynamic>) {
        final messagesMap = Map<String, dynamic>.from(messages);

        // Find the message with the latest timestamp
        String latestKey = '';
        DateTime latestTime = DateTime(0);

        messagesMap.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            final message = Map<String, dynamic>.from(value);
            final timestampStr = message['timestamp']?.toString();
            if (timestampStr != null && timestampStr.isNotEmpty) {
              try {
                final timestamp = DateTime.parse(timestampStr);
                if (timestamp.isAfter(latestTime)) {
                  latestTime = timestamp;
                  latestKey = key;
                }
              } catch (e) {
                print('Error parsing timestamp for message $key: $e');
              }
            }
          }
        });

        if (latestKey.isNotEmpty) {
          return messagesMap[latestKey] is Map<dynamic, dynamic>
              ? Map<String, dynamic>.from(messagesMap[latestKey])
              : null;
        }
      }
    } catch (e) {
      print('Error getting last message: $e');
    }
    return null;
  }

  // Helper function to extract participants from messages
  Map<String, dynamic>? _getParticipants(
      Map<dynamic, dynamic> chatData, String chatKey) {
    try {
      // First try to get participants from root level
      final participants = chatData['participants'];
      if (participants is Map<dynamic, dynamic>) {
        return Map<String, dynamic>.from(participants);
      }

      // If not found at root level, try to extract from messages
      final messages = chatData['messages'];
      if (messages is Map<dynamic, dynamic>) {
        final messagesMap = Map<String, dynamic>.from(messages);

        // Look for any message that might have participants info
        for (final message in messagesMap.values) {
          if (message is Map<dynamic, dynamic>) {
            final messageMap = Map<String, dynamic>.from(message);
            final participants = messageMap['participants'];
            if (participants is Map<dynamic, dynamic>) {
              return Map<String, dynamic>.from(participants);
            }
          }
        }

        // If no participants found in messages, try to extract from message senders
        final participantsMap = <String, dynamic>{};
        for (final message in messagesMap.values) {
          if (message is Map<dynamic, dynamic>) {
            final messageMap = Map<String, dynamic>.from(message);
            final senderId = messageMap['senderId']?.toString();
            final senderName = messageMap['senderName']?.toString();

            if (senderId != null &&
                senderName != null &&
                !participantsMap.containsKey(senderId)) {
              participantsMap[senderId] = {
                'firstName': senderName.split(' ').first,
                'lastName': senderName.split(' ').length > 1
                    ? senderName.split(' ').sublist(1).join(' ')
                    : '',
                'serviceName': 'User'
              };
            }
          }
        }

        if (participantsMap.isNotEmpty) {
          return participantsMap;
        }
      }
    } catch (e) {
      print('Error getting participants for chat $chatKey: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user.user;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Messages', style: TextStyle()),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Build display-ready entries from whatever chat data has loaded so far
    final List<_ChatEntry> displayEntries = [];

    for (final chatKey in _chatIds) {
      final chatDataValue = _chatsData[chatKey];
      if (chatDataValue == null) continue; // still loading this chat

      final Map<dynamic, dynamic> chatData = chatDataValue;

      final bool isDisputeChat = chatKey.startsWith('dispute_') ||
          (chatData['lastMessage'] != null &&
              chatData['lastMessage']['disputeTitle'] != null);

      final lastMessage = _getLastMessage(chatData);
      final participants = _getParticipants(chatData, chatKey);

      if (lastMessage == null || participants == null) {
        continue;
      }

      // For dispute chats, check if current user is a participant
      if (isDisputeChat) {
        final List<dynamic> disputeParticipants =
        lastMessage['participants'] is List
            ? lastMessage['participants'] as List<dynamic>
            : [];

        if (!disputeParticipants.contains(user?.id.toString())) {
          continue; // Skip if user is not a participant
        }
      } else {
        final userIds = chatKey.split('_');
        if (userIds.length < 2 || !userIds.contains(user?.id.toString())) {
          continue;
        }
      }

      String displayName;
      String displayService = '';
      String otherUserId = '';
      String disputeId = '';

      if (isDisputeChat) {
        disputeId = chatKey.startsWith('dispute_')
            ? chatKey.replaceFirst('dispute_', '')
            : '';
        displayName =
            lastMessage['disputeTitle']?.toString() ?? 'Dispute Resolution';
        displayService = 'Dispute';
        otherUserId = lastMessage['senderId']?.toString() ?? '';
      } else {
        final userIds = chatKey.split('_');
        final lastMessageSenderId = lastMessage['senderId']?.toString();
        final lastMessageReceiverId = lastMessage['receiverId']?.toString();

        if (lastMessageSenderId == user?.id.toString()) {
          displayName =
              lastMessage['customerName']?.toString() ?? 'Unknown User';
          displayService =
              lastMessage['serviceName']?.toString() ?? 'Unknown Service';
          otherUserId = lastMessageReceiverId ??
              (userIds[0] == user?.id.toString() ? userIds[1] : userIds[0]);
        } else if (lastMessageReceiverId == user?.id.toString()) {
          displayName =
              lastMessage['customerName']?.toString() ?? 'Unknown User';
          displayService =
              lastMessage['serviceName']?.toString() ?? 'Unknown Service';
          otherUserId = lastMessageSenderId ??
              (userIds[0] == user?.id.toString() ? userIds[1] : userIds[0]);
        } else {
          otherUserId =
          userIds[0] == user?.id.toString() ? userIds[1] : userIds[0];
          final otherUserData = participants[otherUserId];
          if (otherUserData is Map<dynamic, dynamic>) {
            displayName =
                '${otherUserData['firstName'] ?? ''} ${otherUserData['lastName'] ?? ''}'
                    .trim();
            displayService = otherUserData['serviceName'] ?? 'User';
          } else {
            displayName = 'Unknown User';
            displayService = 'Unknown Service';
          }
        }
      }

      final lastMessageText = lastMessage['text']?.toString() ?? '';

      DateTime lastMessageTime;
      try {
        final timestampString = lastMessage['timestamp']?.toString();
        if (timestampString != null && timestampString.isNotEmpty) {
          lastMessageTime = DateTime.parse(timestampString);
        } else {
          lastMessageTime = DateTime.now();
        }
      } catch (e) {
        print('Error parsing last message timestamp for chat $chatKey: $e');
        lastMessageTime = DateTime.now();
      }

      displayEntries.add(_ChatEntry(
        chatKey: chatKey,
        displayName: displayName,
        displayService: displayService,
        otherUserId: otherUserId,
        disputeId: disputeId,
        isDisputeChat: isDisputeChat,
        lastMessageText: lastMessageText,
        lastMessageTime: lastMessageTime,
        lastMessageSenderId: lastMessage['senderId']?.toString() ?? '',
        lastMessageSenderName: lastMessage['senderName']?.toString() ?? '',
      ));
    }

    // Most recent conversation first
    displayEntries.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    print('=== DISPLAY ENTRIES (${displayEntries.length} chats) ===');
    for (final e in displayEntries) {
      debugPrint(
        '  chatKey: ${e.chatKey} | name: ${e.displayName} | service: ${e.displayService} | '
            'last: "${e.lastMessageText}" | time: ${e.lastMessageTime} | isDispute: ${e.isDisputeChat}',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: displayEntries.isEmpty
          ? Center(
        child: Text(
          'No messages yet',
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
      )
          : ListView.builder(
        itemCount: displayEntries.length,
        itemBuilder: (context, index) {
          final entry = displayEntries[index];

          return _ChatListItem(
            chatId: entry.chatKey,
            userName: entry.displayName,
            userService: entry.displayService,
            lastMessage: entry.lastMessageText,
            timestamp: entry.lastMessageTime,
            unreadCount: 0,
            isDispute: entry.isDisputeChat,
            disputeId: entry.disputeId,
            sellerId: entry.isDisputeChat
                ? entry.lastMessageSenderId
                : entry.otherUserId,
            sellerName: entry.isDisputeChat
                ? entry.lastMessageSenderName
                : entry.displayName,
            onTap: () {
              if (entry.isDisputeChat) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DisputeChatScreen(
                      sellerId: entry.lastMessageSenderId,
                      sellerName: entry.lastMessageSenderName.isNotEmpty
                          ? entry.lastMessageSenderName
                          : 'Unknown',
                      userId: user!.id.toString(),
                      senderName:
                      "${user.firstName} ${user.lastName}",
                      disputeId: entry.disputeId,
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      sellerId: user!.id.toString(),
                      sellerName: entry.displayName,
                      sellerService: entry.displayService,
                      receiverId: entry.otherUserId,
                      senderName: entry.displayName,
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}

// Simple internal model to hold a fully-resolved chat list row
class _ChatEntry {
  final String chatKey;
  final String displayName;
  final String displayService;
  final String otherUserId;
  final String disputeId;
  final bool isDisputeChat;
  final String lastMessageText;
  final DateTime lastMessageTime;
  final String lastMessageSenderId;
  final String lastMessageSenderName;

  _ChatEntry({
    required this.chatKey,
    required this.displayName,
    required this.displayService,
    required this.otherUserId,
    required this.disputeId,
    required this.isDisputeChat,
    required this.lastMessageText,
    required this.lastMessageTime,
    required this.lastMessageSenderId,
    required this.lastMessageSenderName,
  });
}

class _ChatListItem extends StatelessWidget {
  final String chatId;
  final String userName;
  final String userService;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;
  final VoidCallback onTap;
  final bool isDispute;
  final String disputeId;
  final String sellerId;
  final String sellerName;

  const _ChatListItem({
    required this.chatId,
    required this.userName,
    required this.userService,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    required this.onTap,
    this.isDispute = false,
    this.disputeId = '',
    this.sellerId = '',
    this.sellerName = '',
  });

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDay =
    DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDay == today) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (messageDay == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor:
            isDispute ? Colors.orange : const Color(0xFF4D3490),
            child: Icon(
              isDispute ? Icons.warning : Icons.person,
              color: Colors.white,
              size: isDispute ? 20 : null,
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          if (isDispute) const Icon(Icons.warning, color: Colors.orange, size: 16),
          if (isDispute) const SizedBox(width: 4),
          Expanded(
            child: Text(
              userName,
              style: TextStyle(
                fontWeight:
                unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        isDispute
            ? 'Dispute: $lastMessage'
            : lastMessage.isNotEmpty
            ? lastMessage
            : 'No messages yet',
        style: TextStyle(
          color: isDispute
              ? Colors.orange.withOpacity(0.8)
              : Colors.white.withOpacity(0.7),
          overflow: TextOverflow.ellipsis,
          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
        ),
        maxLines: 1,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(timestamp),
            style: TextStyle(
              color: unreadCount > 0
                  ? const Color(0xFFA585F9)
                  : Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          if (unreadCount > 0)
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFFA585F9),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}