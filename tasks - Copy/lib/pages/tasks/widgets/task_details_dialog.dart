import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasks/providers/task_provider.dart';
import 'package:intl/intl.dart';

class TaskDetailsDialog extends StatefulWidget {
  final String taskId;

  const TaskDetailsDialog({
    super.key,
    required this.taskId,
  });

  @override
  State<TaskDetailsDialog> createState() => _TaskDetailsDialogState();
}

class _TaskDetailsDialogState extends State<TaskDetailsDialog> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _taskDetails;

  @override
  void initState() {
    super.initState();
    _loadTaskDetails();
  }

  Future<void> _loadTaskDetails() async {
    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final details = await taskProvider.getTaskDetails(widget.taskId);
      if (mounted) {
        setState(() {
          _taskDetails = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Color _getPriorityColor(String priority) {
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.task_alt,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Task Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      splashRadius: 20,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_error != null)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadTaskDetails,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_taskDetails != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and Priority/Status Section
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _taskDetails!['title'] ?? 'Untitled Task',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      // Priority Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _getPriorityColor(_taskDetails!['priority'] ?? '').withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: _getPriorityColor(_taskDetails!['priority'] ?? '').withOpacity(0.5),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _taskDetails!['priority']?.toString().toLowerCase() == 'high'
                                                  ? Icons.keyboard_double_arrow_up
                                                  : _taskDetails!['priority']?.toString().toLowerCase() == 'medium'
                                                      ? Icons.keyboard_arrow_up
                                                      : Icons.keyboard_arrow_down,
                                              color: _getPriorityColor(_taskDetails!['priority'] ?? ''),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _taskDetails!['priority']?.toString().toUpperCase() ?? 'NONE',
                                              style: TextStyle(
                                                color: _getPriorityColor(_taskDetails!['priority'] ?? ''),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Status Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(_taskDetails!['status'] ?? '').withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: _getStatusColor(_taskDetails!['status'] ?? '').withOpacity(0.5),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _taskDetails!['status']?.toString().toLowerCase() == 'completed'
                                                  ? Icons.check_circle_outline
                                                  : _taskDetails!['status']?.toString().toLowerCase() == 'inprogress'
                                                      ? Icons.pending_outlined
                                                      : Icons.schedule,
                                              color: _getStatusColor(_taskDetails!['status'] ?? ''),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatStageText(_taskDetails!['status'] ?? ''),
                                              style: TextStyle(
                                                color: _getStatusColor(_taskDetails!['status'] ?? ''),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Description Section
                            if (_taskDetails!['description']?.toString().isNotEmpty ?? false)
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey.shade200),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.description_outlined,
                                            size: 20,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Description',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _taskDetails!['description'] ?? '',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey.shade800,
                                        height: 1.5,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Dates Section
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Due Date
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.event,
                                          size: 20,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Due Date',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('MMMM d, y').format(
                                              DateTime.parse(_taskDetails!['dueDate'] ?? ''),
                                            ),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context).primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Created At
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.access_time,
                                          size: 20,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Created At',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('MMMM d, y - h:mm a').format(
                                              DateTime.parse(_taskDetails!['createdAt'] ?? ''),
                                            ),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context).primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Assignees Section
                            if (_taskDetails!['assignedTo']?.isNotEmpty ?? false)
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey.shade200),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.people,
                                            size: 20,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Assigned To',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ...(_taskDetails!['assignedTo'] as List).map((assignee) {
                                      final name = assignee['name']?.toString() ?? 
                                                 assignee['fullName']?.toString() ?? 
                                                 'Unknown User';
                                      final email = assignee['email']?.toString() ?? '';
                                      String initials;
                                      
                                      if (name.trim().isEmpty) {
                                        initials = 'U';
                                      } else {
                                        final nameParts = name.trim().split(' ').where((part) => part.isNotEmpty).toList();
                                        if (nameParts.isEmpty) {
                                          initials = 'U';
                                        } else if (nameParts.length == 1) {
                                          initials = nameParts[0][0];
                                        } else {
                                          initials = '${nameParts[0][0]}${nameParts[1][0]}';
                                        }
                                      }

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                                              child: Text(
                                                initials.toUpperCase(),
                                                style: TextStyle(
                                                  color: Theme.of(context).primaryColor,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  if (email.isNotEmpty)
                                                    Text(
                                                      email,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 