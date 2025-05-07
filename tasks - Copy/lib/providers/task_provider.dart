import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasks/models/task.dart';
import 'package:http/http.dart' as http;

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  final List<Task> _trashTasks = [];
  List<Map<String, String>> _normalUsers = [];
  static const String _tasksKey = 'tasks';
  static const String _trashTasksKey = 'trash_tasks';
  static const String _baseUrl = 'http://localhost:5000/api';
  static const Duration _timeout = Duration(seconds: 30);
  static const String _tokenKey = 'token';
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  DateTime? _lastSubmissionTime;

  String get _apiBaseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    }
    return _baseUrl;
  }

  TaskProvider() {
    fetchTasks();
    fetchTrashTasks();
  }

  List<Task> get tasks => _tasks;
  List<Task> get trashTasks => _trashTasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalTasks => _tasks.length;

  int get highPriorityTasks =>
      _tasks.where((task) => task.priority.toLowerCase() == 'high').length;

  int get mediumPriorityTasks =>
      _tasks.where((task) => task.priority.toLowerCase() == 'medium').length;

  int get lowPriorityTasks =>
      _tasks.where((task) => task.priority.toLowerCase() == 'low').length;

  int get completedTasks =>
      _tasks.where((task) => task.stage == 'Completed').length;

  int get inProgressTasks =>
      _tasks.where((task) => task.stage == 'In Progress').length;

  int get todoTasks => _tasks.where((task) => task.stage == 'To Do').length;

  Map<String, int> get tasksByPriority {
    return {
      'high':
          _tasks.where((task) => task.priority.toLowerCase() == 'high').length,
      'medium': _tasks
          .where((task) => task.priority.toLowerCase() == 'medium')
          .length,
      'low':
          _tasks.where((task) => task.priority.toLowerCase() == 'low').length,
    };
  }

  List<Task> get recentTasks {
    // Sort tasks by date (newest first) and take the first 3
    final sortedTasks = List<Task>.from(_tasks);
    sortedTasks.sort((a, b) => b.date.compareTo(a.date));
    return sortedTasks.take(3).toList();
  }

  List<Map<String, String>> get normalUsers => _normalUsers;

  Future<List<Map<String, String>>> fetchNormalUsers() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      print('Fetching normal users from: $_apiBaseUrl/user/normalUsers');

      final response = await http.get(
        Uri.parse('$_apiBaseUrl/user/normalUsers'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Connection timed out. Please check your server status.');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['users'] != null && data['users'] is List) {
          _normalUsers = (data['users'] as List)
              .map((user) => {
                    'id': user['_id']?.toString() ?? '',
                    'fullName': user['fullName']?.toString() ?? '',
                    'email': user['email']?.toString() ?? '',
                    'role': user['role']?.toString() ?? 'user',
                  })
              .toList();
          notifyListeners();
          return _normalUsers;
        } else {
          throw Exception('Invalid response format from server');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch users');
      }
    } catch (e) {
      print('Error fetching normal users: $e');
      return [];
    }
  }

  Future<bool> addTask(Task task) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      // Check user role from token
      final parts = token.split('.');
      final payload = json
          .decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final userRole = payload['role']?.toString().toLowerCase();

      // Only allow admin users to create tasks
      if (userRole != 'admin') {
        throw Exception('Only administrators can create tasks');
      }

      // Check if this is a duplicate submission within 1 second
      final now = DateTime.now();
      if (_lastSubmissionTime != null &&
          now.difference(_lastSubmissionTime!) <
              const Duration(milliseconds: 500)) {
        print(
            'Preventing duplicate submission - too soon after last submission');
        return false;
      }

      // Check if already submitting
      if (_isSubmitting) {
        print('Task submission already in progress');
        return false;
      }

      // Check if task with same title already exists
      if (_tasks.any((t) => t.title.trim() == task.title.trim())) {
        print('Task with this title already exists');
        return false;
      }

      try {
        _isSubmitting = true;
        _isLoading = true;
        _lastSubmissionTime = now;
        notifyListeners();

        // Fetch user details for assignees
        final users = await getNormalUsers();
        final assigneesWithDetails = task.assignees.map((assignee) {
          final userDetails = users.firstWhere(
            (user) => user['_id'] == assignee['id'],
            orElse: () => {
              '_id': assignee['id'],
              'fullName': 'Unknown',
              'email': '',
              'role': 'user'
            },
          );
          return {
            'id': userDetails['_id'],
            'fullName': userDetails['fullName'],
            'email': userDetails['email'],
          };
        }).toList();

        // Compare only the date parts without time
        final today = DateTime(now.year, now.month, now.day);
        final taskDate =
            DateTime(task.date.year, task.date.month, task.date.day);

        if (taskDate.isBefore(today)) {
          throw Exception('Due date must be today or a future date');
        }

        // Set the time to end of day (23:59:59.999) to ensure it's always in the future
        final adjustedDate = DateTime(
          taskDate.year,
          taskDate.month,
          taskDate.day,
          23,
          59,
          59,
          999,
        );

        final requestBody = {
          'title': task.title.trim(),
          'description': task.description.trim(),
          'dueDate': adjustedDate.toIso8601String(),
          'priority': task.priority.toLowerCase(),
          'status': task.stage.toLowerCase(),
          'assignedTo': assigneesWithDetails.map((a) => a['id']).toList(),
        };

        print('Sending request to: $_apiBaseUrl/task');
        print('Request body: ${jsonEncode(requestBody)}');

        // Add task to local state first for optimistic update
        final localTask = Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: task.title.trim(),
          description: task.description.trim(),
          priority: task.priority,
          date: adjustedDate,
          stage: task.stage,
          assignees: assigneesWithDetails,
        );

        _tasks.add(localTask);
        notifyListeners();

        final response = await http
            .post(
          Uri.parse('$_apiBaseUrl/task'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'token': token,
          },
          body: jsonEncode(requestBody),
        )
            .timeout(
          _timeout,
          onTimeout: () {
            throw TimeoutException(
                'Connection timed out. Please check your server status.');
          },
        );

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        // Remove the temporary local task
        _tasks.removeWhere((t) => t.id == localTask.id);

        if (response.statusCode == 201 || response.statusCode == 200) {
          final responseData = jsonDecode(response.body);

          try {
            // Get the task data from the response
            final taskData = responseData['task'];
            Map<String, dynamic> taskMap;

            if (taskData is List) {
              // If task is a list but empty, throw an error
              if (taskData.isEmpty) {
                throw Exception('Server returned empty task data');
              }
              // If task is returned as a list, take the first item
              taskMap = Map<String, dynamic>.from(taskData[0]);
            } else if (taskData is Map<String, dynamic>) {
              // If task is already a map, use it directly
              taskMap = taskData;
            } else {
              // If task data is in the root of response
              taskMap = Map<String, dynamic>.from(responseData);
            }

            // Create new task from server response
            final serverTask = Task(
              id: taskMap['_id']?.toString() ?? '',
              title: taskMap['title']?.toString() ?? '',
              description: taskMap['description']?.toString() ?? '',
              priority: taskMap['priority']?.toString().toLowerCase() ?? 'low',
              date: DateTime.tryParse(taskMap['dueDate']?.toString() ?? '') ??
                  DateTime.now(),
              stage: taskMap['status']?.toString().toLowerCase() ?? 'todo',
              assignees: assigneesWithDetails,
            );

            _tasks.add(serverTask);
            await _saveTasks();
            notifyListeners();
            return true;
          } catch (e) {
            print('Error processing server response: $e');
            notifyListeners();
            rethrow;
          }
        } else {
          final responseData = jsonDecode(response.body);
          final errorMessage = responseData['error']?.toString() ?? '';
          if (errorMessage.contains('dueDate')) {
            throw Exception('Task due date must be in the future');
          }
          throw Exception(responseData['message'] ??
              responseData['error'] ??
              'Failed to create task');
        }
      } catch (e) {
        print('Error creating task: $e');
        _error = e.toString();
        rethrow;
      } finally {
        _isSubmitting = false;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      print('Error creating task: $e');
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> removeTask(String id) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required. Please login first.');
      }

      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/task/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': token,
        },
      );

      if (response.statusCode == 200) {
        _tasks.removeWhere((task) => task.id == id);
        _saveTasks();
        notifyListeners();
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ??
            errorData['message'] ??
            'Failed to delete task');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error removing task: $e');
      }
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      // Fetch user details for assignees
      final users = await getNormalUsers();
      final assigneesWithDetails = task.assignees.map((assignee) {
        final userDetails = users.firstWhere(
          (user) => user['_id'] == assignee['id'],
          orElse: () => <String, dynamic>{
            '_id': assignee['id'],
            'fullName': assignee['fullName'] ?? 'Unknown',
            'email': assignee['email'] ?? '',
            'role': 'user'
          },
        );
        return {
          'id': userDetails['_id'],
          'fullName': userDetails['fullName'],
          'email': userDetails['email'],
        };
      }).toList();

      // Compare only the date parts without time
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final taskDate = DateTime(task.date.year, task.date.month, task.date.day);

      if (taskDate.isBefore(today)) {
        throw Exception('Due date must be today or a future date');
      }

      // Convert stage to server's expected status format
      String status = task.stage.toLowerCase();
      switch (status.replaceAll(' ', '')) {
        case 'todo':
          status = 'to do';
          break;
        case 'inprogress':
          status = 'in progress';
          break;
        case 'completed':
          status = 'completed';
          break;
        default:
          status = 'to do';
      }

      // Format the task data to match server expectations
      final taskData = {
        'title': task.title.trim(),
        'description': task.description.trim(),
        'priority': task.priority.toLowerCase(),
        'status': status,
        'dueDate': task.date.toIso8601String(),
        'assignedTo': assigneesWithDetails.map((a) => a['id']).toList(),
      };

      print('Updating task with data: ${jsonEncode(taskData)}');

      final response = await http
          .put(
        Uri.parse('$_apiBaseUrl/task/${task.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(taskData),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Connection timed out. Please check your server status.');
        },
      );

      print('Update response status: ${response.statusCode}');
      print('Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final updatedTaskData = responseData['task'] ?? responseData;

        // Create updated task from server response with proper assignee details
        final updatedTask = Task(
          id: task.id,
          title: updatedTaskData['title']?.toString() ?? task.title,
          description:
              updatedTaskData['description']?.toString() ?? task.description,
          priority: updatedTaskData['priority']?.toString().toLowerCase() ??
              task.priority,
          date:
              DateTime.tryParse(updatedTaskData['dueDate']?.toString() ?? '') ??
                  task.date,
          stage:
              updatedTaskData['status']?.toString().toLowerCase() ?? task.stage,
          assignees: assigneesWithDetails,
        );

        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = updatedTask;
          await _saveTasks();
          notifyListeners();
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ??
            errorData['message'] ??
            'Failed to update task');
      }
    } catch (e) {
      print('Error updating task: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Map status to backend expected format
      String apiStatus = newStatus.toLowerCase();
      switch (apiStatus.replaceAll(' ', '')) {
        case 'todo':
          apiStatus = 'to do';
          break;
        case 'inprogress':
          apiStatus = 'in progress';
          break;
        case 'completed':
          apiStatus = 'completed';
          break;
        default:
          apiStatus = 'to do';
      }

      print('Updating task status to: $apiStatus');
      print('Using endpoint: $_apiBaseUrl/task/$taskId/status');

      final response = await http
          .patch(
        Uri.parse('$_apiBaseUrl/task/$taskId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'token': token,
        },
        body: jsonEncode({
          'status': apiStatus,
        }),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Connection timed out. Please check your server status.');
        },
      );

      print('Status update response: ${response.statusCode}');
      print('Status update body: ${response.body}');

      if (response.statusCode == 200) {
        final index = _tasks.indexWhere((task) => task.id == taskId);
        if (index != -1) {
          _tasks[index] = _tasks[index].copyWith(stage: newStatus);
          notifyListeners();
        }
      } else {
        throw Exception('Failed to update task status: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error updating task status: $e');
      rethrow;
    }
  }

  Future<void> moveToTrash(String taskId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Optimistic update - move to trash locally first
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      Task? task;

      if (taskIndex != -1) {
        task = _tasks[taskIndex];
        _tasks.removeAt(taskIndex);
        _trashTasks.add(task);
        notifyListeners();
      }

      // Call the API to move to trash
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/task/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'token': token,
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Connection timed out. Please check your server status.');
        },
      );

      if (response.statusCode == 200) {
        // Success - save the updated state
        _saveTasks();
      } else {
        // Revert the optimistic update if the API call fails
        if (task != null && taskIndex != -1) {
          _trashTasks.remove(task);
          _tasks.insert(taskIndex, task);
          notifyListeners();
        }
        throw Exception('Failed to move task to trash: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error moving task to trash: $e');
      rethrow;
    }
  }

  Future<void> restoreFromTrash(String taskId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Optimistic update - restore locally first
      final taskIndex = _trashTasks.indexWhere((task) => task.id == taskId);
      Task? task;

      if (taskIndex != -1) {
        task = _trashTasks[taskIndex];
        _trashTasks.removeAt(taskIndex);
        _tasks.add(task);
        notifyListeners();
      }

      // Call the API to restore the task
      final response = await http.patch(
        Uri.parse('$_apiBaseUrl/task/$taskId/restore'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'token': token,
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Connection timed out. Please check your server status.');
        },
      );

      if (response.statusCode == 200) {
        // Success - save the updated state
        _saveTasks();
      } else {
        // Revert the optimistic update if the API call fails
        if (task != null) {
          _tasks.remove(task);
          _trashTasks.insert(taskIndex, task);
          notifyListeners();
        }
        throw Exception('Failed to restore task from trash: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error restoring task from trash: $e');
      rethrow;
    }
  }

  void permanentlyDeleteTask(String taskId) {
    _trashTasks.removeWhere((task) => task.id == taskId);
    _saveTasks();
    notifyListeners();
  }

  Future<void> permanentlyDeleteTaskFromBackend(String taskId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Optimistic update - remove from local state first
      final taskIndex = _trashTasks.indexWhere((task) => task.id == taskId);
      Task? task;

      if (taskIndex != -1) {
        task = _trashTasks[taskIndex];
        _trashTasks.removeAt(taskIndex);
        notifyListeners();
      }

      // Call the API to permanently delete the task
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/task/$taskId/trash'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'token': token,
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Connection timed out. Please check your server status.');
        },
      );

      if (response.statusCode == 200) {
        // Success - save the updated state
        _saveTasks();
      } else {
        // Revert the optimistic update if the API call fails
        if (task != null) {
          _trashTasks.insert(taskIndex, task);
          notifyListeners();
        }
        throw Exception('Failed to delete task permanently: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error deleting task permanently: $e');
      rethrow;
    }
  }

  Future<void> clearTrash() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Optimistic update - clear local trash first
      final trashTasksCopy = List<Task>.from(_trashTasks);
      _trashTasks.clear();
      notifyListeners();

      // Call the API to empty trash
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/task/trash/empty'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'token': token,
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Connection timed out. Please check your server status.');
        },
      );

      if (response.statusCode == 200) {
        // Success - save the updated state
        _saveTasks();
      } else {
        // Revert the optimistic update if the API call fails
        _trashTasks.addAll(trashTasksCopy);
        notifyListeners();
        throw Exception('Failed to clear trash: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error clearing trash: $e');
      rethrow;
    }
  }

  // Save tasks to SharedPreferences
  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save regular tasks
      final tasksJson =
          jsonEncode(_tasks.map((task) => task.toJson()).toList());
      await prefs.setString(_tasksKey, tasksJson);

      // Save trash tasks
      final trashTasksJson =
          jsonEncode(_trashTasks.map((task) => task.toJson()).toList());
      await prefs.setString(_trashTasksKey, trashTasksJson);
    } catch (e) {
      // Handle any errors during saving
      if (kDebugMode) {
        print('Error saving tasks: $e');
      }
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getToken() async {
    return _getToken();
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<void> fetchTrashTasks() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      // Call the API to get trash tasks
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/task/trash'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'token': token,
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Connection timed out. Please check your server status.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['tasks'] != null) {
          final List<dynamic> tasksJson =
              data['tasks'] is List ? data['tasks'] : [];

          _trashTasks.clear();

          if (tasksJson.isNotEmpty) {
            final fetchedTasks = tasksJson
                .map((taskJson) {
                  try {
                    // Ensure the task has all required fields
                    if (taskJson['_id'] == null) {
                      return null;
                    }

                    // Convert server response format to Task model format
                    final task = Task(
                      id: taskJson['_id']?.toString() ?? '',
                      title: taskJson['title']?.toString() ?? '',
                      description: taskJson['description']?.toString() ?? '',
                      priority:
                          taskJson['priority']?.toString().toLowerCase() ??
                              'low',
                      date: DateTime.tryParse(
                              taskJson['dueDate']?.toString() ?? '') ??
                          DateTime.now(),
                      stage: taskJson['status']?.toString().toLowerCase() ??
                          'todo',
                      assignees:
                          (taskJson['assignedTo'] as List?)?.map((assignee) {
                                if (assignee is Map<String, dynamic>) {
                                  return {
                                    'id': assignee['_id']?.toString() ?? '',
                                    'fullName':
                                        assignee['fullName']?.toString() ?? '',
                                    'email':
                                        assignee['email']?.toString() ?? '',
                                  };
                                } else {
                                  return {
                                    'id': assignee.toString(),
                                    'fullName': '',
                                    'email': '',
                                  };
                                }
                              }).toList() ??
                              [],
                    );

                    return task;
                  } catch (e) {
                    debugPrint('Error processing trash task: $e');
                    return null;
                  }
                })
                .where((task) => task != null)
                .cast<Task>()
                .toList();

            _trashTasks.addAll(fetchedTasks);
          }

          _error = null;
        }
      } else {
        final errorData = jsonDecode(response.body);
        _error = errorData['message'] ??
            errorData['error'] ??
            'Failed to fetch trash tasks';
        throw Exception(_error);
      }
    } catch (e) {
      debugPrint('Error fetching trash tasks: $e');
      if (e is SocketException) {
        _error =
            'Cannot connect to server. Please check if the server is running.';
      } else if (e is TimeoutException) {
        _error = 'Connection timed out. Please check your server status.';
      } else {
        _error = e.toString();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTasks() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication required');
      }

      // Decode the token to get user ID and role
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid token format');
      }

      final payload = json
          .decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));

      print('Token payload: $payload');

      final userId = payload['userId']?.toString();
      final isAdmin = payload['role']?.toString().toLowerCase() == 'admin';

      if (userId == null || userId.isEmpty) {
        print('User ID not found in token payload');
        throw Exception('User ID not found in token');
      }

      // Use different endpoints based on user role
      final endpoint = isAdmin ? '/task' : '/task/userTasks/$userId';
      print('Fetching tasks from: $_apiBaseUrl$endpoint');
      print('User role: ${isAdmin ? 'admin' : 'user'}');
      print('User ID: $userId');
      print('Using token: $token');

      final response = await http.get(
        Uri.parse('$_apiBaseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'token': token,
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Connection timed out. Please check your server status.');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Decoded data: $data');

        if (data['tasks'] != null) {
          final List<dynamic> tasksJson =
              data['tasks'] is List ? data['tasks'] : [];
          print('Tasks JSON: $tasksJson');

          if (tasksJson.isEmpty) {
            print('No tasks found for user $userId');
            _tasks = [];
            _error = null;
            return;
          }

          _tasks = tasksJson
              .map((taskJson) {
                print('Processing task: $taskJson');
                try {
                  // Ensure the task has all required fields
                  if (taskJson['_id'] == null) {
                    print('Task missing ID: $taskJson');
                    return null;
                  }

                  // Convert server response format to Task model format
                  final task = Task(
                    id: taskJson['_id']?.toString() ?? '',
                    title: taskJson['title']?.toString() ?? '',
                    description: taskJson['description']?.toString() ?? '',
                    priority:
                        taskJson['priority']?.toString().toLowerCase() ?? 'low',
                    date: DateTime.tryParse(
                            taskJson['dueDate']?.toString() ?? '') ??
                        DateTime.now(),
                    stage:
                        taskJson['status']?.toString().toLowerCase() ?? 'todo',
                    assignees:
                        (taskJson['assignedTo'] as List?)?.map((assignee) {
                              if (assignee is Map<String, dynamic>) {
                                return {
                                  'id': assignee['_id']?.toString() ?? '',
                                  'fullName':
                                      assignee['fullName']?.toString() ?? '',
                                  'email': assignee['email']?.toString() ?? '',
                                };
                              } else {
                                return {
                                  'id': assignee.toString(),
                                  'fullName': '',
                                  'email': '',
                                };
                              }
                            }).toList() ??
                            [],
                  );

                  print('Created task: ${task.toJson()}');
                  return task;
                } catch (e) {
                  print('Error processing task: $e');
                  print('Task JSON that caused error: $taskJson');
                  return null;
                }
              })
              .where((task) => task != null)
              .cast<Task>()
              .toList();

          print('Final tasks count: ${_tasks.length}');
          _error = null;
        } else {
          print('No tasks field in response');
          _tasks = [];
          _error = null;
        }
      } else {
        final errorData = jsonDecode(response.body);
        _error = errorData['message'] ??
            errorData['error'] ??
            'Failed to fetch tasks';

        // If unauthorized, clear the token
        if (response.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_tokenKey);
          print('Cleared invalid token');
        }

        throw Exception(_error);
      }
    } catch (e) {
      print('Error fetching tasks: $e');
      if (e is SocketException) {
        _error =
            'Cannot connect to server. Please check if the server is running.';
      } else if (e is TimeoutException) {
        _error = 'Connection timed out. Please check your server status.';
      } else {
        _error = e.toString();
      }
      _tasks = []; // Clear tasks on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getNormalUsers() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      print('Fetching users from: $_apiBaseUrl/user');
      print('Using token: $token');

      final response = await http.get(
        Uri.parse('$_apiBaseUrl/user'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'token': token,
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Connection timed out. Please check your server status.');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['users'] != null && data['users'] is List) {
          // Filter out admin users and map to the correct format
          final users = (data['users'] as List)
              .where((user) => user['role']?.toString().toLowerCase() == 'user')
              .map((user) {
            print('Raw user data: $user'); // Debug log

            // Get the full name from the user data
            String fullName = user['fullName']?.toString() ?? '';

            // If fullName is empty, try to get it from name field
            if (fullName.isEmpty) {
              fullName = user['name']?.toString() ?? '';
            }

            // If still empty, generate from email
            if (fullName.isEmpty) {
              final email = user['email']?.toString() ?? '';
              if (email.isNotEmpty) {
                // Extract username part before @
                final username = email.split('@')[0];
                // Split by common separators and capitalize each part
                fullName = username
                    .split(RegExp(r'[._-]'))
                    .where((part) => part.isNotEmpty)
                    .map((part) =>
                        part[0].toUpperCase() + part.substring(1).toLowerCase())
                    .join(' ');
              }
            }

            // If still empty, use a default name
            if (fullName.isEmpty) {
              fullName =
                  'User ${user['_id']?.toString().substring(0, 4) ?? ''}';
            }

            return <String, dynamic>{
              '_id': user['_id']?.toString() ?? '',
              'fullName': fullName,
              'email': user['email']?.toString() ?? '',
              'role': user['role']?.toString() ?? 'user',
              'jobTitle': user['jobTitle']?.toString() ?? 'Employee'
            };
          }).toList();

          print('Processed users: $users'); // Debug log
          return users;
        } else {
          throw Exception('Invalid response format from server');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ??
            errorData['error'] ??
            'Failed to load users');
      }
    } catch (e) {
      print('Error in getNormalUsers: $e');
      throw Exception('Failed to load users: $e');
    }
  }

  Future<Map<String, dynamic>> getTaskDetails(String taskId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required');
    }

    final response = await http.get(
      Uri.parse('$_apiBaseUrl/task/$taskId'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'token': token,
      },
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException(
            'Connection timed out. Please check your server status.');
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['task'] != null) {
        return data['task'];
      } else if (data is Map<String, dynamic>) {
        return data;
      } else {
        throw Exception('Invalid response format from server');
      }
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ??
          errorData['error'] ??
          'Failed to load task details');
    }
  }

  Future<Task> createTask(Task task) async {
    try {
      _isLoading = true;
      notifyListeners();

      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/task'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'token': token,
        },
        body: jsonEncode(task.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final createdTask = Task.fromJson(data);
        _tasks.add(createdTask);
        notifyListeners();
        return createdTask;
      } else {
        throw Exception('Failed to create task: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
