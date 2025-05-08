import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';
import '../repositories/user_repository.dart';

class TaskProvider with ChangeNotifier {
  final TaskRepository _taskRepository;
  final UserRepository _userRepository;
  
  List<Task> _tasks = [];
  List<Task> _trashTasks = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  DateTime? _lastSubmissionTime;
  
  TaskProvider({
    TaskRepository? taskRepository,
    UserRepository? userRepository,
  }) : 
    _taskRepository = taskRepository ?? TaskRepository(),
    _userRepository = userRepository ?? UserRepository() {
    fetchTasks();
    fetchTrashTasks();
  }
  
  // Getters
  List<Task> get tasks => _tasks;
  List<Task> get trashTasks => _trashTasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Task statistics
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
  
  List<Map<String, dynamic>> get normalUsers => _userRepository.normalUsers;
  
  // Fetch all users including admins
  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    return _userRepository.fetchAllUsers();
  }
  
  // Fetch normal users
  Future<List<Map<String, dynamic>>> fetchNormalUsers() async {
    return _userRepository.fetchNormalUsers();
  }
  
  // Add a new task
  Future<bool> addTask(Task task) async {
    try {
      // Check if this is a duplicate submission within 500 milliseconds
      final now = DateTime.now();
      if (_lastSubmissionTime != null &&
          now.difference(_lastSubmissionTime!) < const Duration(milliseconds: 500)) {
        debugPrint('Preventing duplicate submission - too soon after last submission');
        return false;
      }
      
      // Check if already submitting
      if (_isSubmitting) {
        debugPrint('Task submission already in progress');
        return false;
      }
      
      // Check if task with same title already exists
      if (_tasks.any((t) => t.title.trim() == task.title.trim())) {
        debugPrint('Task with this title already exists');
        return false;
      }
      
      try {
        _isSubmitting = true;
        _isLoading = true;
        _lastSubmissionTime = now;
        notifyListeners();
        
        // Add task to local state first for optimistic update
        final localTask = Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: task.title.trim(),
          description: task.description.trim(),
          priority: task.priority,
          date: task.date,
          stage: task.stage,
          assignees: task.assignees,
        );
        
        _tasks.add(localTask);
        notifyListeners();
        
        // Call repository to add task
        final createdTask = await _taskRepository.addTask(task);
        
        // Remove the temporary local task
        _tasks.removeWhere((t) => t.id == localTask.id);
        
        // Add the server-created task
        _tasks.add(createdTask);
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('Error creating task: $e');
        _error = e.toString();
        rethrow;
      } finally {
        _isSubmitting = false;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error creating task: $e');
      _error = e.toString();
      rethrow;
    }
  }
  
  // Update a task
  Future<void> updateTask(Task task) async {
    try {
      // Update task optimistically
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        notifyListeners();
      }
      
      // Call repository to update task
      final updatedTask = await _taskRepository.updateTask(task);
      
      // Update with server response
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating task: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  // Update task status
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    try {
      // Update status optimistically
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(stage: newStatus);
        notifyListeners();
      }
      
      // Call repository to update status
      await _taskRepository.updateTaskStatus(taskId, newStatus);
    } catch (e) {
      debugPrint('Error updating task status: $e');
      rethrow;
    }
  }
  
  // Move task to trash
  Future<void> moveToTrash(String taskId) async {
    try {
      // Optimistic update - move to trash locally first
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      Task? task;
      
      if (taskIndex != -1) {
        task = _tasks[taskIndex];
        _tasks.removeAt(taskIndex);
        _trashTasks.add(task);
        notifyListeners();
      }
      
      // Call repository to move to trash
      await _taskRepository.moveToTrash(taskId);
    } catch (e) {
      debugPrint('Error moving task to trash: $e');
      rethrow;
    }
  }
  
  // Restore task from trash
  Future<void> restoreFromTrash(String taskId) async {
    try {
      // Optimistic update - restore locally first
      final taskIndex = _trashTasks.indexWhere((task) => task.id == taskId);
      Task? task;
      
      if (taskIndex != -1) {
        task = _trashTasks[taskIndex];
        _trashTasks.removeAt(taskIndex);
        _tasks.add(task);
        notifyListeners();
      }
      
      // Call repository to restore from trash
      await _taskRepository.restoreFromTrash(taskId);
    } catch (e) {
      debugPrint('Error restoring task from trash: $e');
      rethrow;
    }
  }
  
  // Permanently delete task locally
  void permanentlyDeleteTask(String taskId) {
    _trashTasks.removeWhere((task) => task.id == taskId);
    notifyListeners();
  }
  
  // Permanently delete task from backend
  Future<void> permanentlyDeleteTaskFromBackend(String taskId) async {
    try {
      // Optimistic update - remove from local state first
      final taskIndex = _trashTasks.indexWhere((task) => task.id == taskId);
      
      if (taskIndex != -1) {
        _trashTasks.removeAt(taskIndex);
        notifyListeners();
      }
      
      // Call repository to permanently delete task
      await _taskRepository.permanentlyDeleteTask(taskId);
    } catch (e) {
      debugPrint('Error deleting task permanently: $e');
      rethrow;
    }
  }
  
  // Clear trash
  Future<void> clearTrash() async {
    try {
      // Optimistic update - clear local trash first
      _trashTasks.clear();
      notifyListeners();
      
      // Call repository to clear trash
      await _taskRepository.clearTrash();
    } catch (e) {
      debugPrint('Error clearing trash: $e');
      rethrow;
    }
  }
  
  // Fetch tasks
  Future<void> fetchTasks() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Call repository to fetch tasks
      _tasks = await _taskRepository.fetchTasks();
      _error = null;
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      _error = e.toString();
      _tasks = []; // Clear tasks on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Fetch trash tasks
  Future<void> fetchTrashTasks() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Call repository to fetch trash tasks
      _trashTasks = await _taskRepository.fetchTrashTasks();
      _error = null;
    } catch (e) {
      debugPrint('Error fetching trash tasks: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get normal users for task assignment
  Future<List<Map<String, dynamic>>> getNormalUsers() async {
    return _userRepository.fetchAllUsers();
  }
  
  // Get task details
  Future<Map<String, dynamic>> getTaskDetails(String taskId) async {
    return _taskRepository.getTaskDetails(taskId);
  }
  
  // Create a new task
  Future<Task> createTask(Task task) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final createdTask = await _taskRepository.addTask(task);
      _tasks.add(createdTask);
      notifyListeners();
      return createdTask;
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
