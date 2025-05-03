import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  final String baseUrl = 'http://10.0.2.2:3000/api/notification';

  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unreadCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error fetching notifications: $e');
      return 0;
    }
  }

  Future<void> markAsRead(String userId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/$userId/read'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  Future<void> sendTaskAssignmentNotification({
    required String userId,
    required String taskId,
    required String taskTitle,
    required String assignedBy,
  }) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/task-assignment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'taskId': taskId,
          'taskTitle': taskTitle,
          'assignedBy': assignedBy,
          'type': 'task_assignment',
        }),
      );
    } catch (e) {
      print('Error sending task assignment notification: $e');
    }
  }
} 