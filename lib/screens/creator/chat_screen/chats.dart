import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
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
  late Query _chatsQuery;

  @override
  void initState() {
    super.initState();
    // Query all chats
    _chatsQuery = _dbRef.child('chats').limitToLast(50);

    // Run migrations when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _migrateAllChats();
    });
  }

  // MIGRATION FUNCTION FOR CHAT LIST
  Future<void> _migrateAllChats() async {
    try {
      final snapshot = await _dbRef.child('chats').get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> chatsMap = snapshot.value as Map<dynamic, dynamic>;

        final updates = <String, dynamic>{};

        chatsMap.forEach((chatKey, chatValue) {
          if (chatValue is Map<dynamic, dynamic>) {
            final chatData = Map<String, dynamic>.from(chatValue);

            // Migration 1: Add lastMessage field if missing
            if (!chatData.containsKey('lastMessage') && chatData.containsKey('messages')) {
              final lastMessage = _getLastMessage(chatData);
              if (lastMessage != null) {
                updates['chats/$chatKey/lastMessage'] = lastMessage;
              }
            }

            // Migration 2: Fix participants if it's a List
            if (chatData['participants'] is List) {
              print('Fixing participants for chat $chatKey (was List)');
              // Extract participants from messages
              final participants = _getParticipants(chatData, chatKey.toString());
              if (participants != null) {
                updates['chats/$chatKey/participants'] = participants;
              }
            }

            // Migration 3: Fix lastRead if it's a List
            if (chatData['lastRead'] is List) {
              print('Fixing lastRead for chat $chatKey (was List)');
              updates['chats/$chatKey/lastRead'] = {};
            }
          }
        });

        if (updates.isNotEmpty) {
          await _dbRef.update(updates);
          print('Migrated ${updates.length} chats');
          // Refresh the list after migration
          setState(() {});
        }
      }
    } catch (e) {
      print('Error migrating chat data: $e');
    }
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
  Map<String, dynamic>? _getParticipants(Map<dynamic, dynamic> chatData, String chatKey) {
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

            if (senderId != null && senderName != null && !participantsMap.containsKey(senderId)) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FirebaseAnimatedList(
        query: _chatsQuery,
        itemBuilder: (context, snapshot, animation, index) {
          final chatKey = snapshot.key!;

          // Add debug logging
          print('Processing chat with key: $chatKey');
          print('Chat data: ${snapshot.value}');

          // Safe type checking for chatData
          dynamic chatDataValue = snapshot.value;
          Map<dynamic, dynamic> chatData = {};

          if (chatDataValue is Map<dynamic, dynamic>) {
            chatData = chatDataValue;
          } else {
            print('WARNING: Chat data is not a Map for key $chatKey, skipping');
            return const SizedBox();
          }

          // Check if this is a dispute chat
          final bool isDisputeChat = chatKey.startsWith('dispute_') ||
              (chatData['lastMessage'] != null &&
                  chatData['lastMessage']['disputeTitle'] != null);

          // Get last message from the messages collection
          final lastMessage = _getLastMessage(chatData);

          // Get participants information
          final participants = _getParticipants(chatData, chatKey);

          if (lastMessage == null || participants == null) {
            print('WARNING: Missing lastMessage or participants for chat $chatKey');
            return const SizedBox();
          }

          // For dispute chats, check if current user is a participant
          if (isDisputeChat) {
            final List<dynamic> disputeParticipants = lastMessage['participants'] is List
                ? lastMessage['participants'] as List<dynamic>
                : [];

            if (!disputeParticipants.contains(user?.id.toString())) {
              return const SizedBox(); // Skip if user is not a participant
            }
          }
          // For regular chats, check if this chat involves the current user using the chat ID format
          else {
            final userIds = chatKey.split('_');
            if (userIds.length < 2 || !userIds.contains(user?.id.toString())) {
              return const SizedBox();
            }
          }

          String displayName;
          String displayService = '';
          String otherUserId = '';
          String disputeId = '';

          // Extract dispute ID if this is a dispute chat
          if (isDisputeChat) {
            disputeId = chatKey.startsWith('dispute_')
                ? chatKey.replaceFirst('dispute_', '')
                : '';
            displayName = lastMessage['disputeTitle']?.toString() ?? 'Dispute Resolution';
            displayService = 'Dispute';
            otherUserId = lastMessage['senderId']?.toString() ?? '';
          } else {
            // Regular chat logic - extract user IDs from chat key
            final userIds = chatKey.split('_');
            final lastMessageSenderId = lastMessage['senderId']?.toString();
            final lastMessageReceiverId = lastMessage['receiverId']?.toString();

            // If current user sent the last message, show receiver's name
            if (lastMessageSenderId == user?.id.toString()) {
              displayName = lastMessage['customerName']?.toString() ?? 'Unknown User';
              displayService = lastMessage['serviceName']?.toString() ?? 'Unknown Service';
              otherUserId = lastMessageReceiverId ?? (userIds[0] == user?.id.toString() ? userIds[1] : userIds[0]);
            }
            // If current user received the last message, show sender's name
            else if (lastMessageReceiverId == user?.id.toString()) {
              displayName = lastMessage['customerName']?.toString() ?? 'Unknown User';
              displayService = lastMessage['serviceName']?.toString() ?? 'Unknown Service';
              otherUserId = lastMessageSenderId ?? (userIds[0] == user?.id.toString() ? userIds[1] : userIds[0]);
            }
            // Fallback: use participants data
            else {
              otherUserId = userIds[0] == user?.id.toString() ? userIds[1] : userIds[0];
              final otherUserData = participants[otherUserId];
              if (otherUserData is Map<dynamic, dynamic>) {
                displayName = '${otherUserData['firstName'] ?? ''} ${otherUserData['lastName'] ?? ''}'.trim();
                displayService = otherUserData['serviceName'] ?? 'User';
              } else {
                displayName = 'Unknown User';
                displayService = 'Unknown Service';
              }
            }
          }

          final lastMessageText = lastMessage['text']?.toString() ?? '';

          // Safe timestamp parsing
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

          // For now, set unread count to 0 since we don't have lastRead data
          int unreadCount = 0;

          return _ChatListItem(
            chatId: chatKey,
            userName: displayName,
            userService: displayService,
            lastMessage: lastMessageText,
            timestamp: lastMessageTime,
            unreadCount: unreadCount,
            isDispute: isDisputeChat,
            disputeId: disputeId,
            sellerId: isDisputeChat ? lastMessage['senderId']?.toString() ?? '' : otherUserId,
            sellerName: isDisputeChat ? lastMessage['senderName']?.toString() ?? '' : displayName,
            onTap: () {
              if (isDisputeChat) {
                // Navigate to dispute chat screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DisputeChatScreen(
                      sellerId: lastMessage['senderId']?.toString() ?? '',
                      sellerName: lastMessage['senderName']?.toString() ?? 'Unknown',
                      userId: user!.id.toString(),
                      senderName: "${user.firstName} ${user.lastName}",
                      disputeId: disputeId,
                    ),
                  ),
                );
              } else {
                // Navigate to regular chat screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      sellerId: user!.id.toString(),
                      sellerName: displayName,
                      sellerService: displayService,
                      receiverId: otherUserId,
                      senderName: displayName,
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
    final messageDay = DateTime(timestamp.year, timestamp.month, timestamp.day);

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
            backgroundColor: isDispute ? Colors.orange : const Color(0xFF4D3490),
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
          if (isDispute)
            const Icon(Icons.warning, color: Colors.orange, size: 16),
          if (isDispute)
            const SizedBox(width: 4),
          Expanded(
            child: Text(
              userName,
              style: TextStyle(
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        isDispute ? 'Dispute: $lastMessage' : lastMessage.isNotEmpty ? lastMessage : 'No messages yet',
        style: TextStyle(
          color: isDispute ? Colors.orange.withOpacity(0.8) : Colors.white.withOpacity(0.7),
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