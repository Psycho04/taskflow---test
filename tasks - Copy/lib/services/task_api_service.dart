import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/api_base.dart';
import '../services/api_constants.dart';
import '../services/token_manager.dart';

class TaskApiService {
  // Fetch all tasks (for admin users)
  Future<List<Task>> fetchAllTasks() async {
    final response = await ApiBase.get<Map<String, dynamic>>(
      ApiConstants.tasksEndpoint,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      if (data['tasks'] != null && data['tasks'] is List) {
        return _convertTasksFromJson(data['tasks'] as List);
      }
    }

    if (response.error != null) {
      throw Exception(response.error);
    }

    return [];
  }

  // Fetch tasks for a specific user
  Future<List<Task>> fetchUserTasks(String userId) async {
    final response = await ApiBase.get<Map<String, dynamic>>(
      ApiConstants.userTasksEndpoint(userId),
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      if (data['tasks'] != null && data['tasks'] is List) {
        return _convertTasksFromJson(data['tasks'] as List);
      }
    }

    if (response.error != null) {
      throw Exception(response.error);
    }

    return [];
  }

  // Fetch tasks based on user role
  Future<List<Task>> fetchTasks() async {
    final token = await TokenManager.getToken();
    if (token == null) {
      throw Exception('Authentication required');
    }

    final userId = TokenManager.getUserIdFromToken(token);
    final isAdmin = TokenManager.isUserAdmin(token);

    if (userId == null) {
      throw Exception('User ID not found in token');
    }

    if (isAdmin) {
      return fetchAllTasks();
    } else {
      return fetchUserTasks(userId);
    }
  }

  // Fetch trash tasks
  Future<List<Task>> fetchTrashTasks() async {
    final response = await ApiBase.get<Map<String, dynamic>>(
      ApiConstants.trashTasksEndpoint,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      if (data['tasks'] != null && data['tasks'] is List) {
        return _convertTasksFromJson(data['tasks'] as List);
      }
    }

    if (response.error != null) {
      throw Exception(response.error);
    }

    return [];
  }

  // Add a new task
  Future<Task> addTask(
      Task task, List<Map<String, dynamic>> assigneesWithDetails) async {
    final token = await TokenManager.getToken();
    if (token == null) {
      throw Exception('Authentication required');
    }

    if (!TokenManager.isUserAdmin(token)) {
      throw Exception('Only administrators can create tasks');
    }

    // Set the time to end of day (23:59:59.999) to ensure it's always in the future
    final adjustedDate = DateTime(
      task.date.year,
      task.date.month,
      task.date.day,
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

    final response = await ApiBase.post<Map<String, dynamic>>(
      ApiConstants.tasksEndpoint,
      body: requestBody,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      Map<String, dynamic> taskMap;

      if (data['task'] is List) {
        if ((data['task'] as List).isEmpty) {
          throw Exception('Server returned empty task data');
        }
        taskMap = Map<String, dynamic>.from((data['task'] as List)[0]);
      } else if (data['task'] is Map<String, dynamic>) {
        taskMap = data['task'] as Map<String, dynamic>;
      } else {
        taskMap = data;
      }

      return Task(
        id: taskMap['_id']?.toString() ?? '',
        title: taskMap['title']?.toString() ?? '',
        description: taskMap['description']?.toString() ?? '',
        priority: taskMap['priority']?.toString().toLowerCase() ?? 'low',
        date: DateTime.tryParse(taskMap['dueDate']?.toString() ?? '') ??
            DateTime.now(),
        stage: taskMap['status']?.toString().toLowerCase() ?? 'to do',
        assignees: assigneesWithDetails,
      );
    }

    throw Exception(response.error ?? 'Failed to create task');
  }

  // Update a task
  Future<Task> updateTask(
      Task task, List<Map<String, dynamic>> assigneesWithDetails) async {
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

    final taskData = {
      'title': task.title.trim(),
      'description': task.description.trim(),
      'priority': task.priority.toLowerCase(),
      'status': status,
      'dueDate': task.date.toIso8601String(),
      'assignedTo': assigneesWithDetails.map((a) => a['id']).toList(),
    };

    final response = await ApiBase.put<Map<String, dynamic>>(
      ApiConstants.taskDetailsEndpoint(task.id),
      body: taskData,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      final updatedTaskData = data['task'] ?? data;

      return Task(
        id: task.id,
        title: updatedTaskData['title']?.toString() ?? task.title,
        description:
            updatedTaskData['description']?.toString() ?? task.description,
        priority: updatedTaskData['priority']?.toString().toLowerCase() ??
            task.priority,
        date: DateTime.tryParse(updatedTaskData['dueDate']?.toString() ?? '') ??
            task.date,
        stage:
            updatedTaskData['status']?.toString().toLowerCase() ?? task.stage,
        assignees: assigneesWithDetails,
      );
    }

    throw Exception(response.error ?? 'Failed to update task');
  }

  // Update task status
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
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

    final response = await ApiBase.patch<Map<String, dynamic>>(
      ApiConstants.taskStatusEndpoint(taskId),
      body: {'status': apiStatus},
    );

    if (!response.isSuccess) {
      throw Exception(response.error ?? 'Failed to update task status');
    }
  }

