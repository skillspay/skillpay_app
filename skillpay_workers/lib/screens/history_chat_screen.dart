import 'package:flutter/material.dart';
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
  final String? _myUserId = Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _messagesService.unsubscribe();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();

    try {
      // The real-time listener will pick this up and add it to the UI, 
      // but we can optionally add it optimistically or just wait for the DB event.
      // Since subscribeToMessages receives events immediately, waiting is fine.
      await _messagesService.sendMessage(
        conversationId: widget.conversationId,
        message: text,
      );
    } catch (e) {
      if (mounted) {
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
                                time: _formatTime(msg.createdAt),
                                isMe: isMe,
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
              child: Row(
                children: [
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
                  // const Icon(Icons.attach_file, color: Colors.grey), // Future iteration: attachment upload
                  // const SizedBox(width: 12),
                  InkWell(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFC107),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
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

  Widget _buildMessageBubble({required String text, required String time, required bool isMe}) {
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
          child: Text(
            text,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
        if (time.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ]
      ],
    );
  }
}

