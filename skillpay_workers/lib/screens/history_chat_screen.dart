import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/messages_service.dart';
import '../models/message_model.dart';
import 'package:intl/intl.dart';

class HistoryChatScreen extends StatefulWidget {
  final String conversationId;
  final String clientName;
  final String? clientAvatarUrl;
  final String? jobTitle;

  const HistoryChatScreen({
    super.key,
    required this.conversationId,
    required this.clientName,
    this.clientAvatarUrl,
    this.jobTitle,
  });

  @override
  State<HistoryChatScreen> createState() => _HistoryChatScreenState();
}

class _HistoryChatScreenState extends State<HistoryChatScreen> {
  final _messagesService = MessagesService();
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  String _getInitials(String name) {
    if (name.isEmpty) return 'H';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
  
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _myUserId;
  File? _selectedFile;
  bool _isUploading = false;
  bool _isOtherUserTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _messagesService.getMyPrismaUserId().then((id) {
      if (mounted) {
        setState(() => _myUserId = id);
        if (!_isLoading) {
          _setupRealtime();
        }
      }
    });
    _loadMessages();
  }



  Future<void> _loadMessages() async {
    try {
      final messages = await _messagesService.fetchMessages(widget.conversationId);
      if (mounted) {
        setState(() {
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
    if (_myUserId == null) return;
    _messagesService.subscribeToMessages(
      conversationId: widget.conversationId,
      currentUserId: _myUserId!,
      onMessage: (message) {
        if (mounted) {
          if (_messages.any((m) => m.id == message.id)) return;
          
          setState(() {
            _messages.insert(0, message);
          });
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
      },
      onTyping: (isTyping) {
        if (mounted) {
          setState(() => _isOtherUserTyping = isTyping);
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
    final result = await FilePicker.pickFiles(
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
    _typingTimer?.cancel();
    _messagesService.unsubscribe();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTypingChanged(String value) {
    if (_myUserId == null) return;
    
    _messagesService.updateTypingStatus(_myUserId!, true);
    
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      _messagesService.updateTypingStatus(_myUserId!, false);
    });
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
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade700],
                ),
              ),
              child: ClipOval(
                child: (widget.clientAvatarUrl != null && widget.clientAvatarUrl!.isNotEmpty)
                    ? Image.network(
                        widget.clientAvatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            _getInitials(widget.clientName),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          _getInitials(widget.clientName),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (widget.jobTitle?.isNotEmpty == true)
                        ? widget.jobTitle!
                        : widget.clientName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _isOtherUserTyping
                        ? 'typing...'
                        : ((widget.jobTitle?.isNotEmpty == true)
                            ? widget.clientName
                            : 'Client'),
                    style: TextStyle(
                      fontSize: 11,
                      color: _isOtherUserTyping ? Colors.green.shade700 : Colors.grey.shade600,
                      fontWeight: _isOtherUserTyping ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
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
                            final isMe = msg.senderRole != null
                                ? msg.senderRole == 'ARTISAN'
                                : msg.senderId == _myUserId;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
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
                  if (_isOtherUserTyping)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 8),
                        child: Text(
                          'Typing...',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
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
                        onChanged: _onTypingChanged,
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
    final maxWidth = MediaQuery.of(context).size.width * 0.78;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFFFC107) : const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(3),
            bottomRight: isMe ? const Radius.circular(3) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
              if (text.isNotEmpty) const SizedBox(height: 6),
            ],
            if (text.isNotEmpty)
              Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.3,
                  fontWeight: FontWeight.w400,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Spacer(),
                Text(
                  time,
                  style: TextStyle(
                    color: isMe ? Colors.white.withAlpha(190) : Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  if (isSending)
                    Icon(Icons.access_time, size: 12, color: Colors.white.withAlpha(190))
                  else if (hasError)
                    const Icon(Icons.error_outline, size: 12, color: Colors.red)
                  else
                    Icon(Icons.done_all, size: 14, color: Colors.white.withAlpha(220)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

