import 'package:flutter/material.dart';
import 'package:tasks/models/notification.dart' as app_notification;
import 'package:intl/intl.dart';
import 'package:tasks/pages/tasks/widgets/task_details_dialog.dart';
import 'package:tasks/pages/inbox/chat_screen.dart';

class NotificationItem extends StatelessWidget {
  final app_notification.Notification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationItem({
    Key? key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
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
      case 'message_received':
        return Icons.chat;
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
      case 'message_received':
        return Colors.teal;
      case 'general':
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red.shade100,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(
          Icons.delete,
          color: Colors.red,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        onDelete();
      },
      child: InkWell(
        onTap: () {
          onTap();
          // If there's a related task, open task details directly
          if (notification.relatedTaskId != null) {
            showDialog(
              context: context,
              builder: (context) => TaskDetailsDialog(
                taskId: notification.relatedTaskId!,
              ),
            );
          }
          // If there's a related message, navigate to the chat screen
          else if (notification.type == 'message_received' &&
              notification.createdById != null) {
            // Close the notification dialog first
            Navigator.of(context, rootNavigator: true).pop();
            // Navigate to the chat screen with the sender's ID
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  userId: notification.createdById!,
                  userName: notification.createdByName,
                ),
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12.0),
            border: notification.isRead
                ? Border.all(color: Colors.grey.shade200, width: 1.0)
                : Border.all(color: Colors.blue.shade200, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and type
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: _getNotificationColor().withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getNotificationIcon(),
                        color: _getNotificationColor(),
                        size: 18.0,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            _getNotificationTypeText(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                              color: _getNotificationColor(),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              margin: const EdgeInsets.only(left: 8.0),
                              width: 8.0,
                              height: 8.0,
                              decoration: BoxDecoration(
                                color: _getNotificationColor(),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
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

              // Message content
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 12.0),
                child: Text(
                  notification.message,
                  style: TextStyle(
                    fontWeight: notification.isRead
                        ? FontWeight.normal
                        : FontWeight.bold,
                    fontSize: 14.0,
                    color: notification.isRead
                        ? const Color(0xFF666666)
                        : const Color(0xFF333333),
                  ),
                ),
              ),

              // From section if available
              if (notification.createdByName != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12.0),
                      bottomRight: Radius.circular(12.0),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person,
                        color: Colors.blue,
                        size: 16.0,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'From: ${notification.createdByName}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                          fontSize: 12.0,
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
      case 'message_received':
        return 'New Message';
      case 'general':
      default:
        return 'General Notification';
    }
  }
}
