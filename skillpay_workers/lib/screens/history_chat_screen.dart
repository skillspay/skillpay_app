import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/messages_service.dart';
import '../models/message_model.dart';
import 'package:intl/intl.dart';

class HistoryChatScreen extends StatefulWidget {
  final String conversationId;
  final String clientName;

  const HistoryChatScreen({
    super.key,
    required this.conversationId,
    required this.clientName,
  });

  @override
  State<HistoryChatScreen> createState() => _HistoryChatScreenState();
}

class _HistoryChatScreenState extends State<HistoryChatScreen> {
  final _messagesService = MessagesService();
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _myUserId;
  File? _selectedFile;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _messagesService.getMyPrismaUserId().then((id) {
      if (mounted) setState(() => _myUserId = id);
    });
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _messagesService.fetchMessages(widget.conversationId);
      if (mounted) {
        setState(() {
          // fetchMessages usually returns latest first if ordered by createdAt DESC, 
          // but we display them in a ListView which builds top to bottom.
          // Depending on the backend ordering, we might need to reverse them. 
          // Let's assume the backend returns oldest to newest. If reversed, we handle it later.
          // Wait, chat usually shows newest at bottom. Let's reverse them and use ListView(reverse: true).
          _messages = messages.reversed.toList();
          _isLoading = false;
        });
        
        _setupRealtime();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _setupRealtime() {
    _messagesService.subscribeToMessages(
      conversationId: widget.conversationId,
      onMessage: (message) {
        if (mounted) {
          if (_messages.any((m) => m.id == message.id)) return;
          
          setState(() {
            // Insert at beginning since list is reversed
            _messages.insert(0, message);
          });
          // Scroll to bottom (which is top for reversed list)
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
      },
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Document (PDF)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickDocument();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  @override
  void dispose() {
    _messagesService.unsubscribe();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty && _selectedFile == null) return;

    setState(() {
      _isUploading = true;
    });

    String? uploadedUrl;
    if (_selectedFile != null) {
      uploadedUrl = await _messagesService.uploadAttachment(_selectedFile!);
    }
    
    setState(() {
      _selectedFile = null;
    });

    _msgController.clear();

    final optimisticMsg = MessageModel(
      id: 'optimistic_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversationId,
      senderId: _myUserId ?? '',
      message: text,
      attachmentUrls: uploadedUrl != null ? [uploadedUrl] : [],
      seen: false,
      createdAt: DateTime.now(),
      isSending: true,
    );

    setState(() {
      _messages.insert(0, optimisticMsg);
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    try {
      final sent = await _messagesService.sendMessage(
        conversationId: widget.conversationId,
        message: text,
        attachmentUrls: optimisticMsg.attachmentUrls,
      );
      if (mounted) {
        setState(() {
          _isUploading = false;
          final index = _messages.indexWhere((m) => m.id == optimisticMsg.id);
          if (index != -1) {
            _messages[index] = sent;
          } else {
            if (!_messages.any((m) => m.id == sent.id)) _messages.insert(0, sent);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          optimisticMsg.isSending = false;
          optimisticMsg.hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final aDate = DateTime(date.year, date.month, date.day);
    final timeStr = DateFormat('HH:mm').format(date);
    
    if (aDate == today) {
      return 'Today $timeStr';
    } else if (aDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday $timeStr';
    } else {
      return '${DateFormat('dd MMM').format(date)} $timeStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.clientName,
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isMe = msg.senderId == _myUserId;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                                child: _buildMessageBubble(
                                  text: msg.message,
                                  attachmentUrls: msg.attachmentUrls,
                                  time: _formatTime(msg.createdAt),
                                  isMe: isMe,
                                  isSending: msg.isSending,
                                  hasError: msg.hasError,
                                ),
                            );
                          },
                        ),
            ),
            
            // Input Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedFile != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Stack(
                        children: [
                          if (_selectedFile!.path.toLowerCase().endsWith('.pdf'))
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                              ),
                            )
                          else
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedFile!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedFile = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _showAttachmentOptions,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.attach_file, color: Colors.black54, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50], // Or white with grey border
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: TextField(
                        controller: _msgController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: _isUploading ? null : _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isUploading ? Colors.grey : const Color(0xFFFFC107),
                        shape: BoxShape.circle,
                      ),
                      child: _isUploading 
                          ? const SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);
}

  Widget _buildMessageBubble({
    required String text, 
    List<String> attachmentUrls = const [],
    required String time, 
    required bool isMe,
    bool isSending = false,
    bool hasError = false,
  }) {
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFFFFC107) : Colors.grey[100],
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
              bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (attachmentUrls.isNotEmpty) ...[
                if (attachmentUrls.first.toLowerCase().endsWith('.pdf'))
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse(attachmentUrls.first);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.white.withAlpha(50) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            color: isMe ? Colors.white : Colors.red,
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              attachmentUrls.first.split('/').last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      attachmentUrls.first,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (text.isNotEmpty) const SizedBox(height: 8),
              ],
              if (text.isNotEmpty)
                Text(
                  text,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
        if (time.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
              if (isMe && isSending) ...[
                const SizedBox(width: 4),
                const Icon(Icons.access_time, size: 10, color: Colors.grey),
              ],
              if (isMe && hasError) ...[
                const SizedBox(width: 4),
                const Icon(Icons.error_outline, size: 10, color: Colors.red),
              ],
            ],
          ),
        ]
      ],
    );
  }
}

