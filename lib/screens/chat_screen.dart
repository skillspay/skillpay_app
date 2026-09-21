import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:skillpay/models/message_model.dart';
import 'package:skillpay/services/messages_service.dart';
import 'package:skillpay/services/jobs_service.dart';
import 'package:skillpay/theme/app_theme.dart';
import 'package:skillpay/screens/hire_artisan_screen.dart';
import 'package:skillpay/models/chat_model.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final String artisanName;
  final String conversationId;
  final String? artisanAvatarUrl;
  final String? jobTitle;
  final Map<String, dynamic>? artisanData;

  const ChatScreen({
    super.key,
    required this.artisanName,
    required this.conversationId,
    this.artisanAvatarUrl,
    this.jobTitle,
    this.artisanData,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessagesService _messagesService = MessagesService();

  List<MessageModel> _messages = [];
  bool _isLoading = true;
  String? _currentUserId;
  File? _selectedFile;
  bool _isUploading = false;
  bool _canHire = false;
  Map<String, dynamic>? _artisanData;
  bool _isOtherUserTyping = false;
  Timer? _typingTimer;

  String _getInitials(String name) {
    if (name.isEmpty) return 'A';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _messagesService.getMyPrismaUserId().then((id) {
      if (mounted) {
        setState(() => _currentUserId = id);
        _subscribeToRealtime();
      }
    });
    _loadMessages();
    _checkHireEligibility();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _messagesService.unsubscribe();
    super.dispose();
  }

  Future<void> _checkHireEligibility() async {
    try {
      final chats = await _messagesService.fetchConversations();
      final chat = chats.cast<ChatModel?>().firstWhere(
        (c) => c?.id == widget.conversationId, 
        orElse: () => null
      );
      
      if (chat != null && chat.jobId.isNotEmpty) {
        final job = await JobsService().fetchJob(chat.jobId);
        
        if (mounted) {
          setState(() {
            _artisanData = widget.artisanData ?? {
              'id': chat.artisanId,
              'name': chat.artisanName,
              'jobId': chat.jobId,
            };
            
            if (job.isPending || job.isPublished) {
              _canHire = true;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking hire eligibility: $e');
    }
  }


  Future<void> _loadMessages() async {
    try {
      final msgs = await _messagesService.fetchMessages(
        widget.conversationId,
        limit: 50,
      );
      if (mounted) {
        setState(() {
          final seen = <String>{};
          _messages = msgs.where((m) => seen.add(m.id)).toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addOrUpdateMessage(MessageModel msg) {
    if (!mounted) return;
    setState(() {
      // 1. If real message ID already in list, do not duplicate
      if (_messages.any((m) => m.id == msg.id)) return;

      // 2. If there's an optimistic placeholder matching this message, replace it
      final optimisticIdx = _messages.indexWhere(
        (m) => m.id.startsWith('optimistic_') && m.message == msg.message,
      );
      if (optimisticIdx != -1) {
        _messages[optimisticIdx] = msg;
      } else {
        _messages.add(msg);
      }
    });
    _scrollToBottom();
  }

  void _subscribeToRealtime() {
    if (_currentUserId == null) return;
    _messagesService.subscribeToMessages(
      conversationId: widget.conversationId,
      currentUserId: _currentUserId!,
      onMessage: (msg) {
        _addOrUpdateMessage(msg);
      },
      onTyping: (isTyping) {
        if (mounted) {
          setState(() => _isOtherUserTyping = isTyping);
        }
      },
    );
  }

  void _onTypingChanged(String value) {
    if (_currentUserId == null) return;
    
    // Notify we are typing
    _messagesService.updateTypingStatus(_currentUserId!, true);
    
    // Reset timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      _messagesService.updateTypingStatus(_currentUserId!, false);
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
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

    final optimisticMsg = MessageModel(
      id: 'optimistic_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversationId,
      senderId: _currentUserId ?? '',
      senderRole: 'HOMEOWNER',
      message: text,
      attachmentUrls: uploadedUrl != null ? [uploadedUrl] : [],
      seen: false,
      createdAt: DateTime.now(),
      isSending: true,
    );

    _messageController.clear();

    setState(() {
      _messages.add(optimisticMsg);
    });
    _scrollToBottom();

    try {
      final sent = await _messagesService.sendMessage(
        conversationId: widget.conversationId,
        message: text,
        attachmentUrls: optimisticMsg.attachmentUrls,
      );
      if (mounted) {
        setState(() {
          _isUploading = false;
          // If WebSocket already added the message, remove the optimistic placeholder
          if (_messages.any((m) => m.id == sent.id)) {
            _messages.removeWhere((m) => m.id == optimisticMsg.id);
          } else {
            final index = _messages.indexWhere((m) => m.id == optimisticMsg.id);
            if (index != -1) {
              _messages[index] = sent;
            } else {
              _messages.add(sent);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
          optimisticMsg.isSending = false;
          optimisticMsg.hasError = true;
        });
      }
    }

    // Mark conversation as seen
    await _messagesService.markConversationAsSeen(widget.conversationId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                  colors: [Colors.amber.shade400, Colors.amber.shade600],
                ),
              ),
              child: ClipOval(
                child: (widget.artisanAvatarUrl != null && widget.artisanAvatarUrl!.isNotEmpty)
                    ? Image.network(
                        widget.artisanAvatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            _getInitials(widget.artisanName),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          _getInitials(widget.artisanName),
                          style: GoogleFonts.outfit(
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
                        : widget.artisanName,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _isOtherUserTyping
                        ? 'typing...'
                        : ((widget.jobTitle?.isNotEmpty == true)
                            ? widget.artisanName
                            : 'Online'),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: _isOtherUserTyping
                          ? Colors.amber.shade300
                          : Colors.white70,
                      fontWeight: _isOtherUserTyping ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_canHire && _artisanData != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HireArtisanScreen(artisanData: _artisanData!),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Hire now',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary))
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Start a conversation',
                          style: GoogleFonts.outfit(
                              color: AppColors.textMedium),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.senderRole != null
                              ? msg.senderRole == 'HOMEOWNER'
                              : msg.senderId == _currentUserId;
                          final time =
                              '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';
                          return _buildBubble(
                            text: msg.message,
                            attachmentUrls: msg.attachmentUrls,
                            time: time,
                            isMe: isMe,
                            isSending: msg.isSending,
                            hasError: msg.hasError,
                          );
                        },
                      ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildBubble({
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
          color: isMe ? AppColors.primary : const Color(0xFFF2F4F7),
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
                            style: GoogleFonts.outfit(
                              color: isMe ? Colors.white : AppColors.textDark,
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
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  height: 1.3,
                  color: isMe ? Colors.white : AppColors.textDark,
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
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: isMe ? Colors.white.withAlpha(190) : AppColors.textMedium,
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

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
            top: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
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
                        color: const Color(0xFFF0F0F0),
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
                  color: AppColors.textMedium,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          Row(
            children: [
              GestureDetector(
                onTap: _showAttachmentOptions,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F0F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.attach_file, color: AppColors.textMedium, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: const Color(0xFFE0E0E0), width: 1),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: GoogleFonts.outfit(
                        color: const Color(0xFFB0B0B0),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                    ),
                    style: GoogleFonts.outfit(
                        fontSize: 14, color: AppColors.textDark),
                    onChanged: _onTypingChanged,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _isUploading ? null : _sendMessage,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isUploading ? Colors.grey : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: _isUploading 
                      ? const Padding(
                          padding: EdgeInsets.all(14.0),
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