  // Move task to trash
  Future<void> moveToTrash(String taskId) async {
    final response = await ApiBase.delete<Map<String, dynamic>>(
      ApiConstants.taskDetailsEndpoint(taskId),
    );

    if (!response.isSuccess) {
      throw Exception(response.error ?? 'Failed to move task to trash');
    }
  }

  // Restore task from trash
  Future<void> restoreFromTrash(String taskId) async {
    final response = await ApiBase.patch<Map<String, dynamic>>(
      ApiConstants.restoreTaskEndpoint(taskId),
    );

    if (!response.isSuccess) {
      throw Exception(response.error ?? 'Failed to restore task from trash');
    }
  }

  // Permanently delete task
  Future<void> permanentlyDeleteTask(String taskId) async {
    final response = await ApiBase.delete<Map<String, dynamic>>(
      ApiConstants.permanentDeleteTaskEndpoint(taskId),
    );

    if (!response.isSuccess) {
      throw Exception(response.error ?? 'Failed to delete task permanently');
    }
  }

  // Clear trash
  Future<void> clearTrash() async {
    final response = await ApiBase.delete<Map<String, dynamic>>(
      ApiConstants.emptyTrashEndpoint,
    );

    if (!response.isSuccess) {
      throw Exception(response.error ?? 'Failed to clear trash');
    }
  }

  // Get task details
  Future<Map<String, dynamic>> getTaskDetails(String taskId) async {
    final response = await ApiBase.get<Map<String, dynamic>>(
      ApiConstants.taskDetailsEndpoint(taskId),
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      if (data['task'] != null) {
        return data['task'] as Map<String, dynamic>;
      } else {
        return data;
      }
    }

    throw Exception(response.error ?? 'Failed to load task details');
  }

  // Helper method to convert tasks from JSON
  List<Task> _convertTasksFromJson(List taskJsonList) {
    return taskJsonList
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
              priority: taskJson['priority']?.toString().toLowerCase() ?? 'low',
              date: DateTime.tryParse(taskJson['dueDate']?.toString() ?? '') ??
                  DateTime.now(),
              stage: taskJson['status']?.toString().toLowerCase() ?? 'todo',
              assignees: (taskJson['assignedTo'] as List?)?.map((assignee) {
                    if (assignee is Map<String, dynamic>) {
                      return {
                        'id': assignee['_id']?.toString() ?? '',
                        'fullName': assignee['fullName']?.toString() ?? '',
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

            return task;
          } catch (e) {
            debugPrint('Error processing task: $e');
            return null;
          }
        })
        .where((task) => task != null)
        .cast<Task>()
        .toList();
  }
}
