import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/utils/app_colors.dart';
import 'package:soundhive2/lib/dashboard_provider/apiresponseprovider.dart';
import 'package:soundhive2/lib/dashboard_provider/get_thread_message_provider.dart';
import 'package:soundhive2/lib/dashboard_provider/get_conversations_provider.dart';
import 'package:soundhive2/lib/dashboard_provider/user_provider.dart';
import '../../../model/ai_conversation_thread_model.dart';
import '../../../model/apiresponse_model.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../marketplace/creators_list.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const _kPurple     = Color(0xFFA26BFA);
const _kPurpleLight = Color(0xFFC5AFFF);
const _kPurpleDark  = Color(0xFF19172E);
const _kSurface    = Color(0xFF1A191E);
const _kBorder     = Color(0xFF2C2C2C);

// ─────────────────────────────────────────────────────────────────────────────
// Response type enum – mirrors what the backend now returns
// ─────────────────────────────────────────────────────────────────────────────

enum AiResponseType {
  project,
  greeting,
  smallTalk,
  offTopic,
  clarification,
  error,
  unknown,
}

AiResponseType _parseResponseType(Map<String, dynamic>? data) {
  if (data == null) return AiResponseType.unknown;

  // Backend sets these flags
  if (data['is_off_topic'] == true)       return AiResponseType.offTopic;
  if (data['is_conversational'] == true)  return AiResponseType.greeting;
  if (data['needs_clarification'] == true) return AiResponseType.clarification;

  final type = (data['type'] ?? '').toString().toLowerCase();
  switch (type) {
    case 'project':      return AiResponseType.project;
    case 'greeting':     return AiResponseType.greeting;
    case 'small_talk':   return AiResponseType.smallTalk;
    case 'off_topic':    return AiResponseType.offTopic;
    case 'clarification':return AiResponseType.clarification;
    default:
    // If workflow_plan has content → treat as project
      final plan = data['workflow_plan'];
      if (plan is Map && (plan['steps'] as List? ?? []).isNotEmpty) {
        return AiResponseType.project;
      }
      return AiResponseType.unknown;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────

class AiChatScreen extends ConsumerStatefulWidget {
  final int? threadId;
  final String? initialTitle;

  const AiChatScreen({super.key, this.threadId, this.initialTitle});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _controller      = TextEditingController();
  final ScrollController       _scrollController = ScrollController();

  bool    _isGeneratingResponse = false;
  int?    _threadId;
  String? _conversationTitle;

  final List<ChatMessage> messages = [];

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _threadId           = widget.threadId;
    _conversationTitle  = widget.initialTitle;

    if (_threadId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadConversationHistory());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ── History loading ────────────────────────────────────────────────────────

  Future<void> _loadConversationHistory() async {
    if (_threadId == null) return;

    try {
      await ref.read(getThreadMessageProvider.notifier).getThreadMessage(id: _threadId!);
      final threadState = ref.read(getThreadMessageProvider);

      threadState.when(
        data: (response) {
          if (!response.success) return;
          final conversations = response.data.data;

          setState(() {
            messages.clear();
            if (conversations.isNotEmpty) {
              _conversationTitle = conversations.first.title;
            }

            for (final conversation in conversations) {
              final userImageUrl = conversation.user?.image;
              final userName     = conversation.user?.firstName;
              final metadata     = _convertMetadataToMap(conversation.metadata);
              final suggestedCreators = conversation.suggestedCreators;

              // User bubble
              messages.add(ChatMessage(
                fromUser:  true,
                text:      conversation.userMessage,
                userImage: userImageUrl,
                userName:  userName,
                timestamp: DateTime.parse(conversation.createdAt),
                metadata:  metadata,
                suggestedCreators: suggestedCreators,
              ));

              if (conversation.aiResponse.isEmpty) continue;

              // Determine type from stored title/metadata (history only)
              final storedTitle = conversation.title ?? '';
              AiResponseType historyType;
              if (storedTitle == 'Off Topic') {
                historyType = AiResponseType.offTopic;
              } else if (storedTitle == 'Conversation' || storedTitle == 'Greeting') {
                historyType = AiResponseType.greeting;
              } else if (storedTitle == 'Getting Started') {
                historyType = AiResponseType.clarification;
              } else {
                historyType = AiResponseType.project;
              }

              Map<String, dynamic>? workflowPlan;
              String aiText = conversation.aiResponse;

              if (historyType == AiResponseType.project) {
                try {
                  final cleaned = _stripJsonFences(conversation.aiResponse);
                  final decoded = json.decode(cleaned);
                  if (decoded is Map) {
                    workflowPlan = Map<String, dynamic>.from(decoded);
                    aiText = _formatWorkflowText(workflowPlan);
                  }
                } catch (_) {
                  aiText = conversation.aiResponse;
                }
              }

              messages.add(ChatMessage(
                fromUser:         false,
                text:             aiText,
                fullText:         aiText,
                timestamp:        DateTime.parse(conversation.updatedAt),
                options:          _buildOptions(historyType, workflowPlan, suggestedCreators),
                metadata:         workflowPlan ?? metadata,
                suggestedCreators: suggestedCreators,
                responseType:     historyType,
                shouldAnimate:    false,
              ));
            }
          });

          _scrollToBottom(animated: false);
        },
        loading: () {},
        error: (error, _) {
          debugPrint('Error loading conversation: $error');
          _addErrorMessage('I had trouble loading the conversation history. Let\'s start fresh!');
        },
      );
    } catch (e) {
      debugPrint('Error loading conversation: $e');
      _addErrorMessage('I had trouble loading the conversation history. Let\'s start fresh!');
    }
  }

  // ── Sending a message ──────────────────────────────────────────────────────

  void generateChat() async {
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty || _isGeneratingResponse) return;

    _addUserMessage(userMessage);
    _addThinkingMessage();

    try {
      final response = await ref.read(apiresponseProvider.notifier).generateWorkFlow(
        context:              context,
        description:          userMessage,
        parentConversationId: _threadId,
      );

      if (response.status && response.data != null) {
        final apiData = response.data!;

        if (_threadId == null && apiData['thread_starter_id'] != null) {
          setState(() {
            _threadId          = apiData['thread_starter_id'];
            _conversationTitle = apiData['title'] ?? _conversationTitle;
          });
        }

        final responseType      = _parseResponseType(apiData);
        final workflowPlan      = Map<String, dynamic>.from(apiData['workflow_plan'] ?? {});
        final suggestedCreators = apiData['suggested_creators'] ?? [];
        final aiText            = (apiData['ai_response'] as String?) ??
            _formatWorkflowText(workflowPlan);

        _replaceThinkingWithResponse(
          aiText:           aiText,
          workflowPlan:     workflowPlan,
          suggestedCreators: suggestedCreators,
          responseType:     responseType,
        );

        await ref.read(getConversationProvider.notifier).getConversations();
      } else {
        _handleError(response.message);
      }
    } on DioException catch (e) {
      String msg = e.message ?? 'Network error occurred';
      if (e.response?.data != null) {
        try {
          msg = ApiResponseModel.fromJson(e.response!.data).message;
        } catch (_) {}
      }
      _handleError(msg);
    } catch (e) {
      _handleError('An unexpected error occurred');
    }
  }

  // ── Message helpers ────────────────────────────────────────────────────────

  void _addUserMessage(String text) {
    final user = ref.read(userProvider);
    setState(() {
      messages.add(ChatMessage(
        fromUser:  true,
        text:      text,
        userImage: user.value?.user?.image,
        userName:  user.value?.user?.firstName,
        timestamp: DateTime.now(),
      ));
      _isGeneratingResponse = false;
    });
    _controller.clear();
    _scrollToBottom();
  }

  void _addThinkingMessage() {
    setState(() {
      messages.add(ChatMessage(
        fromUser:  false,
        text:      '',
        isThinking: true,
        timestamp: DateTime.now(),
      ));
      _isGeneratingResponse = true;
    });
    _scrollToBottom();
  }

  void _addErrorMessage(String text) {
    setState(() {
      messages.add(ChatMessage(
        fromUser:  false,
        text:      text,
        timestamp: DateTime.now(),
        responseType: AiResponseType.error,
      ));
    });
  }

  void _replaceThinkingWithResponse({
    required String aiText,
    required Map<String, dynamic> workflowPlan,
    required dynamic suggestedCreators,
    required AiResponseType responseType,
  }) {
    setState(() {
      messages.removeWhere((m) => m.isThinking == true);
      messages.add(ChatMessage(
        fromUser:          false,
        text:              '',
        fullText:          aiText,
        timestamp:         DateTime.now(),
        options:           _buildOptions(responseType, workflowPlan, suggestedCreators),
        metadata:          workflowPlan,
        suggestedCreators: suggestedCreators,
        responseType:      responseType,
        shouldAnimate:     true,
      ));
      _isGeneratingResponse = false;
    });
    _scrollToBottom();
  }

  void _handleError(String errorMessage) {
    setState(() {
      messages.removeWhere((m) => m.isThinking == true);
      messages.add(ChatMessage(
        fromUser:    false,
        text:        'Sorry, I ran into an issue: $errorMessage\n\nPlease try again.',
        timestamp:   DateTime.now(),
        responseType: AiResponseType.error,
      ));
      _isGeneratingResponse = false;
    });
  }

  // ── Options builder ────────────────────────────────────────────────────────

  List<String> _buildOptions(
      AiResponseType type,
      Map<String, dynamic>? plan,
      dynamic suggestedCreators,
      ) {
    // Off-topic: redirect shortcuts only
    if (type == AiResponseType.offTopic) {
      return [
        '📅 Plan a wedding',
        '🎂 Plan a birthday party',
        '💼 Plan a corporate event',
        '🎵 Produce a music album',
        '📸 Arrange a photoshoot',
      ];
    }

    // Greeting / clarification: just a nudge
    if (type == AiResponseType.greeting || type == AiResponseType.clarification) {
      return ['Start a project'];
    }

    // Project: build from plan
    final options = <String>[];

    final required = (plan?['required_creators'] as List? ?? []);
    for (final c in required.take(3)) {
      final s = c.toString().trim();
      if (s.isNotEmpty) options.add('Browse ${s}s');
    }

    final timeline  = plan?['timeline']?.toString()   ?? '';
    final costRange = plan?['cost_range']?.toString()  ?? '';

    if (timeline.isNotEmpty   && !_isNonApplicable(timeline))   options.add('View timeline');
    if (costRange.isNotEmpty  && !_isNonApplicable(costRange))  options.add('See cost range');

    bool hasCreators = false;
    if (suggestedCreators is Map) {
      hasCreators = suggestedCreators.values
          .any((v) => v is List && v.isNotEmpty);
    } else if (suggestedCreators is List) {
      hasCreators = suggestedCreators.isNotEmpty;
    }
    if (hasCreators) options.add('Book creators now');

    return options;
  }

  // ── Text formatting ────────────────────────────────────────────────────────

  String _formatWorkflowText(Map<String, dynamic>? plan) {
    if (plan == null || plan.isEmpty) return '';
    final sb = StringBuffer();

    final creators  = plan['required_creators'] as List? ?? [];
    final timeline  = plan['timeline']?.toString()   ?? '';
    final costRange = plan['cost_range']?.toString()  ?? '';
    final steps     = plan['steps'] as List? ?? [];

    if (creators.isNotEmpty) {
      sb.writeln('Required Creators:');
      for (final c in creators) sb.writeln('• $c');
      sb.writeln();
    }
    if (timeline.isNotEmpty && !_isNonApplicable(timeline)) {
      sb.writeln('Timeline: $timeline');
      sb.writeln();
    }
    if (costRange.isNotEmpty && !_isNonApplicable(costRange)) {
      sb.writeln('Estimated Cost: $costRange');
      sb.writeln();
    }
    if (steps.isNotEmpty) {
      sb.writeln('Action Steps:');
      for (var i = 0; i < steps.length; i++) {
        sb.writeln('${i + 1}. ${steps[i]}');
      }
    }
    return sb.toString().trim();
  }

  bool _isNonApplicable(String value) {
    final v = value.toLowerCase();
    return v.isEmpty ||
        v.contains('not applicable') ||
        v.contains('n/a') ||
        v.contains('varies') ||
        v.contains('contact for') ||
        v.contains('consult with');
  }

  Map<String, dynamic> _convertMetadataToMap(Metadata? m) {
    if (m == null) return {};
    return {'timeline': m.timeline, 'cost_range': m.costRange, 'steps': m.steps};
  }

  String _stripJsonFences(String raw) {
    String s = raw.trim();
    if (s.startsWith('```')) {
      s = s
          .replaceFirst(RegExp(r'^```json\s*\n?'), '')
          .replaceFirst(RegExp(r'\n?```$'), '')
          .trim();
    }
    return s;
  }

  // ── Scroll ─────────────────────────────────────────────────────────────────

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  // ── Option handler ─────────────────────────────────────────────────────────

  void _handleOptionTap(String option, ChatMessage message) {
    // Off-topic redirect shortcuts — inject as a new message
    final redirectPrefixes = ['📅', '🎂', '💼', '🎵', '📸'];
    if (redirectPrefixes.any((p) => option.startsWith(p))) {
      // Strip the emoji prefix and send as a user query
      final query = option.replaceAll(RegExp(r'^[^\w]+'), '').trim();
      _controller.text = query;
      generateChat();
      return;
    }

    if (option.startsWith('Browse')) {
      final creatorType = option.replaceAll('Browse ', '').replaceAll(RegExp(r's$'), '');
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => CreatorsList(initialJobTitleFilter: creatorType),
      ));
    } else if (option == 'View timeline') {
      _showInfoDialog('Work Plan Timeline', message.metadata?['timeline']?.toString());
    } else if (option == 'See cost range') {
      _showInfoDialog('Estimated Cost Range', message.metadata?['cost_range']?.toString());
    } else if (option == 'Book creators now') {
      String? filter;
      final sc = message.suggestedCreators;
      if (sc is Map && sc.isNotEmpty) {
        final first = sc.values.first;
        if (first is List && first.isNotEmpty) {
          filter = (first.first as Map?)?['job_title']?.toString();
        }
      }
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => CreatorsList(initialJobTitleFilter: filter),
      ));
    } else if (option == 'Start a project') {
      _controller.text = '';
      FocusScope.of(context).requestFocus(FocusNode());
    }
  }

  void _showInfoDialog(String title, String? content) {
    if (content == null || content.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: _kPurple)),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.BACKGROUNDCOLOR,
      resizeToAvoidBottomInset: true, // 👈 Make sure this is true
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: Text(
          _conversationTitle ?? 'Cre8Hive AI Assistant',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF656566)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // This Expanded forces the message list to take all available space
          // and dynamically shrink down comfortably when the keyboard opens.
          Expanded(
            child: messages.isEmpty ? _buildEmptyState() : _buildChatList(),
          ),
          SafeArea(top: false, child: _buildChatInput()),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: _kPurple.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded, color: _kPurple, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            _threadId != null ? 'Continue your conversation' : 'What do you want to create?',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _threadId != null
                  ? 'I\'m ready to continue helping you'
                  : 'Describe your event or project and I\'ll build your plan',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (_, index) {
        final msg = messages[index];
        if (msg.isThinking == true) return _buildThinkingIndicator();
        return _OptimizedMessageBubble(
          message:     msg,
          onOptionTap: _handleOptionTap,
        );
      },
    );
  }

  Widget _buildThinkingIndicator() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AiAvatar(),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cre8hive AI is thinking',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: 8),
              LoadingAnimationWidget.waveDots(color: _kPurple, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatInput() {
    return Container(
      // Clean up bottom padding calculations; let the Scaffold resize lift this container
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.BACKGROUNDCOLOR,
        border: Border(top: BorderSide(color: _kBorder.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isGeneratingResponse,
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  final updatedText =
                      value[0].toUpperCase() + value.substring(1);

                  if (updatedText != value) {
                    _controller.value = TextEditingValue(
                      text: updatedText,
                      selection: TextSelection.collapsed(
                        offset: updatedText.length,
                      ),
                    );
                  }
                }
              },
              decoration: InputDecoration(
                hintText: 'Ask something e.g I want to launch...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: _kSurface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: _kPurple),
                ),
              ),
              onSubmitted: (_) {
                if (!_isGeneratingResponse) generateChat();
              },
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isGeneratingResponse ? null : generateChat,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isGeneratingResponse ? _kPurple.withOpacity(0.4) : _kPurple,
                shape: BoxShape.circle,
              ),
              child: _isGeneratingResponse
                  ? LoadingAnimationWidget.threeArchedCircle(color: Colors.white, size: 20)
                  : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Avatar
// ─────────────────────────────────────────────────────────────────────────────

class _AiAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4, top: 5),
      width: 35, height: 35,
      decoration: const BoxDecoration(color: _kPurple, shape: BoxShape.circle),
      child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message Bubble
