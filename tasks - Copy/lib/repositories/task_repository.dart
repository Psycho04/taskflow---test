import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../services/api_constants.dart';
import '../services/task_api_service.dart';
import '../services/user_api_service.dart';

class TaskRepository {
  final TaskApiService _taskApiService;
  final UserApiService _userApiService;
  
  TaskRepository({
    TaskApiService? taskApiService,
    UserApiService? userApiService,
  }) : 
    _taskApiService = taskApiService ?? TaskApiService(),
    _userApiService = userApiService ?? UserApiService();
  
  // Fetch tasks from API
  Future<List<Task>> fetchTasks() async {
    try {
      final tasks = await _taskApiService.fetchTasks();
      await _saveTasks(tasks);
      return tasks;
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      rethrow;
    }
  }
  
  // Fetch trash tasks from API
  Future<List<Task>> fetchTrashTasks() async {
    try {
      final tasks = await _taskApiService.fetchTrashTasks();
      await _saveTrashTasks(tasks);
      return tasks;
    } catch (e) {
      debugPrint('Error fetching trash tasks: $e');
      rethrow;
    }
  }
  
  // Add a new task
  Future<Task> addTask(Task task) async {
    try {
      // Fetch user details for assignees
      final users = await _userApiService.fetchAllUsers();
      final assigneesWithDetails = task.assignees.map((assignee) {
        final userDetails = users.firstWhere(
          (user) => user['id'] == assignee['id'],
          orElse: () => {
            'id': assignee['id'],
            'name': 'Unknown',
            'email': '',
            'role': 'user'
          },
        );
        return {
          'id': userDetails['id'],
          'fullName': userDetails['name'],
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
      
      final createdTask = await _taskApiService.addTask(task, assigneesWithDetails);
      return createdTask;
    } catch (e) {
      debugPrint('Error adding task: $e');
      rethrow;
    }
  }
  
  // Update an existing task
  Future<Task> updateTask(Task task) async {
    try {
      // Fetch user details for assignees
      final users = await _userApiService.fetchAllUsers();
      final assigneesWithDetails = task.assignees.map((assignee) {
        final userDetails = users.firstWhere(
          (user) => user['id'] == assignee['id'],
          orElse: () => {
            'id': assignee['id'],
            'name': assignee['fullName'] ?? 'Unknown',
            'email': assignee['email'] ?? '',
            'role': 'user'
          },
        );
        return {
          'id': userDetails['id'],
          'fullName': userDetails['name'],
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
      
      final updatedTask = await _taskApiService.updateTask(task, assigneesWithDetails);
      return updatedTask;
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }
  
  // Update task status
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    try {
      await _taskApiService.updateTaskStatus(taskId, newStatus);
    } catch (e) {
      debugPrint('Error updating task status: $e');
      rethrow;
    }
  }
  
  // Move task to trash
  Future<void> moveToTrash(String taskId) async {
    try {
      await _taskApiService.moveToTrash(taskId);
    } catch (e) {
      debugPrint('Error moving task to trash: $e');
      rethrow;
    }
  }
  
  // Restore task from trash
  Future<void> restoreFromTrash(String taskId) async {
    try {
      await _taskApiService.restoreFromTrash(taskId);
    } catch (e) {
      debugPrint('Error restoring task from trash: $e');
      rethrow;
    }
  }
  
  // Permanently delete task
  Future<void> permanentlyDeleteTask(String taskId) async {
    try {
      await _taskApiService.permanentlyDeleteTask(taskId);
    } catch (e) {
      debugPrint('Error deleting task permanently: $e');
      rethrow;
    }
  }
  
  // Clear trash
  Future<void> clearTrash() async {
    try {
      await _taskApiService.clearTrash();
    } catch (e) {
      debugPrint('Error clearing trash: $e');
      rethrow;
    }
  }
  
  // Get task details
  Future<Map<String, dynamic>> getTaskDetails(String taskId) async {
    try {
      return await _taskApiService.getTaskDetails(taskId);
    } catch (e) {
      debugPrint('Error getting task details: $e');
      rethrow;
    }
  }
  
  // Save tasks to local storage
  Future<void> _saveTasks(List<Task> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = jsonEncode(tasks.map((task) => task.toJson()).toList());
      await prefs.setString(ApiConstants.tasksKey, tasksJson);
    } catch (e) {
      debugPrint('Error saving tasks: $e');
    }
  }
  
  // Save trash tasks to local storage
  Future<void> _saveTrashTasks(List<Task> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = jsonEncode(tasks.map((task) => task.toJson()).toList());
      await prefs.setString(ApiConstants.trashTasksKey, tasksJson);
    } catch (e) {
      debugPrint('Error saving trash tasks: $e');
    }
  }
  
  // Load tasks from local storage
  Future<List<Task>> loadTasksFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getString(ApiConstants.tasksKey);
      
      if (tasksJson != null) {
        final List<dynamic> decodedTasks = jsonDecode(tasksJson);
        return decodedTasks
            .map((taskJson) => Task.fromJson(taskJson))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading tasks from local storage: $e');
    }
    
    return [];
  }
  
  // Load trash tasks from local storage
  Future<List<Task>> loadTrashTasksFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getString(ApiConstants.trashTasksKey);
      
      if (tasksJson != null) {
        final List<dynamic> decodedTasks = jsonDecode(tasksJson);
        return decodedTasks
            .map((taskJson) => Task.fromJson(taskJson))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading trash tasks from local storage: $e');
    }
    
    return [];
  }
}
