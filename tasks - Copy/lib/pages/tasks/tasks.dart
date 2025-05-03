import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasks/models/task.dart';
import 'package:tasks/providers/task_provider.dart';
import 'package:tasks/pages/tasks/widgets/task_container.dart';
import 'widgets/add_task_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Tasks extends StatefulWidget {
  const Tasks({super.key});

  @override
  State<Tasks> createState() => _TasksState();
}

class _TasksState extends State<Tasks> with SingleTickerProviderStateMixin {
  // State Variables
  late TabController _tabController;
  late List<String> _tabs;
  DateTime selectedDate = DateTime.now();
  final TextEditingController _titleController = TextEditingController();
  String? selectedPriority;
  String? selectedStage;
  bool _isAdmin = false;

  // Filtered tasks based on selected tab
  List<Task> get filteredTasks {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final allTasks = taskProvider.tasks;

    if (_tabController.index == 0) {
      return allTasks;
    } else {
      final selectedStage = _tabs[_tabController.index].toLowerCase().replaceAll(' ', '');
      return allTasks.where((task) => task.stage.toLowerCase().replaceAll(' ', '') == selectedStage).toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _tabs = const [
      'All',
      'To Do',
      'In Progress',
      'Completed'
    ];

    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _checkUserRole();
    
    // Initial tasks fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchTasks();
    });
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token != null) {
      try {
        final parts = token.split('.');
        final payload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
        );
        setState(() {
          _isAdmin = payload['role']?.toString().toLowerCase() == 'admin';
        });
      } catch (e) {
        print('Error checking user role: $e');
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _handleStatusChange(String taskId, String newStatus) {
    if (!mounted) return;
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.updateTaskStatus(taskId, newStatus);
    
    final statusIndex = _tabs.indexWhere(
      (tab) => tab.toLowerCase().replaceAll(' ', '') == newStatus.toLowerCase().replaceAll(' ', '')
    );
    if (statusIndex != -1) {
      _tabController.animateTo(statusIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTabBar(),
            const SizedBox(height: 20),
            Expanded(
              child: Consumer<TaskProvider>(
                builder: (context, taskProvider, child) {
                  if (taskProvider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (taskProvider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                          const SizedBox(height: 16),
                          Text(
                            taskProvider.error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => taskProvider.fetchTasks(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final tasks = filteredTasks;
                  if (tasks.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TaskContainer(
                        key: ValueKey(task.id),
                        id: task.id,
                        title: task.title,
                        description: task.description,
                        priority: task.priority,
                        stage: task.stage,
                        date: task.date,
                        assignees: task.assignees.map((assignee) {
                          return assignee;
                                                }).toList(),
                        onStatusChange: _handleStatusChange,
                        isAdmin: _isAdmin,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () => _showAddTaskDialog(),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 2,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TabBar(
        isScrollable: false,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(15),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
        tabs: _tabs.map((tab) => Tab(
          height: 35,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(tab),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _tabController.index == 0
                ? Icons.assignment_outlined
                : _tabController.index == 1
                    ? Icons.assignment_late_outlined
                    : _tabController.index == 2
                        ? Icons.assignment_turned_in_outlined
                        : Icons.assignment_returned_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No ${_tabs[_tabController.index].toLowerCase()} tasks found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        onTaskAdded: _handleAddTask,
      ),
    );
  }

  void _handleAddTask(Task task) {
    if (!mounted) return;
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
    
    if (taskDate.isBefore(today)) {
      throw Exception('Due date must be today or a future date');
    }
    taskProvider.addTask(task);
  }
}
