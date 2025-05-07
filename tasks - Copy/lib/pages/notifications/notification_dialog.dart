import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasks/pages/notifications/notification_list.dart';
import 'package:tasks/providers/notification_provider.dart';

class NotificationDialog extends StatelessWidget {
  const NotificationDialog({Key? key}) : super(key: key);

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
        height: MediaQuery.of(context).size.height * 0.7,
        constraints: const BoxConstraints(maxWidth: 500),
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
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Consumer<NotificationProvider>(
                    builder: (context, notificationProvider, child) {
                      final unreadCount = notificationProvider.unreadCount;
                      return Row(
                        children: [
                          const Icon(
                            Icons.notifications,
                            color: Colors.blue,
                            size: 24.0,
                          ),
                          const SizedBox(width: 12.0),
                          const Text(
                            'Notifications',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8.0),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 2.0),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF666666)),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      padding: const EdgeInsets.all(8.0),
                    ),
                  ),
                ],
              ),
            ),
            Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                final hasNotifications =
                    notificationProvider.notifications.isNotEmpty;
                final unreadCount = notificationProvider.unreadCount;

                if (hasNotifications) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            // Show confirmation dialog
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete All Notifications'),
                                content: const Text(
                                  'Are you sure you want to delete all notifications? This action cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      notificationProvider
                                          .deleteAllNotifications();
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Delete All'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.delete_sweep,
                              size: 16.0, color: Colors.red),
                          label: const Text('Delete All'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                            textStyle: const TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (unreadCount > 0)
                          TextButton.icon(
                            onPressed: () {
                              notificationProvider.markAllAsRead();
                            },
                            icon: const Icon(Icons.done_all, size: 16.0),
                            label: const Text('Mark all as read'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 8.0),
                              textStyle: const TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            Expanded(
              child: NotificationList(
                onClose: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
