import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soundhive2/lib/dashboard_provider/chat_send_provider.dart';
import 'package:soundhive2/lib/dashboard_provider/getChatProvider.dart';
import 'package:soundhive2/model/chat_send_model.dart';

import '../../../model/user_model.dart';

class Message {
  final String text;
  final String time;
  final bool isMe;
  final bool isSystem;
  final List<String>? fileUrls; // Now only stores URLs
  final List<File>? pendingFiles;

  Message({
    required this.text,
    required this.time,
    this.isMe = false,
    this.isSystem = false,
    this.pendingFiles,
    this.fileUrls,
  });
  Message copyWith({
    String? text,
    List<String>? fileUrls,
    List<File>? pendingFiles,
  }) {
    return Message(
      text: text!,
      time: time,
      isMe: isMe,
      isSystem: isSystem,
      fileUrls: fileUrls ?? this.fileUrls,
      pendingFiles: pendingFiles ?? this.pendingFiles,
    );
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  final String sellerId;
  final String sellerName;
  final String sellerService;
  final User user;
  const ChatScreen({Key? key, required this.sellerId, required this.user, required this.sellerName, required this.sellerService}) : super(key: key);
  @override
  _ChatScreenScreenState createState() => _ChatScreenScreenState();
}

class _ChatScreenScreenState extends ConsumerState<ChatScreen> {
  List<File> _pendingFiles = [];
  String _pendingText = '';
  List<Message> _messages = [];

  final TextEditingController _controller = TextEditingController();

  void _handleFilesSelected(List<File> files) {
    setState(() {
      _pendingFiles.addAll(files);
    });
  }
  Future<String> _uploadFileToCloudinary(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
      'upload_preset': 'soundhive',
    });

    final response = await Dio().post(
      'https://api.cloudinary.com/v1_1/image/upload',
      data: formData,
    );

    if (response.statusCode != 200) {
      throw Exception('Upload failed: ${response.data}');
    }

