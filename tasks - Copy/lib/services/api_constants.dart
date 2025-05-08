import 'dart:io';

class ApiConstants {
  static const String baseUrl = 'http://localhost:5000/api';
  static const Duration timeout = Duration(seconds: 30);
  static const String tokenKey = 'token';

  static String get apiBaseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    }
    return baseUrl;
  }

  // Task endpoints
  static String get tasksEndpoint => '/task';
  static String userTasksEndpoint(String userId) => '/task/userTasks/$userId';
  static String taskDetailsEndpoint(String taskId) => '/task/$taskId';
  static String taskStatusEndpoint(String taskId) => '/task/$taskId/status';
  static String get trashTasksEndpoint => '/task/trash';
  static String restoreTaskEndpoint(String taskId) => '/task/$taskId/restore';
  static String permanentDeleteTaskEndpoint(String taskId) =>
      '/task/$taskId/trash';
  static String get emptyTrashEndpoint => '/task/trash/empty';

  // User endpoints
  static String get usersEndpoint => '/user';
  static String get normalUsersEndpoint => '/user/normal';

  // Local storage keys
  static const String tasksKey = 'tasks';
  static const String trashTasksKey = 'trash_tasks';
}
