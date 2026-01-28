import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/screens/non_creator/ai/ai_chat_screen.dart';
import 'package:soundhive2/lib/dashboard_provider/get_conversations_provider.dart';
import '../../../model/ai_conversation_thread_model.dart';

class AiChatConversationScreen extends ConsumerStatefulWidget {
  const AiChatConversationScreen({super.key});

  @override
  ConsumerState<AiChatConversationScreen> createState() => _AiChatConversationScreenState();
}

class _AiChatConversationScreenState extends ConsumerState<AiChatConversationScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load conversations when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(getConversationProvider.notifier).getConversations();
    });

    _searchController.addListener(_onSearchChanged);

    // Setup infinite scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      final searchQuery = _searchController.text.trim();
      if (searchQuery.isEmpty) {
        // If search is cleared, load without search
        ref.read(getConversationProvider.notifier).getConversations(page: 1);
      } else {
        // Perform search
        ref.read(getConversationProvider.notifier).searchConversations(searchQuery);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // Load more data when reaching the bottom
      ref.read(getConversationProvider.notifier).loadNextPage();
    }
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      // Format date
      if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return '${months}mo ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  void _openConversation(AiChatConversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiChatScreen(
          threadId: conversation.id,
          initialTitle: conversation.title,
        ),
      ),
    );
  }

  void _startNewChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AiChatScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversationsState = ref.watch(getConversationProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: _buildSearchBar(),
            ),

            // Chat History Title
            const Padding(
              padding: EdgeInsets.only(left: 16.0, bottom: 12.0, top: 16.0),
              child: Text(
                "Chat History",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Conversations List
            Expanded(
              child: conversationsState.when(
                data: (response) {
                  final conversations = response.data.data;
                  if (conversations.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildConversationsList(conversations);
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFA26BFA),
                  ),
                ),
                error: (error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 50,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Failed to load conversations",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(getConversationProvider.notifier).getConversations();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA26BFA),
                        ),
                        child: const Text(
                          "Try Again",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Arrow
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFF656566),
              size: 17,
            ),
          ),
          const SizedBox(height: 24),
          // Title
          const Text(
            "Cre8Hive AI Assistant",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          // Description
          const Text(
            "Get faster results on questions regarding creatives with the best service, what you need for your projects, etc.",
            style: TextStyle(
              color: Color(0xFFB0B0B6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        hintText: "Search conversations...",
        hintStyle: const TextStyle(color: Color(0xFFC5C1D4)),
        prefixIcon: const Icon(Icons.search, color: Color(0xFFC5C1D4)),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.clear, color: Color(0xFFC5C1D4)),
          onPressed: () {
            _searchController.clear();
            ref.read(getConversationProvider.notifier).clearSearch();
          },
        )
            : null,
        contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildConversationsList(List<AiChatConversation> conversations) {
    return RefreshIndicator(
      backgroundColor: const Color(0xFF1A191E),
      color: const Color(0xFFA26BFA),
      onRefresh: () async {
        await ref.read(getConversationProvider.notifier).getConversations();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];

          return Column(
            children: [
              GestureDetector(
                onTap: () => _openConversation(conversation),
                child: Container(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                conversation.title ?? 'Untitled Conversation',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              // Metadata Row
                              Row(
                                children: [
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDateTime(conversation.createdAt),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Chevron
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF656566),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(
                color: Color(0xFF2C2C2C),
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: 150.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_toy_rounded,
              color: Color(0xFFA26BFA),
              size: 40,
            ),
            SizedBox(height: 20),
            Text(
              "No conversations yet",
              style: TextStyle(
                color: Color(0xFF7C7C88),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      child: FloatingActionButton.extended(
        onPressed: _startNewChat,
        label: Row(
          children: [
            Image.asset(
              "images/ai_chat.png",
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            const Text(
              "Start a new chat",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFA26BFA),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        elevation: 8,
      ),
    );
  }
}