// ─────────────────────────────────────────────────────────────────────────────

class _OptimizedMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final void Function(String, ChatMessage) onOptionTap;

  const _OptimizedMessageBubble({required this.message, required this.onOptionTap});

  @override
  Widget build(BuildContext context) {
    final isUser = message.fromUser;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser) _AiAvatar(),
        if (isUser) _UserAvatar(message: message),
        const SizedBox(width: 8),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color:        message.responseType == AiResponseType.offTopic
                    ? const Color(0xFF1F1A2E)
                    : _kSurface,
                borderRadius: BorderRadius.circular(4),
                border:       Border.all(
                  color: message.responseType == AiResponseType.offTopic
                      ? _kPurple.withOpacity(0.4)
                      : _kBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Off-topic header badge
                  if (message.responseType == AiResponseType.offTopic) ...[
                    _OffTopicBadge(),
                    const SizedBox(height: 10),
                  ],
                  // Message text
                  _MessageText(message: message),
                  // Options
                  if (message.options != null && message.options!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    // Off-topic options have a different heading
                    if (message.responseType == AiResponseType.offTopic)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'Here\'s what I can help with:',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ...message.options!.map((opt) => _OptionChip(
                      label: opt,
                      onTap: () => onOptionTap(opt, message),
                      isRedirect: message.responseType == AiResponseType.offTopic,
                    )),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Off-topic badge
// ─────────────────────────────────────────────────────────────────────────────

class _OffTopicBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _kPurple.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kPurple.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.info_outline_rounded, color: _kPurple, size: 12),
          SizedBox(width: 4),
          Text(
            'Outside my expertise',
            style: TextStyle(
              color: _kPurple,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message text (typing animation aware)
// ─────────────────────────────────────────────────────────────────────────────

class _MessageText extends StatelessWidget {
  final ChatMessage message;
  const _MessageText({required this.message});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: Colors.white, fontSize: 14, height: 1.45);
    final displayText = message.fullText ?? message.text;

    if (!message.fromUser &&
        message.fullText != null &&
        message.shouldAnimate &&
        !message.animationComplete) {
      return TypingAnimatedText(
        fullText:      message.fullText!,
        style:         style,
        shouldAnimate: true,
        onComplete:    () { message.animationComplete = true; },
      );
    }
    return Text(displayText, style: style);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Option chip
// ─────────────────────────────────────────────────────────────────────────────

class _OptionChip extends StatelessWidget {
  final String   label;
  final VoidCallback onTap;
  final bool     isRedirect;

  const _OptionChip({required this.label, required this.onTap, this.isRedirect = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:        isRedirect ? _kPurple.withOpacity(0.1) : _kPurpleDark,
          borderRadius: BorderRadius.circular(4),
          border:       Border.all(
            color: isRedirect ? _kPurple.withOpacity(0.5) : Colors.white24,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color:      isRedirect ? _kPurpleLight : _kPurpleLight,
                  fontSize:   13,
                  fontWeight: isRedirect ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              isRedirect ? Icons.auto_awesome : Icons.arrow_forward_ios,
              color: _kPurpleLight,
              size:  13,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User avatar
// ─────────────────────────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  final ChatMessage message;
  const _UserAvatar({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.userImage != null && message.userImage!.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.only(left: 8, top: 5),
        width: 35, height: 35,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(message.userImage!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final initial = message.userName?.isNotEmpty == true
        ? message.userName![0].toUpperCase()
        : 'U';

    final colors = [
      _kPurple,
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
    ];
    final color = colors[initial.codeUnitAt(0) % colors.length];

    return Container(
      margin: const EdgeInsets.only(left: 8, top: 5),
      width: 35, height: 35,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(initial,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Typing animated text
// ─────────────────────────────────────────────────────────────────────────────

class TypingAnimatedText extends StatefulWidget {
  final String       fullText;
  final TextStyle?   style;
  final bool         shouldAnimate;
  final VoidCallback? onComplete;

  const TypingAnimatedText({
    super.key,
    required this.fullText,
    this.style,
    this.shouldAnimate = true,
    this.onComplete,
  });

  @override
  State<TypingAnimatedText> createState() => _TypingAnimatedTextState();
}

class _TypingAnimatedTextState extends State<TypingAnimatedText> {
  final ValueNotifier<String> _display    = ValueNotifier('');
  final ValueNotifier<bool>   _isComplete = ValueNotifier(false);
  Timer? _timer;
  int    _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.shouldAnimate && widget.fullText.isNotEmpty) {
      _startAnimation();
    } else {
      _display.value    = widget.fullText;
      _isComplete.value = true;
    }
  }

  void _startAnimation() {
    final chars = widget.fullText.characters.toList();
    _timer = Timer.periodic(const Duration(milliseconds: 18), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_currentIndex >= chars.length) {
        t.cancel();
        _isComplete.value = true;
        widget.onComplete?.call();
        return;
      }
      _currentIndex++;
      _display.value = chars.take(_currentIndex).join();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _display.dispose();
    _isComplete.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _display,
      builder: (_, text, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: widget.style),
          ValueListenableBuilder<bool>(
            valueListenable: _isComplete,
            builder: (_, done, __) => done
                ? const SizedBox.shrink()
                : const Text('▋',
                style: TextStyle(color: _kPurple, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ChatMessage model
// ─────────────────────────────────────────────────────────────────────────────

class ChatMessage {
  final bool              fromUser;
  final String            text;
  final String?           fullText;
  final String?           userImage;
  final String?           userName;
  final DateTime          timestamp;
  final bool?             isThinking;
  final List<String>?     options;
  final Map<String, dynamic>? metadata;
  final dynamic           suggestedCreators;
  final bool              shouldAnimate;
  final AiResponseType    responseType;
  bool                    animationComplete;

  ChatMessage({
    required this.fromUser,
    required this.text,
    this.fullText,
    this.userImage,
    this.userName,
    required this.timestamp,
    this.isThinking,
    this.options,
    this.metadata,
    this.suggestedCreators,
    this.shouldAnimate     = false,
    this.responseType      = AiResponseType.unknown,
    this.animationComplete = false,
  });

  ChatMessage copyWith({
    bool? fromUser, String? text, String? fullText, String? userImage,
    String? userName, DateTime? timestamp, bool? isThinking,
    List<String>? options, Map<String, dynamic>? metadata,
    dynamic suggestedCreators, bool? shouldAnimate,
    AiResponseType? responseType, bool? animationComplete,
  }) => ChatMessage(
    fromUser:          fromUser          ?? this.fromUser,
    text:              text              ?? this.text,
    fullText:          fullText          ?? this.fullText,
    userImage:         userImage         ?? this.userImage,
    userName:          userName          ?? this.userName,
    timestamp:         timestamp         ?? this.timestamp,
    isThinking:        isThinking        ?? this.isThinking,
    options:           options           ?? this.options,
    metadata:          metadata          ?? this.metadata,
    suggestedCreators: suggestedCreators ?? this.suggestedCreators,
    shouldAnimate:     shouldAnimate     ?? this.shouldAnimate,
    responseType:      responseType      ?? this.responseType,
    animationComplete: animationComplete ?? this.animationComplete,
  );
}