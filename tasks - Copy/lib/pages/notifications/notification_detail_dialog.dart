import 'package:flutter/material.dart';
import 'package:tasks/models/notification.dart' as app_notification;
import 'package:intl/intl.dart';
import 'package:tasks/pages/tasks/widgets/task_details_dialog.dart';

class NotificationDetailDialog extends StatelessWidget {
  final app_notification.Notification notification;

  const NotificationDetailDialog({
    Key? key,
    required this.notification,
  }) : super(key: key);

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case 'task_created':
        return Icons.add_task;
      case 'task_updated':
        return Icons.update;
      case 'task_due':
        return Icons.alarm;
      case 'task_trashed':
        return Icons.delete;
      case 'task_restored':
        return Icons.restore;
      case 'task_deleted':
        return Icons.delete_forever;
      case 'general':
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor() {
    switch (notification.type) {
      case 'task_created':
        return Colors.green;
      case 'task_updated':
        return Colors.blue;
      case 'task_due':
        return Colors.orange;
      case 'task_trashed':
        return Colors.red;
      case 'task_restored':
        return Colors.purple;
      case 'task_deleted':
        return Colors.red.shade900;
      case 'general':
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy - h:mm a').format(date);
  }

  String _getNotificationTypeText() {
    switch (notification.type) {
      case 'task_created':
        return 'Task Created';
      case 'task_updated':
        return 'Task Updated';
      case 'task_due':
        return 'Task Due Soon';
      case 'task_trashed':
        return 'Task Moved to Trash';
      case 'task_restored':
        return 'Task Restored';
      case 'task_deleted':
        return 'Task Deleted';
      case 'general':
      default:
        return 'General Notification';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and type
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: _getNotificationColor().withAlpha(25),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(
                      _getNotificationIcon(),
                      color: _getNotificationColor(),
                      size: 24.0,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getNotificationTypeText(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          _formatDate(notification.createdAt),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Message content
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
              ),
              child: Text(
                notification.message,
                style: const TextStyle(
                  fontSize: 16.0,
                  color: Color(0xFF333333),
                ),
              ),
            ),

            // From section
            if (notification.createdByName != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person,
                      color: Colors.blue,
                      size: 18.0,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      'From: ${notification.createdByName}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
              ),

            // Action buttons
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (notification.relatedTaskId != null)
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        showDialog(
                          context: context,
                          builder: (context) => TaskDetailsDialog(
                            taskId: notification.relatedTaskId!,
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: _getNotificationColor(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'View Task',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  const SizedBox(width: 8.0),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.grey.shade800,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
