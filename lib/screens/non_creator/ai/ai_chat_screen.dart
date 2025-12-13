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

class AiChatScreen extends ConsumerStatefulWidget {
  final int? threadId;
  final String? initialTitle;

  const AiChatScreen({
    super.key,
    this.threadId,
    this.initialTitle,
  });

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isGeneratingResponse = false;
  int? _threadId;
  String? _conversationTitle;

  // Store typing animation state for each AI message
  final Map<int, TypingAnimationState> _typingStates = {};

  final List<ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();
    _threadId = widget.threadId;
    _conversationTitle = widget.initialTitle;

    // If we have a thread ID, load the conversation history
    if (_threadId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadConversationHistory();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    // Cancel all timers
    _typingStates.forEach((key, state) {
      state.timer?.cancel();
    });
    _typingStates.clear();
    super.dispose();
  }

  Future<void> _loadConversationHistory() async {
    if (_threadId == null) return;

    try {
      // Load the data
      await ref.read(getThreadMessageProvider.notifier).getThreadMessage(id: _threadId!);

      // Get the current state after loading
      final threadState = ref.read(getThreadMessageProvider);

      threadState.when(
        data: (response) {
          if (response.success) {
            final conversations = response.data.data; // This is the paginated list

            setState(() {
              // Clear existing messages
              messages.clear();

              // Set conversation title from the first conversation
              if (conversations.isNotEmpty) {
                _conversationTitle = conversations.first.title;
              }

              // Load all conversations from the paginated response
              for (var conversation in conversations) {

                String? userImageUrl;
                String? userName;

                if (conversation.user != null) {
                  userImageUrl = conversation.user!.image; // This should be the image URL
                  userName = conversation.user!.firstName;
                }

                // Extract suggested creators from conversation
                dynamic suggestedCreators = conversation.suggestedCreators;

                // Parse metadata
                final metadata = _convertMetadataToMap(conversation.metadata);

                // Add user message
                messages.add(ChatMessage(
                  fromUser: true,
                  text: conversation.userMessage,
                  userImage: userImageUrl, // Pass actual image URL
                  userName: userName,
                  timestamp: DateTime.parse(conversation.createdAt),
                  metadata: metadata,
                  suggestedCreators: suggestedCreators,
                ));

                // Add AI response if exists
                if (conversation.aiResponse.isNotEmpty) {
                  // Try to parse the AI response
                  String aiText = conversation.aiResponse;
                  Map<String, dynamic>? workflowPlan;

                  // If it's JSON, extract the readable content
                  try {
                    final jsonResponse = json.decode(conversation.aiResponse);
                    if (jsonResponse is Map) {
                      // Store the workflow plan for options generation
                      workflowPlan = Map<String, dynamic>.from(jsonResponse);
                      aiText = _formatAiResponse(
                        workflowPlan,
                        suggestedCreators,
                      );
                    }
                  } catch (e) {
                    // If not JSON, use as-is
                    aiText = conversation.aiResponse;
                  }

                  // Generate options from the loaded data
                  List<String>? options;
                  if (workflowPlan != null) {
                    // Use workflow plan if we parsed it
                    options = _generateOptionsFromResponse(workflowPlan, suggestedCreators);
                  } else if (metadata.isNotEmpty) {
                    // If no workflow plan but we have metadata, create options from metadata
                    final Map<String, dynamic> planFromMetadata = {
                      'required_creators': [],
                      'timeline': metadata['timeline'],
                      'cost_range': metadata['cost_range'],
                      'steps': metadata['steps'] ?? [],
                    };

                    // Try to get required creators from suggestedCreators keys
                    if (suggestedCreators is Map) {
                      planFromMetadata['required_creators'] = suggestedCreators.keys.toList();
                    }

                    options = _generateOptionsFromResponse(planFromMetadata, suggestedCreators);
                  }

                  messages.add(ChatMessage(
                    fromUser: false,
                    text: aiText,
                    fullText: aiText,
                    timestamp: DateTime.parse(conversation.updatedAt),
                    options: options, // Use the regenerated options
                    metadata: metadata,
                    suggestedCreators: suggestedCreators,
                    shouldAnimate: false,
                  ));
                }
              }
            });

            _scrollToBottom();
          }
        },
        loading: () {
          const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFA26BFA),
            ),
          );
        },
        error: (error, stackTrace) {
          // Handle error
          print("Error loading conversation: $error");
          setState(() {
            messages.add(ChatMessage(
              fromUser: false,
              text: "I had trouble loading the conversation history. Let's start fresh!",
              timestamp: DateTime.now(),
            ));
          });
        },
      );
    } catch (e) {
      print("Error loading conversation: $e");
      setState(() {
        messages.add(ChatMessage(
          fromUser: false,
          text: "I had trouble loading the conversation history. Let's start fresh!",
          timestamp: DateTime.now(),
        ));
      });
    }
  }

  Map<String, dynamic> _convertMetadataToMap(Metadata? metadata) {
    if (metadata == null) return {};

    return {
      'timeline': metadata.timeline,
      'cost_range': metadata.costRange,
      'steps': metadata.steps,
    };
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  void _addUserMessage(String text) {
    final user = ref.watch(userProvider);
    final message = ChatMessage(
      fromUser: true,
      text: text,
      userImage: user.value?.user?.image,
      userName: user.value?.user?.firstName,
      timestamp: DateTime.now(),
      shouldAnimate: false,
    );

    setState(() {
      messages.add(message);
    });
    _controller.clear();
    _scrollToBottom();
  }

  void _addAiThinkingMessage() {
    final message = ChatMessage(
      fromUser: false,
      text: "",
      isThinking: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      messages.add(message);
      _isGeneratingResponse = true;
    });
    _scrollToBottom();
  }

  void _startTypingAnimation(int messageIndex, String fullText) {
    if (messageIndex >= messages.length) return;
    if (fullText.isEmpty) return;

    // Update the message with fullText for the TypingAnimatedText widget
    messages[messageIndex] = messages[messageIndex].copyWith(
      fullText: fullText,
    );

    // Trigger a single rebuild instead of multiple setStates
    setState(() {});

    // Scroll to bottom without animation during typing
    _scrollToBottom(animated: false);
  }

  void generateChat() async {
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    _addUserMessage(userMessage);
    _addAiThinkingMessage();

    try {
      final response = await ref.read(apiresponseProvider.notifier).generateWorkFlow(
        context: context,
        description: userMessage,
        parentConversationId: _threadId, // Pass thread ID if exists
      );

      if (response.status && response.data != null) {
        final apiData = response.data!;

        // Check if we have the expected data structure
        if (apiData['workflow_plan'] != null) {
          final workflowPlan = apiData['workflow_plan'] as Map<String, dynamic>;
          final suggestedCreators = apiData['suggested_creators'] ?? [];

          // If this is a new thread, update the thread ID
          if (_threadId == null && apiData['thread_starter_id'] != null) {
            setState(() {
              _threadId = apiData['thread_starter_id'];
              _conversationTitle = apiData['title'] ?? _conversationTitle;
            });
          }

          // Format the AI response text
          final aiResponseText = _formatAiResponse(workflowPlan, suggestedCreators);

          _updateAiMessageWithResponse(
            aiResponseText: aiResponseText,
            workflowPlan: workflowPlan,
            suggestedCreators: suggestedCreators,
          );
          await ref.read(getConversationProvider.notifier).getConversations();
        } else {
          _handleError("Invalid response format from server");
        }
      } else {
        _handleError("Failed to generate response: ${response.message}");
      }
    } catch (error) {
      String errorMessage = 'An unexpected error occurred';

      if (error is DioException) {
        if (error.response?.data != null) {
          try {
            final apiResponse = ApiResponseModel.fromJson(error.response?.data);
            errorMessage = apiResponse.message;
          } catch (e) {
            errorMessage = 'Failed to parse error message';
          }
        } else {
          errorMessage = error.message ?? 'Network error occurred';
        }
      }

      _handleError(errorMessage);
    }
  }

  String _formatAiResponse(Map<dynamic, dynamic> workflowPlan, dynamic suggestedCreators) {
    final StringBuffer response = StringBuffer();

    response.writeln("Here's your personalized workflow plan:");
    response.writeln();

    // Add required creators
    final requiredCreators = workflowPlan['required_creators'] ?? [];
    if (requiredCreators.isNotEmpty) {
      response.writeln("Required Creators:");
      for (var creator in requiredCreators) {
        response.writeln("- ${creator.toString()}");
      }
      response.writeln();
    } else {
      response.writeln("Based on your project description, here's what you might need:");
      response.writeln();
    }

    // Add timeline
    final timeline = workflowPlan['timeline'] ?? '2-4 weeks';
    response.writeln("Timeline: $timeline");
    response.writeln();

    // Add cost range
    final costRange = workflowPlan['cost_range'] ?? 'Varies based on requirements';
    response.writeln("Estimated Cost: $costRange");
    response.writeln();

    // Add steps
    final steps = workflowPlan['steps'] ?? [];
    if (steps.isNotEmpty) {
      response.writeln("Action Steps:");
      for (var i = 0; i < steps.length; i++) {
        response.writeln("${i + 1}. ${steps[i]}");
      }
      response.writeln();
    }

    // Add suggested creators if available
    if (suggestedCreators != null) {
      bool hasCreators = false;

      if (suggestedCreators is Map) {
        for (var creatorType in suggestedCreators.keys) {
          final creators = suggestedCreators[creatorType];
          if (creators is List && creators.isNotEmpty) {
            hasCreators = true;
            break;
          }
        }
      }

      if (hasCreators) {
        response.writeln("Available Creators:");

        if (suggestedCreators is Map) {
          for (var creatorType in suggestedCreators.keys) {
            final creators = suggestedCreators[creatorType];
            if (creators is List && creators.isNotEmpty) {
              for (var creator in creators) {
                if (creator is Map) {
                  final jobTitle = creator['job_title'] ?? creator['jobTitle'] ?? creatorType;
                  final businessName = creator['business_name'] ?? creator['businessName'] ?? 'Creator';
                  response.writeln("- $businessName ($jobTitle)");
                }
              }
            }
          }
        }
      }
    }

    return response.toString();
  }

  void _updateAiMessageWithResponse({
    required String aiResponseText,
    required Map<String, dynamic> workflowPlan,
    required dynamic suggestedCreators,
  }) {
    setState(() {
      // Remove the thinking message
      messages.removeWhere((msg) => msg.isThinking == true);

      // Create the AI response message
      final aiMessage = ChatMessage(
        fromUser: false,
        text: "", // Start with empty text for typing animation
        fullText: aiResponseText,
        timestamp: DateTime.now(),
        options: _generateOptionsFromResponse(workflowPlan, suggestedCreators),
        metadata: workflowPlan,
        suggestedCreators: suggestedCreators,
        shouldAnimate: true, // IMPORTANT: Set to true for new responses
      );

      // Add the message
      messages.add(aiMessage);
      _isGeneratingResponse = false;
    });

    // Start typing animation after a brief delay
    Future.delayed(const Duration(milliseconds: 300), () {
      final lastMessage = messages.last;
      if (lastMessage.fullText != null && lastMessage.shouldAnimate) {
        _startTypingAnimation(messages.length - 1, lastMessage.fullText!);
      }
    });
  }

  List<String> _generateOptionsFromResponse(
      Map<String, dynamic> workflowPlan,
      dynamic suggestedCreators
      ) {
    final List<String> options = [];

    // Add creator type options from workflow plan
    final requiredCreators = workflowPlan['required_creators'] ?? [];
    for (var creatorType in requiredCreators) {
      options.add("Browse ${creatorType}s");
    }

    // Add general options
    if (workflowPlan['timeline'] != null) {
      options.add("View work plan timeline");
    }

    if (workflowPlan['cost_range'] != null) {
      options.add("See estimated cost range");
    }

    // Check if we have suggested creators to show "Book creators now"
    if (suggestedCreators != null) {
      bool hasCreators = false;

      if (suggestedCreators is Map) {
        // Check if any creator type has creators
        for (var creatorType in suggestedCreators.keys) {
          final creators = suggestedCreators[creatorType];
          if (creators is List && creators.isNotEmpty) {
            hasCreators = true;
            break;
          }
        }
      } else if (suggestedCreators is List && suggestedCreators.isNotEmpty) {
        hasCreators = true;
      }

      // if (hasCreators) {
      //   options.add("Book creators now");
      // }
    }

    return options;
  }

  void _handleError(String errorMessage) {
    setState(() {
      // Remove thinking message
      messages.removeWhere((msg) => msg.isThinking == true);

      // Add error message
      messages.add(ChatMessage(
        fromUser: false,
        text: "Sorry, I encountered an error: $errorMessage\n\nPlease try again.",
        timestamp: DateTime.now(),
      ));

      _isGeneratingResponse = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.BACKGROUNDCOLOR,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A191E),
        elevation: 0,
        title: Text(
          _conversationTitle ?? "Cre8Hive AI Assistant",
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF656566)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          _buildChatInput()
        ],
      ),
    );
  }

  Widget _buildBody() {
    return messages.isEmpty
        ? _buildEmptyState()
        : _buildChatWithMessages();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFA26BFA).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Color(0xFFA26BFA),
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _threadId != null ? "Continue your conversation" : "What do you want to create?",
            style: const TextStyle(color: Colors.white, fontSize: 24),
          ),
          const SizedBox(height: 10),
          Text(
            _threadId != null
                ? "I'm ready to continue helping you with your project"
                : "Describe your project and I'll help you plan it",
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatWithMessages() {
    return Column(
      children: [
        Expanded(
          child: _buildChatList(),
        ),
      ],
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (_, index) {
        final message = messages[index];
        final isThinking = message.isThinking == true;

        return Column(
          children: [
            if (isThinking) _buildThinkingIndicator(),
            if (!isThinking) _OptimizedMessageBubble(
              message: message,
              onOptionTap: _handleOptionTap,
            ),
          ],
        );
      },
    );
  }


  Widget _buildThinkingIndicator() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8, top: 5),
          width: 35,
          height: 35,
          decoration: const BoxDecoration(
            color: Color(0xFFA26BFA),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.smart_toy_rounded,
              color: Colors.white, size: 18),
        ),

        const SizedBox(width: 8),

        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A191E),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: const Color(0xFF2C2C2C),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "Cre8hive AI is thinking",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 8),
                  LoadingAnimationWidget.waveDots(
                    color: const Color(0xFFA26BFA),
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleOptionTap(String option, ChatMessage message) {
    if (option.startsWith("Browse")) {
      final creatorType = option.replaceAll("Browse ", "").replaceAll("s", "");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreatorsList(
            initialJobTitleFilter: creatorType,
          ),
        ),
      );
    } else if (option == "View work plan timeline") {
      _showTimeline(message.metadata?['timeline']);
    } else if (option == "See estimated cost range") {
      _showCostRange(message.metadata?['cost_range']);
    } else if (option == "Book creators now") {
      // Extract suggested creators from message
      final suggestedCreators = message.suggestedCreators;
      String? jobTitleFilter;

      // Try to extract job title from suggested creators
      if (suggestedCreators is Map) {
        // Check if there's a single creator type or multiple
        final creatorTypes = suggestedCreators.keys.toList();
        if (creatorTypes.isNotEmpty) {
          // Take the first creator type as job title filter
          final firstType = creatorTypes[0];
          // Get the creators for this type
          final creators = suggestedCreators[firstType];
          if (creators is List && creators.isNotEmpty) {
            // Take the job title from the first creator
            final firstCreator = creators[0];
            if (firstCreator is Map && firstCreator['job_title'] != null) {
              jobTitleFilter = firstCreator['job_title'];
            }
          }
        }
      } else if (suggestedCreators is List && suggestedCreators.isNotEmpty) {
        // Handle if suggestedCreators is a list
        final firstCreator = suggestedCreators[0];
        if (firstCreator is Map && firstCreator['job_title'] != null) {
          jobTitleFilter = firstCreator['job_title'];
        }
      }

      // Navigate to CreatorsList with job title filter
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreatorsList(
            initialJobTitleFilter: jobTitleFilter,
          ),
        ),
      );
    }
  }

  void _showTimeline(String? timeline) {
    if (timeline == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A191E),
        title: const Text(
          "Work Plan Timeline",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          timeline,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Close",
              style: TextStyle(color: Color(0xFFA26BFA)),
            ),
          ),
        ],
      ),
    );
  }

  void _showCostRange(String? costRange) {
    if (costRange == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A191E),
        title: const Text(
          "Estimated Cost Range",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          costRange,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Close",
              style: TextStyle(color: Color(0xFFA26BFA)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.BACKGROUNDCOLOR,
        border: Border(
          top: BorderSide(
            color: const Color(0xFF2C2C2C).withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isGeneratingResponse,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Ask something e.g I want to launch...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: const Color(0xFF1A191E),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(color: Color(0xFF2C2C2C), width: 1)
                ),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(color: Color(0xFF2C2C2C), width: 1)
                ),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(color: AppColors.PRIMARYCOLOR, width: 1)
                ),
              ),
              onSubmitted: (_) {
                if (!_isGeneratingResponse) {
                  generateChat();
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isGeneratingResponse ? null : generateChat,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isGeneratingResponse
                    ? const Color(0xFFA26BFA).withOpacity(0.5)
                    : AppColors.PRIMARYCOLOR,
                shape: BoxShape.circle,
              ),
              child: _isGeneratingResponse
                  ? LoadingAnimationWidget.threeArchedCircle(
                color: Colors.white,
                size: 20,
              )
                  : const Icon(Icons.send, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}

// Chat Message Model
class ChatMessage {
  final bool fromUser;
  final String text;
  final String? fullText;
  final String? userImage;
  final String? userName;
  final DateTime timestamp;
  final bool? isThinking;
  final List<String>? options;
  final Map<String, dynamic>? metadata;
  final dynamic suggestedCreators;
  final bool shouldAnimate; // Add this flag

  ChatMessage({
    required this.fromUser,
    required this.text,
    this.fullText,
    this.userImage,
    required this.timestamp,
    this.isThinking,
    this.userName,
    this.options,
    this.metadata,
    this.suggestedCreators,
    this.shouldAnimate = false, // Default to false
  });

  ChatMessage copyWith({
    bool? fromUser,
    String? text,
    String? fullText,
    String? userImage,
    String? userName,
    DateTime? timestamp,
    bool? isThinking,
    List<String>? options,
    Map<String, dynamic>? metadata,
    dynamic suggestedCreators,
    bool? shouldAnimate,
  }) {
    return ChatMessage(
      fromUser: fromUser ?? this.fromUser,
      text: text ?? this.text,
      fullText: fullText ?? this.fullText,
      userImage: userImage ?? this.userImage,
      userName: userName ?? this.userName,
      timestamp: timestamp ?? this.timestamp,
      isThinking: isThinking ?? this.isThinking,
      options: options ?? this.options,
      metadata: metadata ?? this.metadata,
      suggestedCreators: suggestedCreators ?? this.suggestedCreators,
      shouldAnimate: shouldAnimate ?? this.shouldAnimate,
    );
  }
}

// Helper class to manage typing animation state
class TypingAnimationState {
  final String fullText;
  String currentText;
  bool isComplete;
  Timer? timer;

  TypingAnimationState({
    required this.fullText,
    required this.currentText,
    required this.isComplete,
    this.timer,
  });
}

// Create a separate widget for typing animation
class TypingAnimatedText extends StatefulWidget {
  final String fullText;
  final TextStyle? style;
  final bool shouldAnimate; // Add this parameter

  const TypingAnimatedText({
    super.key,
    required this.fullText,
    this.style,
    this.shouldAnimate = true, // Default to true
  });

  @override
  State<TypingAnimatedText> createState() => _TypingAnimatedTextState();
}

class _TypingAnimatedTextState extends State<TypingAnimatedText> {
  final ValueNotifier<String> _displayText = ValueNotifier<String>('');
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.shouldAnimate && widget.fullText.isNotEmpty) {
      _startAnimation();
    } else {
      // If shouldn't animate, show full text immediately
      _displayText.value = widget.fullText;
    }
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_currentIndex >= widget.fullText.length) {
        timer.cancel();
        return;
      }

      _currentIndex++;
      _displayText.value = widget.fullText.substring(0, _currentIndex);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _displayText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _displayText,
      builder: (context, text, child) {
        return Text(
          text,
          style: widget.style,
        );
      },
    );
  }
}

