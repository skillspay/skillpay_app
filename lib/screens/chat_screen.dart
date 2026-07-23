import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skillpay/models/message_model.dart';
import 'package:skillpay/services/messages_service.dart';
import 'package:skillpay/theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String artisanName;
  final String conversationId;

  const ChatScreen({
    super.key,
    required this.artisanName,
    required this.conversationId,
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

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _loadMessages();
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    _messagesService.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await _messagesService.fetchMessages(
        widget.conversationId,
        limit: 50,
      );
      if (mounted) {
        setState(() {
          _messages = msgs;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToRealtime() {
    _messagesService.subscribeToMessages(
      conversationId: widget.conversationId,
      onMessage: (msg) {
        if (mounted) {
          setState(() => _messages.add(msg));
          _scrollToBottom();
        }
      },
    );
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    try {
      final sent = await _messagesService.sendMessage(
        conversationId: widget.conversationId,
        message: text,
      );
      if (mounted) {
        setState(() => _messages.add(sent));
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.artisanName,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
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
                        padding: const EdgeInsets.all(24),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.senderId == _currentUserId;
                          final time =
                              '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';
                          return _buildBubble(
                            text: msg.message,
                            time: time,
                            isMe: isMe,
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
    required String time,
    required bool isMe,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: isMe ? Colors.white : AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            time,
            style: GoogleFonts.outfit(
                fontSize: 12, color: AppColors.textMedium),
          ),
        ],
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
      child: Row(
        children: [
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
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
