import 'package:flutter/material.dart';
import 'history_chat_screen.dart';
import '../services/messages_service.dart';
import '../models/chat_model.dart';

class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  final _messagesService = MessagesService();
  final _searchController = TextEditingController();

  List<ChatModel> _conversations = [];
  List<ChatModel> _filteredConversations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchConversations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final conversations = await _messagesService.fetchConversations();
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _filteredConversations = conversations;
          _isLoading = false;
        });
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

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredConversations = _conversations.where((c) {
        final nameMatch = c.homeownerName.toLowerCase().contains(query);
        final messageMatch = c.lastMessage.toLowerCase().contains(query);
        return nameMatch || messageMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // App Bar Area
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: 'Search messages...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Content Area
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error loading messages', style: TextStyle(color: Colors.red[300])),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _fetchConversations,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_filteredConversations.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty ? 'No messages yet' : 'No matching messages',
          style: TextStyle(color: Colors.grey[500], fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchConversations,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        itemCount: _filteredConversations.length,
        separatorBuilder: (context, index) => Divider(color: Colors.grey[200], height: 1),
        itemBuilder: (context, index) {
          final conversation = _filteredConversations[index];
          return _buildMessageTile(conversation);
        },
      ),
    );
  }

  Widget _buildMessageTile(ChatModel chat) {
    final hasUnread = chat.unreadCount > 0;
    
    return ListTile(
      onTap: () {
        if (hasUnread) {
          _messagesService.markConversationAsSeen(chat.id);
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryChatScreen(
              conversationId: chat.id,
              clientName: chat.homeownerName,
            ),
          ),
        ).then((_) {
          // Refresh list on return to update read status and last message
          _fetchConversations();
        });
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Stack(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
              image: chat.homeownerAvatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(chat.homeownerAvatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: chat.homeownerAvatarUrl == null
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          if (hasUnread)
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        chat.homeownerName,
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: hasUnread ? Colors.black87 : Colors.grey[600],
          fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      trailing: Text(
        chat.timeText,
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 12,
        ),
      ),
    );
  }
}
