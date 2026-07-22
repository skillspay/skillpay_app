import 'package:flutter/material.dart';
import 'history_chat_screen.dart'; // We can reuse the chat screen we built earlier

class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  // Using a boolean to easily toggle empty state for testing
  final bool _isEmpty = false; 

  final List<Map<String, dynamic>> _mockMessages = [
    {
      'name': 'James Walker',
      'message': 'Hi, are you available for a pro...',
      'time': '1m Ago',
      'isActive': true,
      'imageUrl': 'https://i.pravatar.cc/150?u=a04258114e29026702d',
      'isRead': false,
    },
    {
      'name': 'Bluecollar',
      'message': 'Hi, are you available for a pro...',
      'time': '1m Ago',
      'isActive': true,
      'imageUrl': 'https://i.pravatar.cc/150?u=2',
      'isRead': false,
    },
    {
      'name': 'Bluecollar',
      'message': 'Hi, are you available for a pro...',
      'time': '1m Ago',
      'isActive': false,
      'imageUrl': 'https://i.pravatar.cc/150?u=3',
      'isRead': true,
    },
    {
      'name': 'Bluecollar',
      'message': 'Hi, are you available for a pro...',
      'time': '1m Ago',
      'isActive': false,
      'imageUrl': 'https://i.pravatar.cc/150?u=4',
      'isRead': true,
    },
    {
      'name': 'Bluecollar',
      'message': 'Hi, are you available for a pro...',
      'time': '1m Ago',
      'isActive': true,
      'imageUrl': 'https://i.pravatar.cc/150?u=5',
      'isRead': true,
    },
    {
      'name': 'James Walker',
      'message': 'Hi, are you available for a pro...',
      'time': '1m Ago',
      'isActive': false,
      'imageUrl': 'https://i.pravatar.cc/150?u=a04258114e29026702d',
      'isRead': true,
    },
    {
      'name': 'Bluecollar',
      'message': 'Hi, are you available for a pro...',
      'time': '1m Ago',
      'isActive': false,
      'imageUrl': 'https://i.pravatar.cc/150?u=6',
      'isRead': true,
    },
    {
      'name': 'Bluecollar',
      'message': 'Hi, are you available for a pro...',
      'time': '1m Ago',
      'isActive': true,
      'imageUrl': 'https://i.pravatar.cc/150?u=7',
      'isRead': true,
    },
    {
      'name': 'Bluecollar',
      'message': 'Hi, are you available for a pro...',
      'time': '1m Ago',
      'isActive': false,
      'imageUrl': 'https://i.pravatar.cc/150?u=8',
      'isRead': true,
    },
  ];

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
              child: const TextField(
                decoration: InputDecoration(
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
            child: _isEmpty ? _buildEmptyState() : _buildMessagesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No messages yet',
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: _mockMessages.length,
      separatorBuilder: (context, index) => Divider(color: Colors.grey[200], height: 1),
      itemBuilder: (context, index) {
        final message = _mockMessages[index];
        return _buildMessageTile(message);
      },
    );
  }

  Widget _buildMessageTile(Map<String, dynamic> message) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryChatScreen(clientName: message['name']),
          ),
        );
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
              image: DecorationImage(
                image: NetworkImage(message['imageUrl']),
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (message['isActive'])
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
        message['name'],
        style: TextStyle(
          fontWeight: message['isRead'] ? FontWeight.normal : FontWeight.bold,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        message['message'],
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: message['isRead'] ? Colors.grey[600] : Colors.black87,
          fontWeight: message['isRead'] ? FontWeight.normal : FontWeight.w500,
          fontSize: 13,
        ),
      ),
      trailing: Text(
        message['time'],
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 12,
        ),
      ),
    );
  }
}