// Optimized ChatMessage widget
class _OptimizedMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(String, ChatMessage) onOptionTap;

  const _OptimizedMessageBubble({
    required this.message,
    required this.onOptionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.fromUser;
    final double bubbleWidth = isUser ? 179 : 251;
    final isThinking = message.isThinking == true;
    final shouldAnimate = message.shouldAnimate;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser)
          Container(
            margin: const EdgeInsets.only(right: 8, top: 5),
            width: 35,
            height: 35,
            decoration: const BoxDecoration(
              color: Color(0xFFA26BFA),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 18),
          ),

        if (isUser)
          _buildUserAvatar(message),

        const SizedBox(width: 8),

        Container(
          width: bubbleWidth,
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A191E),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: const Color(0xFF2C2C2C),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show animated text only if shouldAnimate is true
              if (message.fullText != null && !isThinking && shouldAnimate)
                TypingAnimatedText(
                  fullText: message.fullText!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  shouldAnimate: shouldAnimate,
                )
              else if (message.fullText != null && !isThinking)
              // Show complete text immediately for loaded messages
                Text(
                  message.fullText!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                )
              else
                Text(
                  message.text,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),

              // Show typing cursor only for messages that should animate
              if (!isUser &&
                  message.fullText != null &&
                  shouldAnimate &&
                  !isThinking)
                const SizedBox(
                  height: 16,
                  child: Text(
                    "▋",
                    style: TextStyle(
                      color: Color(0xFFA26BFA),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              if (message.options != null && !isThinking)
                const SizedBox(height: 12),

              if (message.options != null && !isThinking)
                ...message.options!.map<Widget>((option) {
                  return GestureDetector(
                    onTap: () => onOptionTap(option, message),
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xff19172E),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.white24,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              option,
                              style: const TextStyle(
                                color: Color(0xFFC5AFFF),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xFFC5AFFF),
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserAvatar(ChatMessage message) {
    // If we have a valid image URL, use it
    if (message.userImage != null &&
        message.userImage!.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.only(left: 8, top: 5),
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(message.userImage!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Otherwise, use the user's name initial
    String userInitial = 'U';

    if (message.userName != null && message.userName!.isNotEmpty) {
      userInitial = message.userName![0].toUpperCase();
    } else {
      // If no name, try to extract from text
      final text = message.text;
      if (text.isNotEmpty) {
        final firstWord = text.trim().split(' ').first;
        if (firstWord.isNotEmpty) {
          userInitial = firstWord[0].toUpperCase();
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(left: 8, top: 5),
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: _getAvatarColor(userInitial),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          userInitial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(String initial) {
    final colors = [
      const Color(0xFFA26BFA), // Purple
      const Color(0xFF2196F3), // Blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFFF44336), // Red
      const Color(0xFF9C27B0), // Deep Purple
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF673AB7), // Deep Purple
    ];

    final charCode = initial.codeUnitAt(0);
    final index = charCode % colors.length;
    return colors[index];
  }
}