import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasks/providers/notification_provider.dart';
import 'notification_item.dart';

class NotificationList extends StatefulWidget {
  final Function onClose;

  const NotificationList({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  @override
  void initState() {
    super.initState();
    // Refresh notifications when the list is opened
    Future.microtask(() {
      Provider.of<NotificationProvider>(context, listen: false)
          .fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        if (notificationProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (notificationProvider.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Error loading notifications',
                  style: TextStyle(color: Colors.red[700]),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    notificationProvider.clearError();
                    notificationProvider.fetchNotifications();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final notifications = notificationProvider.notifications;

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications',
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

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return NotificationItem(
              notification: notification,
              onTap: () {
                notificationProvider.markAsRead(notification.id);
                // The notification item will handle opening the task details directly
              },
              onDelete: () {
                notificationProvider.deleteNotification(notification.id);
              },
            );
          },
        );
      },
    );
  }
}
