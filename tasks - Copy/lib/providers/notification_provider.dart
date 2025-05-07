import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasks/models/notification.dart' as app_notification;

class NotificationProvider with ChangeNotifier {
  List<app_notification.Notification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  static const String _baseUrl = 'http://localhost:5000/api';
  static const Duration _timeout = Duration(seconds: 30);
  static const String _readNotificationsKey = 'read_notifications';
  Set<String> _readNotificationIds = {};

  // Getters
  List<app_notification.Notification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  String get _apiBaseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    }
    return _baseUrl;
  }

  NotificationProvider() {
    // Initialize by loading read notifications first, then fetch notifications
    _initializeProvider();
  }

  // Initialize the provider by loading read notifications first, then fetching
  Future<void> _initializeProvider() async {
    await _loadReadNotifications();
    await fetchNotifications();
  }

  // Load read notification IDs from SharedPreferences
  Future<void> _loadReadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readNotificationsJson = prefs.getString(_readNotificationsKey);

      if (readNotificationsJson != null) {
        final List<dynamic> readIds = json.decode(readNotificationsJson);
        _readNotificationIds = readIds.map((id) => id.toString()).toSet();
        debugPrint(
            'Loaded ${_readNotificationIds.length} read notification IDs');
      } else {
        debugPrint('No read notifications found in storage');
        _readNotificationIds = {};
      }
    } catch (e) {
      // If there's an error loading, just continue with empty set
      debugPrint('Error loading read notifications: $e');
      _readNotificationIds = {};
    }
  }

  // Save read notification IDs to SharedPreferences
  Future<void> _saveReadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readNotificationsJson = json.encode(_readNotificationIds.toList());
      await prefs.setString(_readNotificationsKey, readNotificationsJson);
    } catch (e) {
      // If there's an error saving, just log it and continue
      debugPrint('Error saving read notifications: $e');
    }
  }

  // Fetch notifications for the current user
  Future<void> fetchNotifications() async {
    debugPrint('Fetching notifications...');
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');

      if (userDataString == null) {
        _error = 'User data not found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final userData = json.decode(userDataString);
      final userId = userData['_id'];
      final token = prefs.getString('token');

      if (token == null) {
        _error = 'Authentication token not found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse('$_apiBaseUrl/notification/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'token': token,
        },
      ).timeout(
        _timeout,
        onTimeout: () {
          throw TimeoutException(
              'Connection timed out. Please check your server status.');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['userNotification'] != null) {
          final List<dynamic> notificationsJson = data['userNotification'];
          _notifications = notificationsJson.map((json) {
            // Create notification from JSON
            final notification = app_notification.Notification.fromJson(json);

            // Check if this notification is already marked as read locally
            if (_readNotificationIds.contains(notification.id)) {
              // If it's marked as read locally but not on the server, update it to read
              return notification.isRead
                  ? notification
                  : notification.copyWith(isRead: true);
            }

            // If it's marked as read on the server, add it to our local read set
            if (notification.isRead &&
                !_readNotificationIds.contains(notification.id)) {
              _readNotificationIds.add(notification.id);
              _saveReadNotifications(); // Save the updated set
            }

            return notification;
          }).toList();
        } else {
          _notifications = [];
        }
      } else {
        _error = 'Failed to load notifications: ${response.statusCode}';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      debugPrint('Notifications fetched. Unread count: $unreadCount');
      notifyListeners();
    }
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        _error = 'Authentication token not found';
        notifyListeners();
        return;
      }

      // Optimistically update the UI
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);

        // Add to local read notifications set and save
        _readNotificationIds.add(notificationId);
        _saveReadNotifications();

        notifyListeners();
      }

      // Call the API to mark as read
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/notification/single/$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'token': token,
        },
      ).timeout(
        _timeout,
        onTimeout: () {
          throw TimeoutException(
              'Connection timed out. Please check your server status.');
        },
      );

      if (response.statusCode != 200) {
        // Revert the optimistic update if the API call fails
        await fetchNotifications();
        _error = 'Failed to mark notification as read: ${response.statusCode}';
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      await fetchNotifications(); // Refresh to get the correct state
      notifyListeners();
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        _error = 'Authentication token not found';
        notifyListeners();
        return;
      }

      // Optimistically update the UI
      _notifications.removeWhere((n) => n.id == notificationId);

      // Remove from read notifications set if it exists
      if (_readNotificationIds.contains(notificationId)) {
        _readNotificationIds.remove(notificationId);
        _saveReadNotifications();
      }

      notifyListeners();

      // Call the API to delete the notification
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/notification/$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'token': token,
        },
      ).timeout(
        _timeout,
        onTimeout: () {
          throw TimeoutException(
              'Connection timed out. Please check your server status.');
        },
      );

      if (response.statusCode != 200) {
        // Revert the optimistic update if the API call fails
        await fetchNotifications();
        _error = 'Failed to delete notification: ${response.statusCode}';
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      await fetchNotifications(); // Refresh to get the correct state
      notifyListeners();
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        _error = 'Authentication token not found';
        notifyListeners();
        return;
      }

      // Optimistically update the UI
      _notifications = _notifications.map((notification) {
        // Add all notification IDs to the read set
        _readNotificationIds.add(notification.id);
        return notification.copyWith(isRead: true);
      }).toList();

      // Save the updated read notifications set
      _saveReadNotifications();

      notifyListeners();

      // We don't have a backend API for marking all as read,
      // so we'll mark each unread notification as read individually
      final futures = _notifications
          .where((notification) => !notification.isRead)
          .map((notification) => http.get(
                Uri.parse(
                    '$_apiBaseUrl/notification/single/${notification.id}'),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  'token': token,
                },
              ))
          .toList();

      await Future.wait(futures);
    } catch (e) {
      _error = e.toString();
      await fetchNotifications(); // Refresh to get the correct state
      notifyListeners();
    }
  }

  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userDataString = prefs.getString('userData');

      if (token == null) {
        _error = 'Authentication token not found';
        notifyListeners();
        return;
      }

      if (userDataString == null) {
        _error = 'User data not found';
        notifyListeners();
        return;
      }

      final userData = json.decode(userDataString);
      final userId = userData['_id'];

      // Get all notification IDs before clearing
      final allNotificationIds = _notifications.map((n) => n.id).toSet();

      // Optimistically update the UI
      _notifications = [];

      // Remove all these notifications from the read set
      for (final id in allNotificationIds) {
        _readNotificationIds.remove(id);
      }
      _saveReadNotifications();

      notifyListeners();

      // Use the new endpoint to delete all notifications at once
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/notification/user/$userId/all'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'token': token,
        },
      ).timeout(
        _timeout,
        onTimeout: () {
          throw TimeoutException(
              'Connection timed out. Please check your server status.');
        },
      );

      if (response.statusCode != 200) {
        _error = 'Failed to delete all notifications: ${response.statusCode}';
        await fetchNotifications(); // Refresh to get the correct state
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      await fetchNotifications(); // Refresh to get the correct state
      notifyListeners();
    }
  }

  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
