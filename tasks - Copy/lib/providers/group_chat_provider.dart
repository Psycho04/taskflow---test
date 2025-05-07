import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

class GroupChatProvider with ChangeNotifier {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String? _error;
  static const String _baseUrl = 'http://localhost:5000/api';
  static const Duration _timeout = Duration(seconds: 30);
  static const String _tokenKey = 'token';
  static const String _lastReadMessageKey = 'last_read_group_message';
  String? _lastReadMessageId;

  // Getters
  List<Map<String, dynamic>> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get unread count by comparing the last read message ID with the messages list
  int get unreadCount {
    if (_messages.isEmpty) return 0;
    if (_lastReadMessageId == null) return _messages.length;

    // Find the index of the last read message
    final lastReadIndex =
        _messages.indexWhere((m) => m['_id'] == _lastReadMessageId);

    // If the message is not found, all messages are unread
    if (lastReadIndex == -1) return _messages.length;

    // Count messages newer than the last read message
    return lastReadIndex;
  }

  String get _apiBaseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    }
    return _baseUrl;
  }

  GroupChatProvider() {
    _loadLastReadMessageId();
  }

  // Load the last read message ID from SharedPreferences
  Future<void> _loadLastReadMessageId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastReadMessageId = prefs.getString(_lastReadMessageKey);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading last read message ID: $e');
    }
  }

  // Save the last read message ID to SharedPreferences
  Future<void> _saveLastReadMessageId(String messageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastReadMessageKey, messageId);
      _lastReadMessageId = messageId;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving last read message ID: $e');
    }
  }

  // Mark all messages as read
  Future<void> markAllAsRead() async {
    if (_messages.isEmpty) return;

    // Get the ID of the most recent message
    final mostRecentMessageId = _messages.first['_id'];

    // Save it as the last read message
    await _saveLastReadMessageId(mostRecentMessageId);

    notifyListeners();
  }

  // Fetch group chat messages
  Future<void> fetchGroupChatMessages() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('$_apiBaseUrl/group-chat'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'token': token,
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data']['messages'] is List) {
          _messages = List<Map<String, dynamic>>.from(data['data']['messages']);

          // Sort messages by timestamp (newest first)
          _messages.sort((a, b) {
            final aTime = DateTime.parse(a['timestamp'] ?? a['createdAt']);
            final bTime = DateTime.parse(b['timestamp'] ?? b['createdAt']);
            return bTime.compareTo(aTime);
          });
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['message'] ?? 'Failed to fetch group chat messages');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      debugPrint('Group chat messages fetched. Unread count: $unreadCount');
      notifyListeners();
    }
  }

  // Get the authentication token
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }
}
