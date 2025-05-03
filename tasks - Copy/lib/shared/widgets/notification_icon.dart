import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class NotificationIcon extends StatefulWidget {
  final String userId;

  const NotificationIcon({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon> {
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final count = await _notificationService.getUnreadNotificationCount(widget.userId);
    if (mounted) {
      setState(() {
        _unreadCount = count;
      });
    }
  }

  void _handleNotificationTap() async {
    await _notificationService.markAsRead(widget.userId);
    _loadNotifications();
    // TODO: Navigate to notifications screen or show notification list
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: _handleNotificationTap,
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
} 