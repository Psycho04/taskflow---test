import 'package:flutter/material.dart';
import 'package:tasks/models/task.dart';
import 'package:provider/provider.dart';
import 'package:tasks/providers/task_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AddTaskDialog extends StatefulWidget {
  final Function(Task) onTaskAdded;

  const AddTaskDialog({
    super.key,
    required this.onTaskAdded,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedPriority;
  DateTime _selectedDate = DateTime.now();
  final List<String> _selectedAssignees = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _assigneeValidationAttempted = false;
  List<Map<String, dynamic>> _users = [];
  bool _isLoadingUsers = true;
  String? _currentUserId;

  final List<String> _priorities = ['High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');

      if (userDataString != null) {
        final userData = json.decode(userDataString);
        if (mounted) {
          setState(() {
            _currentUserId = userData['_id'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }

  void _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
      _errorMessage = null;
    });

    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final users = await taskProvider.getNormalUsers();

      // Filter to ensure only non-admin users are shown
      final normalUsers = users
          .where((user) => user['role']?.toString().toLowerCase() == 'user')
          .toList();

      if (!mounted) return;
      setState(() {
        _users = normalUsers;
        _isLoadingUsers = false;
        _errorMessage = null;
      });

      // Print users for debugging
      debugPrint('Loaded users: $_users');

      // If no users are found after filtering
      if (_users.isEmpty) {
        setState(() {
          _errorMessage = 'No team members available';
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingUsers = false;
        _errorMessage = 'Failed to load users. Please try again.';
        _users = [];
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;

    // Set flag that validation has been attempted
    setState(() {
      _assigneeValidationAttempted = true;
    });

    // Check if assignees are selected
    if (_selectedAssignees.isEmpty) {
      setState(() {
        _errorMessage =
            'Please select at least one team member to assign the task to';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Convert selected assignee IDs to the required format
      final formattedAssignees = _selectedAssignees.map((id) {
        // Find the full user data from _users list
        final userData = _users.firstWhere(
          (user) => user['_id'] == id,
          orElse: () => {'_id': id, 'fullName': '', 'email': ''},
        );

        return {
          'id': userData['_id'] ?? id,
          'fullName': userData['fullName'] ?? '',
          'email': userData['email'] ?? '',
        };
      }).toList();

      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        priority: _selectedPriority?.toLowerCase() ?? 'medium',
        date: _selectedDate,
        stage: 'to do',
        assignees: formattedAssignees,
      );

      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final success = await taskProvider.addTask(task);

      if (success) {
        // First update the parent
        widget.onTaskAdded(task);

        // Then clear loading state and close dialog
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _errorMessage =
              taskProvider.error ?? 'Failed to create task. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showAssigneesDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 300,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.people_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Text(
                      'Select Team Members',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (_isLoadingUsers)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_users.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage ?? 'No team members available',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _loadUsers();
                          Navigator.pop(context);
                          _showAssigneesDialog();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: StatefulBuilder(
                    builder: (context, setDialogState) => ListView.builder(
                      shrinkWrap: true,
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final userId = user['_id']?.toString() ?? '';
                        final userName = user['fullName']?.toString() ?? '';
                        final jobTitle =
                            user['jobTitle']?.toString() ?? 'Employee';
                        final isSelected = _selectedAssignees.contains(userId);

                        // Print user data for debugging
                        debugPrint('User at index $index: $user');

                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                userName.isNotEmpty
                                    ? userName[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(userName),
                            subtitle: Text(
                              jobTitle,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setDialogState(() {
                                  if (value == true) {
                                    _selectedAssignees.add(userId);
                                  } else {
                                    _selectedAssignees.remove(userId);
                                  }
                                });
                                setState(() {}); // Update parent state
                              },
                            ),
                            onTap: () {
                              setDialogState(() {
                                if (isSelected) {
                                  _selectedAssignees.remove(userId);
                                } else {
                                  _selectedAssignees.add(userId);
                                }
                              });
                              setState(() {}); // Update parent state
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add New Task',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create a new task for your team',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: Colors.grey[600],
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red.shade400, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter task title',
                      prefixIcon: const Icon(Icons.title_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.blue.shade400, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      if (value.length < 2) {
                        return 'Title must be at least 2 characters';
                      }
                      if (value.length > 50) {
                        return 'Title must be at most 50 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter task description',
                      prefixIcon: const Icon(Icons.description_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.blue.shade400, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      alignLabelWithHint: true,
                    ),
                    minLines: 1,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      if (value.length < 10) {
                        return 'Description must be at least 10 characters';
                      }
                      if (value.length > 100) {
                        return 'Description must be at most 100 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);

                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate.isBefore(today)
                            ? today
                            : _selectedDate,
                        firstDate: today,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: Colors.blue.shade400,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            23,
                            59,
                            59,
                          );
                        });
                      }
                    },
                    child: IgnorePointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Due Date',
                          hintText: 'Select due date',
                          prefixIcon: const Icon(Icons.calendar_today_outlined),
                          suffixIcon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey.shade600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.blue.shade400, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        controller: TextEditingController(
                          text:
                              "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          value: _selectedPriority,
                          hint: const Text(
                            'Select Priority',
                            style: TextStyle(fontSize: 14),
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            labelText: 'Priority',
                            prefixIcon: const Icon(Icons.flag_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.blue.shade400, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: _priorities.map((priority) {
                            Color priorityColor = priority == 'High'
                                ? const Color(0xFFE53935)
                                : priority == 'Medium'
                                    ? const Color(0xFFFB8C00)
                                    : const Color(0xFF43A047);
                            return DropdownMenuItem(
                              value: priority,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle,
                                      size: 12, color: priorityColor),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      priority,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPriority = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a priority';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          enabled: false,
                          initialValue: 'To Do',
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            labelText: 'Status',
                            prefixIcon: const Icon(Icons.layers_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              Icon(Icons.people_outline,
                                  size: 20, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Team Members',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_selectedAssignees.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedAssignees.map((userId) {
                                final user = _users.firstWhere(
                                    (u) => u['_id'] == userId,
                                    orElse: () => {
                                          '_id': userId,
                                          'fullName': 'Unknown User'
                                        });
                                final name = user['fullName']?.toString() ??
                                    'Unknown User';
                                return Chip(
                                  label: Text(
                                    name,
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: Colors.blue.shade400),
                                  deleteIcon: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.blue.shade400,
                                  ),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedAssignees.remove(userId);
                                    });
                                  },
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 0),
                                );
                              }).toList(),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: ElevatedButton.icon(
                            onPressed: _showAssigneesDialog,
                            icon: const Icon(Icons.person_add_outlined),
                            label: Text(_selectedAssignees.isEmpty
                                ? 'Add Team Members'
                                : 'Add More'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade400,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Add error indicator for assignees
                  if (_assigneeValidationAttempted &&
                      _selectedAssignees.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: Text(
                        'Please select at least one team member',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            _isLoading ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _createTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Create Task',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
