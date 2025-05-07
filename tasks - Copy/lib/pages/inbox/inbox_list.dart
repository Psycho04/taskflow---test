import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasks/providers/inbox_provider.dart';
import 'package:intl/intl.dart';
import 'chat_screen.dart';
import 'users_list.dart';

class InboxListPage extends StatefulWidget {
  static const String routeName = 'InboxList';

  const InboxListPage({Key? key}) : super(key: key);

  @override
  State<InboxListPage> createState() => _InboxListPageState();
}

class _InboxListPageState extends State<InboxListPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchSenders();
      }
    });
  }

  Future<void> _fetchSenders() async {
    setState(() {
      _isLoading = true;
    });

    await Provider.of<InboxProvider>(context, listen: false).fetchSenders();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return '';

    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return DateFormat.jm().format(dateTime); // Today, show time
      } else if (difference.inDays < 7) {
        return DateFormat.E().format(dateTime); // Within a week, show day name
      } else {
        return DateFormat.yMd().format(dateTime); // Older, show date
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          // Add new message button
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'New Message',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UsersListPage()),
              ).then((_) => _fetchSenders());
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSenders,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSenders,
        child: Consumer<InboxProvider>(
          builder: (context, inboxProvider, child) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (inboxProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${inboxProvider.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchSenders,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (inboxProvider.senders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inbox, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Your inbox is empty',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Messages from other users will appear here',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: inboxProvider.senders.length,
              itemBuilder: (context, index) {
                final sender = inboxProvider.senders[index];
                final bool hasUnreadMessages = sender['lastMessage'] != null &&
                    sender['lastMessage']['isRead'] == false;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: sender['image'] != null
                        ? NetworkImage(
                            'http://localhost:5000/uploads/${sender['image']}')
                        : null,
                    child: sender['image'] == null
                        ? Text(
                            sender['name']?.substring(0, 1).toUpperCase() ??
                                '?',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  title: Row(
                    children: [
                      Text(
                        sender['name'] ?? 'Unknown',
                        style: TextStyle(
                          fontWeight: hasUnreadMessages
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Show a message icon to indicate this user sent you a message
                      if (hasUnreadMessages)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.mail,
                                size: 14,
                                color: Colors.blue,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'New',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  subtitle: sender['lastMessage'] != null
                      ? Text(
                          sender['lastMessage']['content'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: hasUnreadMessages
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: hasUnreadMessages
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        )
                      : null,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (sender['lastMessage'] != null)
                        Text(
                          _formatDateTime(sender['lastMessage']['createdAt']),
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                hasUnreadMessages ? Colors.blue : Colors.grey,
                          ),
                        ),
                      if (hasUnreadMessages) const SizedBox(height: 4),
                      if (hasUnreadMessages)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '',
                            style: TextStyle(fontSize: 8),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(userId: sender['_id']),
                      ),
                    ).then((_) => _fetchSenders());
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