    return response.data['secure_url'] as String;
  }

  Future<void> _submitToBackend(String text) async {
    try {
      String finalMessage = text;
      List<String> uploadedUrls = [];
      // Upload files first if any
      if (_pendingFiles.isNotEmpty) {
        for (final file in _pendingFiles) {
          final url = await _uploadFileToCloudinary(file);
          uploadedUrls.add(url);
        }

        // Append URLs to the message
        if (text.isNotEmpty) {
          finalMessage = '$text\n\nAttachments:\n${uploadedUrls.join('\n')}';
        } else {
          finalMessage = 'Attachments:\n${uploadedUrls.join('\n')}';
        }
      }

      // Send to backend with only receiver_id and message
      final response = await ref.read(chatSendProvider.notifier).sendMessage(
        receiverId: widget.sellerId,
        message: finalMessage,
      );

      if (response.message == "Message sent") {
        // Update the message with URLs after successful send
        setState(() {
          _messages.last = _messages.last.copyWith(
            text: finalMessage,
            fileUrls: _pendingFiles.isNotEmpty ? uploadedUrls : null,
          );
        });
        _pendingFiles.clear();
        _controller.clear();
      }
    } catch (e) {
      print('Error sending message: $e');
      // Remove the optimistic message if failed
      setState(() {
        if (_messages.isNotEmpty) _messages.removeLast();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: ${e.toString()}')),
      );
    }
  }

  void _sendMessage(String text) {
    if (text.isEmpty && _pendingFiles.isEmpty) return;

    setState(() {
      _messages.add(Message(
        text: text,
        pendingFiles: _pendingFiles.isEmpty ? null : List.from(_pendingFiles),
        time: _getCurrentTime(),
        isMe: true,
      ));
      _pendingText = '';
    });
    _submitToBackend(text);
    _pendingFiles.clear();
    _controller.clear();
  }
  void _removeFile(int index) {
    setState(() {
      _pendingFiles.removeAt(index);
    });
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '${hour}:${now.minute.toString().padLeft(2, '0')} $period';
  }
  String _formatApiTime(String createdAt) {
    final dateTime = DateTime.parse(createdAt).toLocal();
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour}:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }
  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
  }

  Future<void> _loadInitialMessages() async {
    // Load system message first
    _messages = [
      Message(
        text: "Do not mark this job as completed this if your job has not been completed",
        time: '',
        isSystem: true,
        pendingFiles: [],
      ),
    ];

    // Load API messages
    await ref.read(getChatProvider.notifier).getChat(widget.sellerId);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(getChatProvider);
    return Scaffold(
      backgroundColor: Color(0xFF050110),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A191E),
        title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.sellerName, style: TextStyle(color: Colors.white, fontSize: 14),),
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
      ),
      body: chatState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error', style: TextStyle(color: Colors.white),)),
        data: (apiChats) {
          // Convert API data to Message objects
          final apiMessages = apiChats.map((chat) => Message(
            text: chat.message,
            time: _formatApiTime(chat.createdAt),
            isMe: chat.senderId == widget.user.memberId,
            fileUrls: null,
          )).toList();

          // Combine system message with API messages
          final allMessages = [
            _messages.firstWhere((m) => m.isSystem),
            ...apiMessages,
            ..._messages.where((m) => !m.isSystem),
          ];

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: allMessages.length,
                  itemBuilder: (context, index) {
                    final message = allMessages[index];
                    if (message.isSystem) {
                      return _SystemMessage(message: message);
                    }
                    return _ChatBubble(message: message);
                  },
                ),
              ),
              _MessageInput(
                controller: _controller,
                onSend: _sendMessage,
                onFilesSelected: _handleFilesSelected,
                onRemoveFile: _removeFile,
                pendingFiles: _pendingFiles,
              )
            ],
          );
        },
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
          color: Color.fromRGBO(255, 221, 118, 0.1),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, color: Color(0xFFFFDD76), size: 12,),
            SizedBox(width: 8,),
            Flexible(
              child: Text(
                message.text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Color(0xFFFFDD76),
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

  const _ChatBubble({required this.message});

  Widget _buildFilePreview(File file) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: file.path.toLowerCase().endsWith('.pdf')
            ? Container(
          width: 200,
          height: 200,
          color: Colors.grey[800],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.picture_as_pdf, size: 48, color: Colors.white),
              Text('PDF Document', style: TextStyle(color: Colors.white)),
            ],
          ),
        )
            : Image.file(file, width: 200, height: 200, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildUrlPreview(String url) {
    final isImage = url.toLowerCase().contains('.jpg') ||
        url.toLowerCase().contains('.png') ||
        url.toLowerCase().contains('.jpeg');
    final isPdf = url.toLowerCase().contains('.pdf');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: isPdf
            ? Container(
          width: 200,
          height: 200,
          color: Colors.grey[800],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.picture_as_pdf, size: 48, color: Colors.white),
              Text('PDF Document', style: TextStyle(color: Colors.white)),
              Text('(Uploaded)', style: TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        )
            : isImage
            ? Image.network(url, width: 200, height: 200, fit: BoxFit.cover)
            : Container(
          width: 200,
          height: 200,
          color: Colors.grey[800],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.insert_drive_file, size: 48, color: Colors.white),
                Text('Download File', style: TextStyle(color: Colors.white)),
                Text('(Uploaded)', style: TextStyle(color: Colors.white70, fontSize: 10)),
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
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: message.isMe
              ? const Color(0xFF4D3490)
              : const Color(0xFF1A191E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.pendingFiles != null)
              ...message.pendingFiles!.map((file) => _buildFilePreview(file)),
            if (message.fileUrls != null)
              ...message.fileUrls!.map((url) => _buildUrlPreview(url)),


            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8
              ),
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
                    message.time,
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
  final List<File> pendingFiles;

  const _MessageInput({
    required this.controller,
    required this.onSend,
    required this.onFilesSelected,
    required this.onRemoveFile,
    required this.pendingFiles,
  });

  void _handleAttachment(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Photo & Video'),
                onTap: () async {
                  Navigator.pop(context);
                  final files = await ImagePicker().pickMultiImage();
                  if (files.isNotEmpty) {
                    onFilesSelected(files.map((f) => File(f.path)).toList());
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Document'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await FilePicker.platform.pickFiles(
                    allowMultiple: true,
                  );
                  if (result != null) {
                    onFilesSelected(result.paths.map((p) => File(p!)).toList());
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await ImagePicker().pickImage(source: ImageSource.camera);
                  if (file != null) onFilesSelected([File(file.path)]);
                },
              ),
            ],
          ),
        );
      },
    );
  }

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
                              ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.picture_as_pdf,
                                  color: Colors.white, size: 40),
                              Text('PDF',
                                  style: TextStyle(color: Colors.white)),
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
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close,
                                  size: 16, color: Colors.white),
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
                  // IconButton(
                  //   icon: Icon(Icons.attach_file, color: Colors.white),
                  //   onPressed: () => _handleAttachment(context),
                  // ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: pendingFiles.isEmpty
                            ? 'Type something'
                            : 'Add a caption',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onSubmitted: onSend,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
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