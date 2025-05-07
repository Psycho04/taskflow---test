import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:tasks/providers/notification_provider.dart';
import 'package:tasks/pages/notifications/notification_dialog.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Fetch notifications when the app bar initializes
    Future.microtask(() {
      if (mounted) {
        Provider.of<NotificationProvider>(context, listen: false)
            .fetchNotifications();
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');

      if (userDataString != null) {
        final userData = json.decode(userDataString);
        if (mounted) {
          setState(() {
            userId = userData['_id'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => const NotificationDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'Task Management',
        style: TextStyle(color: Colors.white),
      ),
      actions: [
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            final unreadCount = notificationProvider.unreadCount;

            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: _showNotifications,
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
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
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
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
          },
        ),
      ],
      backgroundColor: Colors.blue,
    );
  }
}
