import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';

class InboxProvider with ChangeNotifier {
  List<Map<String, dynamic>> _senders = [];
  List<Message> _messages = [];
  Map<String, dynamic>? _currentContact;
  bool _isLoading = false;
  String? _error;
  static const String _baseUrl = 'http://localhost:5000/api';
  static const Duration _timeout = Duration(seconds: 30);
  static const String _tokenKey = 'token';

  // Getters
  List<Map<String, dynamic>> get senders => _senders;
  List<Message> get messages => _messages;
  Map<String, dynamic>? get currentContact => _currentContact;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _senders
      .where((s) =>
          s['lastMessage'] != null && s['lastMessage']['isRead'] == false)
      .length;

  String get _apiBaseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    }
    return _baseUrl;
  }

  // Get token from shared preferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get current user ID
  Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');
    if (userDataString != null) {
      final userData = json.decode(userDataString);
      return userData['_id']?.toString();
    }
    return null;
  }

  // Fetch all conversations (both sent and received messages)
  Future<void> fetchSenders() async {
    // Only set loading state and notify if not already loading
    if (!_isLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      // First, get users who have sent messages to the current user
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/inbox/senders'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'token': token,
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['senders'] != null && data['senders'] is List) {
          _senders = List<Map<String, dynamic>>.from(data['senders']);

          // Now, let's manually check for users we've sent messages to
          // by fetching the user list and checking conversations
          await _addUsersWithOutgoingMessages();
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch senders');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching senders: $_error');
    } finally {
      // Update loading state and notify once at the end
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to add users that we've sent messages to but haven't replied yet
  Future<void> _addUsersWithOutgoingMessages() async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null) return;

      // Get all users that we might have sent messages to
      final userResponse = await http.get(
        Uri.parse('$_apiBaseUrl/user'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'token': token,
        },
      ).timeout(_timeout);

      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        if (userData['users'] != null && userData['users'] is List) {
          final allUsers = List<Map<String, dynamic>>.from(userData['users']);

          // Filter out current user and users already in senders list
          final usersToCheck = allUsers.where((user) {
            final userId = user['_id']?.toString();
            return userId != currentUserId &&
                !_senders.any((sender) => sender['_id'] == userId);
          }).toList();

          // If we have users to check, get conversations for Adel Khaled first
          for (final user in usersToCheck) {
            final userId = user['_id']?.toString();
            final userName = user['name']?.toString() ?? '';

            // Prioritize checking Adel Khaled first
            if (userName.toLowerCase().contains('adel') ||
                userName.toLowerCase().contains('khaled')) {
              await _checkAndAddUserConversation(token, userId, user);
            }
          }

          // Then check other users
          for (final user in usersToCheck) {
            final userId = user['_id']?.toString();
            final userName = user['name']?.toString() ?? '';

            // Skip Adel Khaled as we already checked
            if (userName.toLowerCase().contains('adel') ||
                userName.toLowerCase().contains('khaled')) {
              continue;
            }

            await _checkAndAddUserConversation(token, userId, user);
          }
        }
      }
    } catch (e) {
      debugPrint('Error adding users with outgoing messages: $e');
      // Don't throw here, just log the error
    }
  }

  // Helper method to check and add a user conversation
  Future<void> _checkAndAddUserConversation(
      String token, String? userId, Map<String, dynamic> user) async {
    if (userId == null) return;
    try {
      // Check if we have messages with this user
      final chatResponse = await http.get(
        Uri.parse('$_apiBaseUrl/inbox/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'token': token,
        },
      ).timeout(_timeout);

      if (chatResponse.statusCode == 200) {
        final chatData = jsonDecode(chatResponse.body);
        if (chatData['messages'] != null &&
            chatData['messages'] is List &&
            (chatData['messages'] as List).isNotEmpty) {
          // Get the last message
          final lastMessage = (chatData['messages'] as List).last;

          // We have messages with this user, add them to senders
          _senders.add({
            '_id': userId,
            'name': user['name'] ?? 'Unknown',
            'email': user['email'] ?? '',
            'image': user['image'],
            'jobTitle': user['jobTitle'] ?? 'Employee',
            // Add last message info
            'lastMessage': {
              'content': lastMessage['content'] ?? '',
              'createdAt':
                  lastMessage['createdAt'] ?? DateTime.now().toIso8601String(),
              'isRead': true // Outgoing messages are always "read"
            }
          });

          // Notify listeners to update UI immediately for important users
          if (user['name']?.toString().toLowerCase().contains('adel') ??
              false) {
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking conversation with user $userId: $e');
    }
  }

  // Fetch messages between current user and another user
  Future<void> fetchMessages(String userId) async {
    // Only set loading state and notify if not already loading
    if (!_isLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('$_apiBaseUrl/inbox/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'token': token,
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['messages'] != null && data['messages'] is List) {
          _messages = (data['messages'] as List)
              .map((message) => Message.fromJson(message))
              .toList();

          if (data['otherUser'] != null) {
            _currentContact = data['otherUser'];
          }
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch messages');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching messages: $_error');
    } finally {
      // Update loading state and notify once at the end
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send a new message
  Future<bool> sendMessage(String receiverId, String content) async {
    // Only set loading state and notify if not already loading
    if (!_isLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http
          .post(
            Uri.parse('$_apiBaseUrl/inbox'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'token': token,
            },
            body: jsonEncode({
              'receiverId': receiverId,
              'content': content,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          final newMessage = Message.fromJson(data['data']);
          _messages.add(newMessage);

          // Update senders list if needed - but don't await it
          // This prevents multiple notifyListeners calls during build
          fetchSenders();

          return true;
        }
        return false;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to send message');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error sending message: $_error');
      return false;
    } finally {
      // Update loading state and notify once at the end
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete specific messages
  Future<bool> deleteMessages(List<String> messageIds) async {
    // Only set loading state and notify if not already loading
    if (!_isLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http
          .delete(
            Uri.parse('$_apiBaseUrl/inbox'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'token': token,
            },
            body: jsonEncode({
              'messageIds': messageIds,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        // Remove deleted messages from the list
        _messages.removeWhere((message) => messageIds.contains(message.id));
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete messages');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting messages: $_error');
      return false;
    } finally {
      // Update loading state and notify once at the end
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete all messages
  Future<bool> deleteAllMessages() async {
    // Only set loading state and notify if not already loading
    if (!_isLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/inbox/all/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'token': token,
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        _messages.clear();
        _senders.clear();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['message'] ?? 'Failed to delete all messages');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting all messages: $_error');
      return false;
    } finally {
      // Update loading state and notify once at the end
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear current contact and messages
  void clearCurrentChat() {
    // Only perform this operation if there's something to clear
    if (_currentContact != null || _messages.isNotEmpty) {
      _currentContact = null;
      _messages.clear();
      notifyListeners();
    }
  }
}
