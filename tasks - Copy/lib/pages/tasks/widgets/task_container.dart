import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasks/models/task.dart';
import 'package:tasks/pages/tasks/widgets/task_details_dialog.dart';
import 'package:tasks/providers/task_provider.dart';

class TaskContainer extends StatelessWidget {
  final String title;
  final String? description;
  final String priority;
  final DateTime date;
  final String stage;
  final String? id;
  final List<Map<String, dynamic>> assignees;
  final Function(String, String) onStatusChange;
  final bool isAdmin;

  const TaskContainer({
    super.key,
    required this.title,
    this.description,
    required this.priority,
    required this.date,
    required this.stage,
    this.id,
    this.assignees = const [],
    required this.onStatusChange,
    required this.isAdmin,
  });

  Color _getPriorityColor() {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFFF5252);
      case 'medium':
        return const Color(0xFFFFB74D);
      case 'low':
        return const Color(0xFF81C784);
      default:
        return Colors.grey;
    }
  }

  String _formatStageText(String stage) {
    switch (stage.toLowerCase().replaceAll(' ', '')) {
      case 'todo':
        return 'To Do';
      case 'inprogress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return stage;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase().replaceAll(' ', '')) {
      case 'todo':
        return const Color(0xFFFF9800);
      case 'inprogress':
        return const Color(0xFF2196F3);
      case 'completed':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase().replaceAll(' ', '')) {
      case 'todo':
        return Icons.assignment_late_outlined;
      case 'inprogress':
        return Icons.assignment_turned_in_outlined;
      case 'completed':
        return Icons.assignment_turned_in;
      default:
        return Icons.assignment_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
        border: Border(
          left: BorderSide(
            color: _getPriorityColor(),
            width: 4,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => TaskDetailsDialog(taskId: id!),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: _getPriorityColor(),
                    width: 4,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Priority and Status
                    Row(
                      children: [
                        _buildPriorityBadge(),
                        const SizedBox(width: 8),
                        _buildStatusBadge(),
                        Spacer(),
                        if (isAdmin) _buildMenuButton(context),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    // Description
                    if (description != null && description!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          description!,
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.5),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Avatars and Calendar Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildAvatars(assignees),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              '${date.day}/${date.month}/${date.year}',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Start Task Button
                    if (stage.toLowerCase().replaceAll(' ', '') == 'todo')
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () {
                              if (id != null) onStatusChange(id!, 'inprogress');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Start Task',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getPriorityColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            priority.toLowerCase() == 'high'
                ? Icons.keyboard_double_arrow_up
                : priority.toLowerCase() == 'medium'
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
            color: _getPriorityColor(),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            priority,
            style: TextStyle(
              color: _getPriorityColor(),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(stage).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(stage),
            size: 16,
            color: _getStatusColor(stage),
          ),
          const SizedBox(width: 4),
          Text(
            _formatStageText(stage),
            style: TextStyle(
              color: _getStatusColor(stage),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Colors.grey.shade600,
        size: 20,
      ),
      onSelected: (value) {
        if (value == 'edit') {
          _showEditDialog(context);
        } else if (value == 'delete') {
          _showDeleteConfirmation(context);
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Update'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatars(List<Map<String, dynamic>> assignees) {
    return Expanded(
      child: Wrap(
        spacing: 4,
        runSpacing: 8,
        children: assignees.map((assignee) {
          String fullName = assignee['fullName']?.toString().trim() ?? '';
          if (fullName.isEmpty) {
            fullName = assignee['name']?.toString().trim() ?? '';
          }
          if (fullName.isEmpty) {
            final email = assignee['email']?.toString() ?? '';
            if (email.isNotEmpty) {
              final username = email.split('@')[0];
              fullName = username.replaceAll(RegExp(r'[._-]+'), ' ');
            }
          }
          String initials;
          if (fullName.isEmpty) {
            initials = 'U';
          } else {
            final names = fullName
                .split(RegExp(r'\\s+'))
                .where((n) => n.isNotEmpty)
                .toList();
            if (names.length >= 2) {
              initials = (names.first[0] + names.last[0]).toUpperCase();
            } else if (names.length == 1) {
              initials = names[0][0].toUpperCase();
            } else {
              initials = 'U';
            }
          }
          return Tooltip(
            message: fullName.isEmpty ? 'Unknown User' : fullName,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                initials,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final TextEditingController titleController =
        TextEditingController(text: title);
    final TextEditingController descriptionController =
        TextEditingController(text: description ?? '');
    String selectedPriority = priority.toLowerCase() == 'medium'
        ? 'Medium'
        : priority.toLowerCase() == 'high'
            ? 'High'
            : priority.toLowerCase() == 'low'
                ? 'Low'
                : 'Medium'; // Default to Medium if invalid value
    String selectedStage = stage.toLowerCase().replaceAll(' ', '') == 'todo'
        ? 'To Do'
        : stage.toLowerCase().replaceAll(' ', '') == 'inprogress'
            ? 'In Progress'
            : stage.toLowerCase().replaceAll(' ', '') == 'completed'
                ? 'Completed'
                : 'To Do'; // Default to To Do if invalid value
    DateTime selectedDate = date;
    List<Map<String, dynamic>> selectedAssignees = List.from(assignees);
    List<Map<String, dynamic>> teamMembers = [];
    bool isLoadingUsers = true;
    String? errorMessage;

    // Load users from the API
    void loadUsers(StateSetter setDialogState) async {
      try {
        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        final users = await taskProvider.getNormalUsers();

        // Double-check to ensure only non-admin users are shown
        final normalUsers = users
            .where((user) => user['role']?.toString().toLowerCase() == 'user')
            .map((user) => {
                  '_id': user['_id'],
                  'fullName': user['fullName'],
                  'email': user['email'],
                  'role': user['role']
                })
            .toList();

        setDialogState(() {
          teamMembers = normalUsers;
          isLoadingUsers = false;
          errorMessage = null;
        });
      } catch (e) {
        print('Error loading users: $e');
        setDialogState(() {
          isLoadingUsers = false;
          errorMessage = 'Failed to load users. Please try again.';
          teamMembers = [];
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with gradient
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Edit Task',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Form Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Task Title
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: 'Task Title',
                            prefixIcon: const Icon(Icons.title),
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
                              borderSide: const BorderSide(
                                  color: Colors.blue, width: 1),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Description
                        TextField(
                          controller: descriptionController,
                          maxLines: null, // Allow unlimited lines
                          minLines: 3, // Start with 3 lines
                          keyboardType:
                              TextInputType.multiline, // Enable multiline input
                          textInputAction:
                              TextInputAction.newline, // Add new line on enter
                          decoration: InputDecoration(
                            labelText: 'Description',
                            alignLabelWithHint:
                                true, // Align label with the hint text
                            prefixIcon: const Icon(Icons.description_outlined),
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
                              borderSide: const BorderSide(
                                  color: Colors.blue, width: 1),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            hintText: 'Enter task description here...',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Priority
                        DropdownButtonFormField<String>(
                          value: selectedPriority,
                          decoration: InputDecoration(
                            labelText: 'Priority',
                            prefixIcon: const Icon(Icons.flag_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items:
                              const ['High', 'Medium', 'Low'].map((priority) {
                            Color priorityColor = priority == 'High'
                                ? Colors.red
                                : priority == 'Medium'
                                    ? Colors.yellow
                                    : Colors.green;
                            return DropdownMenuItem(
                              value: priority,
                              child: Row(
                                children: [
                                  Icon(Icons.circle,
                                      size: 12, color: priorityColor),
                                  const SizedBox(width: 8),
                                  Text(priority),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedPriority = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // Stage
                        DropdownButtonFormField<String>(
                          value: selectedStage,
                          decoration: InputDecoration(
                            labelText: 'Stage',
                            prefixIcon: const Icon(Icons.layers_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: const ['To Do', 'In Progress', 'Completed']
                              .map((stage) => DropdownMenuItem(
                                    value: stage,
                                    child: Text(stage),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedStage = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // Assignees
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.people_outline,
                                          color: Colors.blue.shade700,
                                          size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Assign to',
                                      style: TextStyle(
                                        color: Colors.grey.shade800,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${selectedAssignees.length} selected',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selectedAssignees.isNotEmpty)
                                Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: selectedAssignees.map((assignee) {
                                      final name =
                                          assignee['fullName']?.toString() ??
                                              'Unknown';
                                      String initials;
                                      if (name.trim().isEmpty) {
                                        initials = 'U';
                                      } else {
                                        final names = name
                                            .trim()
                                            .split(RegExp(r'\\s+'))
                                            .where((n) => n.isNotEmpty)
                                            .toList();
                                        if (names.length >= 2) {
                                          initials =
                                              (names.first[0] + names.last[0])
                                                  .toUpperCase();
                                        } else if (names.length == 1) {
                                          initials = names[0][0].toUpperCase();
                                        } else {
                                          initials = 'U';
                                        }
                                      }

                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color: Colors.blue.shade200),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircleAvatar(
                                                radius: 12,
                                                backgroundColor:
                                                    Colors.blue.shade100,
                                                child: Text(
                                                  initials,
                                                  style: TextStyle(
                                                    color: Colors.blue.shade700,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                name,
                                                style: TextStyle(
                                                  color: Colors.blue.shade800,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              InkWell(
                                                onTap: () {
                                                  setDialogState(() {
                                                    selectedAssignees
                                                        .remove(assignee);
                                                  });
                                                },
                                                child: Icon(
                                                  Icons.close,
                                                  size: 16,
                                                  color: Colors.blue.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        titlePadding: const EdgeInsets.fromLTRB(
                                            24, 24, 24, 0),
                                        contentPadding:
                                            const EdgeInsets.fromLTRB(
                                                24, 16, 24, 24),
                                        title: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.people_outline,
                                                    color:
                                                        Colors.blue.shade700),
                                                const SizedBox(width: 8),
                                                const Text('Select Assignees'),
                                                const Spacer(),
                                                IconButton(
                                                  icon: const Icon(Icons.close),
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  color: Colors.grey.shade600,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        content: SizedBox(
                                          width: double.maxFinite,
                                          child: StatefulBuilder(
                                            builder:
                                                (context, setSelectionState) {
                                              if (isLoadingUsers) {
                                                loadUsers(setSelectionState);
                                                return const Center(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(20),
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                );
                                              }

                                              if (errorMessage != null) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.all(20),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.error_outline,
                                                          color: Colors
                                                              .red.shade400,
                                                          size: 48),
                                                      const SizedBox(
                                                          height: 16),
                                                      Text(
                                                        errorMessage!,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                            color: Colors
                                                                .red.shade700),
                                                      ),
                                                      const SizedBox(
                                                          height: 16),
                                                      ElevatedButton(
                                                        onPressed: () => loadUsers(
                                                            setSelectionState),
                                                        child:
                                                            const Text('Retry'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }

                                              if (teamMembers.isEmpty) {
                                                return const Padding(
                                                  padding: EdgeInsets.all(20),
                                                  child: Text(
                                                      'No team members available'),
                                                );
                                              }

                                              return Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    constraints:
                                                        const BoxConstraints(
                                                            maxHeight: 300),
                                                    child: ListView.builder(
                                                      shrinkWrap: true,
                                                      itemCount:
                                                          teamMembers.length,
                                                      itemBuilder:
                                                          (context, index) {
                                                        final member =
                                                            teamMembers[index];
                                                        final userId = member[
                                                                    '_id']
                                                                ?.toString() ??
                                                            '';
                                                        final name = member[
                                                                    'fullName']
                                                                ?.toString() ??
                                                            'Unknown User';
                                                        final email = member[
                                                                    'email']
                                                                ?.toString() ??
                                                            '';
                                                        final role = member[
                                                                    'role']
                                                                ?.toString() ??
                                                            'user';

                                                        final isSelected =
                                                            selectedAssignees.any(
                                                                (assignee) =>
                                                                    assignee[
                                                                        'id'] ==
                                                                    userId);

                                                        String initials;
                                                        if (name
                                                            .trim()
                                                            .isEmpty) {
                                                          initials = 'U';
                                                        } else {
                                                          final names = name
                                                              .trim()
                                                              .split(RegExp(
                                                                  r'\\s+'))
                                                              .where((n) =>
                                                                  n.isNotEmpty)
                                                              .toList();
                                                          if (names.length >=
                                                              2) {
                                                            initials = (names
                                                                            .first[
                                                                        0] +
                                                                    names.last[
                                                                        0])
                                                                .toUpperCase();
                                                          } else if (names
                                                                  .length ==
                                                              1) {
                                                            initials = names[0]
                                                                    [0]
                                                                .toUpperCase();
                                                          } else {
                                                            initials = 'U';
                                                          }
                                                        }

                                                        return Container(
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  bottom: 8),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: isSelected
                                                                ? Colors.blue
                                                                    .shade50
                                                                : Colors.white,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                            border: Border.all(
                                                              color: isSelected
                                                                  ? Colors.blue
                                                                      .shade200
                                                                  : Colors.grey
                                                                      .shade200,
                                                            ),
                                                          ),
                                                          child:
                                                              CheckboxListTile(
                                                            value: isSelected,
                                                            activeColor: Colors
                                                                .blue.shade700,
                                                            checkColor:
                                                                Colors.white,
                                                            onChanged:
                                                                (bool? value) {
                                                              setSelectionState(
                                                                  () {
                                                                if (value ==
                                                                    true) {
                                                                  if (!selectedAssignees.any((assignee) =>
                                                                      assignee[
                                                                          'id'] ==
                                                                      userId)) {
                                                                    selectedAssignees
                                                                        .add({
                                                                      'id':
                                                                          userId,
                                                                      'fullName':
                                                                          name,
                                                                      'email':
                                                                          email,
                                                                      'role':
                                                                          role
                                                                    });
                                                                  }
                                                                } else {
                                                                  selectedAssignees.removeWhere(
                                                                      (assignee) =>
                                                                          assignee[
                                                                              'id'] ==
                                                                          userId);
                                                                }
                                                              });
                                                            },
                                                            title: Row(
                                                              children: [
                                                                CircleAvatar(
                                                                  radius: 16,
                                                                  backgroundColor:
                                                                      Colors
                                                                          .blue
                                                                          .shade100,
                                                                  child: Text(
                                                                    initials,
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .blue
                                                                          .shade700,
                                                                      fontSize:
                                                                          14,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    width: 12),
                                                                Expanded(
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Text(
                                                                        name,
                                                                        style:
                                                                            TextStyle(
                                                                          fontWeight: isSelected
                                                                              ? FontWeight.w600
                                                                              : FontWeight.normal,
                                                                          color: isSelected
                                                                              ? Colors.blue.shade800
                                                                              : Colors.black87,
                                                                        ),
                                                                      ),
                                                                      Text(
                                                                        role,
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              12,
                                                                          color: Colors
                                                                              .grey
                                                                              .shade600,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            contentPadding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        12,
                                                                    vertical:
                                                                        4),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add),
                                  label: Text(selectedAssignees.isEmpty
                                      ? 'Add Assignees'
                                      : 'Add More'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              if (selectedAssignees.isEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline,
                                            color: Colors.grey.shade600,
                                            size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'No assignees selected. Click the button above to add team members.',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Date
                        InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Colors.blue.shade700,
                                      onPrimary: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Due Date',
                              prefixIcon:
                                  const Icon(Icons.calendar_today_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            child: Text(
                              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () {
                                if (id != null) {
                                  // Validate due date
                                  final now = DateTime.now();
                                  final today =
                                      DateTime(now.year, now.month, now.day);
                                  final dueDate = DateTime(selectedDate.year,
                                      selectedDate.month, selectedDate.day);

                                  if (dueDate.isBefore(today)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                            'Due date must be today or a future date'),
                                        backgroundColor: Colors.red.shade700,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  try {
                                    final taskProvider =
                                        Provider.of<TaskProvider>(context,
                                            listen: false);

                                    // Extract just the IDs from selected assignees
                                    final assigneeIds = selectedAssignees
                                        .map((assignee) =>
                                            assignee['id']?.toString() ?? '')
                                        .where((id) => id.isNotEmpty)
                                        .toList();

                                    taskProvider.updateTask(Task(
                                      id: id!,
                                      title: titleController.text,
                                      description: descriptionController.text,
                                      priority: selectedPriority.toLowerCase(),
                                      date: selectedDate,
                                      stage: selectedStage
                                          .replaceAll(' ', '')
                                          .toLowerCase(),
                                      assignees: assigneeIds
                                          .map((id) => {
                                                'id': id,
                                              })
                                          .toList(),
                                    ));

                                    Navigator.pop(context);
                                  } catch (e) {
                                    print('Error updating task: $e');
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Failed to update task: ${e.toString()}'),
                                        backgroundColor: Colors.red.shade700,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Save Changes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red.shade700,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Delete Task',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to delete "$title"?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (id != null) {
                          final taskProvider =
                              Provider.of<TaskProvider>(context, listen: false);
                          taskProvider.moveToTrash(id!);

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Task moved to trash'),
                              backgroundColor: Colors.blue.shade700,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              duration: const Duration(seconds: 2),
                              action: SnackBarAction(
                                label: 'Undo',
                                textColor: Colors.white,
                                onPressed: () {
                                  // Restore the task from trash
                                  taskProvider.restoreFromTrash(id!);
                                },
                              ),
                            ),
                          );
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
