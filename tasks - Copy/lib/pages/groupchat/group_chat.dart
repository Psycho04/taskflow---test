import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'dart:math';

class GroupChatPage extends StatefulWidget {
  const GroupChatPage({Key? key}) : super(key: key);

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _error;
  String? _token;
  Map<String, dynamic>? _userData;
  String? _editingMessageId;
  final TextEditingController _editMessageController = TextEditingController();

  // Helper method to check if the current user is an admin
  bool get isAdmin => _userData != null && _userData!['role'] == 'admin';

  // Group chat lock status
  bool _isGroupLocked = false;

  // Key for storing group lock status in SharedPreferences
  static const String _groupLockKey = 'group_chat_locked';

  // Method to toggle the lock status of the group chat
  Future<void> _toggleGroupLock() async {
    if (!isAdmin) return; // Only admins can toggle lock

    try {
      // Update the local state
      setState(() {
        _isGroupLocked = !_isGroupLocked;
      });

      // Save the lock status to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_groupLockKey, _isGroupLocked);

      // Show a message to indicate the new status
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isGroupLocked
              ? 'Group chat locked. Only admins can send messages.'
              : 'Group chat unlocked. Everyone can send messages.'),
          duration: const Duration(seconds: 3),
        ),
      );

      // In a real app, you would also send this status to the server
      // Example API call:
      // final response = await http.put(
      //   Uri.parse('$_baseUrl/group-chat/lock'),
      //   headers: {
      //     'Authorization': 'Bearer $_token',
      //     'Content-Type': 'application/json',
      //   },
      //   body: json.encode({'locked': _isGroupLocked}),
      // );
    } catch (e) {
      // Revert the change if there's an error
      setState(() {
        _isGroupLocked = !_isGroupLocked;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update group settings: $e')),
      );
    }
  }

  // Method to load the group lock status from SharedPreferences
  Future<void> _loadGroupLockStatus() async {
    try {
      // Show a subtle loading indicator in the UI
      if (mounted) {
        setState(() {
          _error = 'Loading group settings...';
        });
      }

      final prefs = await SharedPreferences.getInstance();
      final isLocked = prefs.getBool(_groupLockKey);

      if (isLocked != null && mounted) {
        setState(() {
          _isGroupLocked = isLocked;
          // Don't clear the error message here, as it might be set by other operations
        });

        // Log the loaded status for debugging
        debugPrint(
            'Group chat lock status loaded: ${isLocked ? 'Locked' : 'Unlocked'}');
      }
    } catch (e) {
      // If there's an error loading the lock status, just use the default value
      // We'll silently ignore the error and use the default value
      debugPrint('Error loading group lock status: $e');
    }
  }

  // Helper method to check if the current user can send messages
  bool get canSendMessages => !_isGroupLocked || isAdmin;

  // Get the correct API URL based on platform
  String get _baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api/v1'; // Android emulator
    }
    return 'http://localhost:5000/api/v1'; // iOS simulator or web
  }

  @override
  void initState() {
    super.initState();
    // Initialize chat immediately
    _initializeChat();

    // Add a delayed retry as a backup in case the first attempt fails
    Future.delayed(const Duration(milliseconds: 800), () {
      if (_isLoading || _error != null) {
        // If still loading or has error after 800ms, try again
        _fetchMessages(retryCount: 1);
      }
    });
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
      _error = 'Initializing chat...';
    });

    try {
      // First load user data
      await _loadUserData();

      // Load the group lock status
      await _loadGroupLockStatus();

      // Then directly fetch messages without checking server connection first
      if (_token != null) {
        await _fetchMessages();
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Not authenticated';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error initializing chat: $e';
      });
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final userDataString = prefs.getString('userData');
    if (userDataString != null) {
      _userData = json.decode(userDataString);
    }
  }

  Future<void> _fetchMessages({int retryCount = 0}) async {
    if (_token == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Not authenticated';
      });
      return;
    }

    try {
      // Add a loading message to the UI
      setState(() {
        _isLoading = true;
        _error = retryCount > 0
            ? 'Retrying... ($retryCount)'
            : 'Loading messages...';
      });

      // Use the correct endpoint - the group chat endpoint doesn't have a /messages suffix for GET
      final url = '$_baseUrl/group-chat';

      // Add a timeout to the request
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;

        setState(() {
          try {
            // Based on the controller code, the response format should be:
            // { status: "success", data: { messages: [...] } }
            if (data['status'] == 'success' && data['data'] != null) {
              if (data['data']['messages'] != null) {
                _messages =
                    List<Map<String, dynamic>>.from(data['data']['messages']);
              } else {
                // If the group chat has no messages yet
                _messages = [];
              }
              _isLoading = false;
              _error = null;
            } else {
              // Unexpected response format
              _error =
                  'Unexpected response format: ${data.toString().substring(0, min(200, data.toString().length))}';
              _messages = [];
              _isLoading = false;

              // Auto-retry once if we get an unexpected format
              if (retryCount < 1) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  _fetchMessages(retryCount: retryCount + 1);
                });
              }
            }
          } catch (e) {
            // Error parsing the response
            _error =
                'Error parsing response: $e\nResponse: ${data.toString().substring(0, min(200, data.toString().length))}';
            _messages = [];
            _isLoading = false;

            // Auto-retry once if we get a parsing error
            if (retryCount < 1) {
              Future.delayed(const Duration(milliseconds: 500), () {
                _fetchMessages(retryCount: retryCount + 1);
              });
            }
          }
        });
      } else if (response.statusCode == 404) {
        // Special handling for 404 errors - auto retry once
        if (retryCount < 1) {
          if (!mounted) return;
          setState(() {
            _error = 'Server returned error: 404. Retrying...';
          });

          // Wait a bit longer before retrying
          await Future.delayed(const Duration(seconds: 1));
          await _fetchMessages(retryCount: retryCount + 1);
        } else {
          if (!mounted) return;
          setState(() {
            _error = 'Server returned error: 404';
            _isLoading = false;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _error =
              'Failed to load messages (${response.statusCode}): ${response.body}';
          _isLoading = false;

          // Auto-retry once for other status codes
          if (retryCount < 1) {
            Future.delayed(const Duration(milliseconds: 800), () {
              _fetchMessages(retryCount: retryCount + 1);
            });
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error connecting to server: $e';
        _isLoading = false;

        // Auto-retry once for connection errors
        if (retryCount < 1) {
          Future.delayed(const Duration(seconds: 1), () {
            _fetchMessages(retryCount: retryCount + 1);
          });
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    // Check if the message is empty or if the user is not authenticated
    if (_messageController.text.trim().isEmpty || _token == null) return;

    // Check if the user can send messages (group is not locked or user is admin)
    if (!canSendMessages) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot send message: Group chat is locked by admin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final message = _messageController.text.trim();
    _messageController.clear();

    try {
      // Show sending indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending message...')),
      );

      final response = await http.post(
        Uri.parse('$_baseUrl/group-chat/messages'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'content': message}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _fetchMessages();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to send message: ${response.statusCode} - ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  Future<void> _updateMessage(String messageId, String newContent) async {
    if (newContent.trim().isEmpty || _token == null) return;

    try {
      // Show updating indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updating message...')),
      );

      final response = await http.patch(
        Uri.parse('$_baseUrl/group-chat/messages/$messageId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'content': newContent}),
      );

      if (response.statusCode == 200) {
        await _fetchMessages();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to update message: ${response.statusCode} - ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating message: $e')),
      );
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    if (_token == null) return;

    try {
      // Show deleting indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleting message...')),
      );

      final response = await http.delete(
        Uri.parse('$_baseUrl/group-chat/messages/$messageId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await _fetchMessages();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to delete message: ${response.statusCode} - ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting message: $e')),
      );
    }
  }

  Future<void> _pinMessage(String messageId) async {
    if (_token == null) return;

    try {
      // Show pinning indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updating pin status...')),
      );

      final response = await http.patch(
        Uri.parse('$_baseUrl/group-chat/messages/$messageId/pin'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await _fetchMessages();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to update pin status: ${response.statusCode} - ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating pin status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Group Chat'),
            if (_isGroupLocked)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Tooltip(
                  message: 'Only admins can send messages',
                  child: Icon(
                    Icons.lock,
                    size: 16,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          // Lock/unlock button for admin users
          if (isAdmin)
            IconButton(
              icon: Icon(_isGroupLocked ? Icons.lock_open : Icons.lock_outline),
              tooltip: _isGroupLocked ? 'Unlock group chat' : 'Lock group chat',
              onPressed: _toggleGroupLock,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh messages',
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = 'Refreshing...';
              });
              // Start a fresh fetch with no retry count
              _fetchMessages(retryCount: 0);
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Connection info',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Group Chat Information'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('API URL: $_baseUrl/group-chat'),
                      const SizedBox(height: 8),
                      Text('Authenticated: ${_token != null ? 'Yes' : 'No'}'),
                      const SizedBox(height: 8),
                      Text('User role: ${isAdmin ? 'Admin' : 'Regular user'}'),
                      const SizedBox(height: 8),
                      Text(
                          'Group status: ${_isGroupLocked ? 'Locked (only admins can send messages)' : 'Unlocked (everyone can send messages)'}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF6F8FB), // Soft background
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Reset state and retry with a fresh attempt
                                  setState(() {
                                    _isLoading = true;
                                    _error = 'Retrying...';
                                  });
                                  // Use a slight delay before retrying
                                  Future.delayed(
                                      const Duration(milliseconds: 300), () {
                                    _fetchMessages(retryCount: 0);
                                  });
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 10),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            // Handle different sender formats safely
                            final senderId = message['sender'] is Map
                                ? message['sender']['_id'] ?? ''
                                : message['sender']?.toString() ?? '';
                            final isMe = senderId == _userData?['_id'];
                            final bool isPinned = message['isPinned'] == true;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (isPinned)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.push_pin,
                                              size: 14,
                                              color: Colors.blue[700]),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Pinned',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Row(
                                    mainAxisAlignment: isMe
                                        ? MainAxisAlignment.end
                                        : MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Add an admin indicator for messages the admin can interact with
                                      if (isAdmin && !isMe)
                                        Tooltip(
                                          message:
                                              'Admin: Long press to manage this message',
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                                top: 8, right: 4),
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withAlpha(25),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Icon(
                                              Icons.admin_panel_settings,
                                              size: 12,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                        ),
                                      if (!isMe)
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.blue.shade100,
                                          child: Text(
                                            (message['sender'] is Map
                                                    ? message['sender']
                                                            ['name'] ??
                                                        'U'
                                                    : 'U')[0]
                                                .toUpperCase(),
                                            style: const TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      if (!isMe) const SizedBox(width: 8),
                                      Flexible(
                                        child: Column(
                                          crossAxisAlignment: isMe
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                          children: [
                                            if (!isMe)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 2),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      message['sender'] is Map
                                                          ? message['sender']
                                                                  ['name'] ??
                                                              'Unknown'
                                                          : 'Unknown',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors
                                                            .blueGrey[700],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    // Show admin badge if the sender is an admin
                                                    if (message['sender']
                                                            is Map &&
                                                        message['sender']
                                                                ['role'] ==
                                                            'admin')
                                                      Container(
                                                        margin: const EdgeInsets
                                                            .only(left: 4),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 4,
                                                                vertical: 1),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.blue
                                                              .withAlpha(40),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                        ),
                                                        child: Text(
                                                          'Admin',
                                                          style: TextStyle(
                                                            fontSize: 9,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: Colors
                                                                .blue[800],
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            GestureDetector(
                                              onLongPress: (isMe || isAdmin)
                                                  ? () {
                                                      _showMessageOptions(
                                                          message, isMe);
                                                    }
                                                  : null,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 10,
                                                        horizontal: 16),
                                                decoration: BoxDecoration(
                                                  color: isPinned
                                                      ? (isMe
                                                          ? Colors.blue[400]
                                                          : Colors.blue[50])
                                                      : (isMe
                                                          ? Colors.blue[300]
                                                          : const Color(
                                                              0xFFF0F1F5)),
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topLeft:
                                                        const Radius.circular(
                                                            18),
                                                    topRight:
                                                        const Radius.circular(
                                                            18),
                                                    bottomLeft: Radius.circular(
                                                        isMe ? 18 : 4),
                                                    bottomRight:
                                                        Radius.circular(
                                                            isMe ? 4 : 18),
                                                  ),
                                                  border: isMe
                                                      ? null
                                                      : Border.all(
                                                          color: Colors
                                                              .grey.shade300,
                                                          width: 1),
                                                ),
                                                child: Text(
                                                  message['content'] ?? '',
                                                  style: TextStyle(
                                                    color: isMe
                                                        ? Colors.white
                                                        : Colors.black87,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isMe) const SizedBox(width: 8),
                                      if (isMe)
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.blue.shade100,
                                          child: Text(
                                            (_userData != null &&
                                                        _userData!.containsKey(
                                                            'name') &&
                                                        _userData!['name'] !=
                                                            null
                                                    ? _userData!['name'][0]
                                                    : 'U')
                                                .toUpperCase(),
                                            style: const TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            Container(
              color: Colors.transparent,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
              child: Column(
                children: [
                  // Show a message when the group is locked for non-admin users
                  if (_isGroupLocked && !isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock,
                                size: 16, color: Colors.amber.shade800),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Only admins can send messages right now',
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: canSendMessages
                                ? Colors.white
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: canSendMessages
                                  ? 'Type a message...'
                                  : 'Group is locked by admin',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              hintStyle: TextStyle(
                                color: canSendMessages
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400,
                              ),
                            ),
                            maxLines: null,
                            enabled: canSendMessages,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        mini: true,
                        backgroundColor:
                            canSendMessages ? Colors.blue : Colors.grey,
                        onPressed: canSendMessages ? _sendMessage : null,
                        child: const Icon(Icons.send, color: Colors.white),
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

  void _showMessageOptions(Map<String, dynamic> message, bool isOwnMessage) {
    final String messageId = message['_id'] ?? '';
    final bool isPinned = message['isPinned'] == true;

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
              // Only show edit option if it's the user's own message
              if (isOwnMessage)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Message'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditMessageDialog(messageId, message['content'] ?? '');
                  },
                ),

              // Show pin option for admin users
              if (isAdmin)
                ListTile(
                  leading:
                      Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin),
                  title: Text(isPinned ? 'Unpin Message' : 'Pin Message'),
                  onTap: () {
                    Navigator.pop(context);
                    _pinMessage(messageId);
                  },
                ),

              // Show delete option for admin users or for own messages
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Message',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(messageId);
                },
              ),

              // Show user info for admin users if it's not their own message
              if (isAdmin && !isOwnMessage && message['sender'] is Map)
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('User Info'),
                  subtitle: Text(
                      '${message['sender']['name'] ?? 'Unknown'} (${message['sender']['email'] ?? 'No email'})'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showEditMessageDialog(String messageId, String currentContent) {
    _editMessageController.text = currentContent;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Message'),
          content: TextField(
            controller: _editMessageController,
            decoration: const InputDecoration(
              hintText: 'Edit your message...',
            ),
            maxLines: null,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateMessage(messageId, _editMessageController.text);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(String messageId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Message'),
          content: const Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteMessage(messageId);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _editMessageController.dispose();
    super.dispose();
  }
}
