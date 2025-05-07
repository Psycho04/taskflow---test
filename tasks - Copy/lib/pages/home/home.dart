import 'package:flutter/material.dart';
import 'package:tasks/pages/dashboard/dashboard.dart';
import 'package:tasks/pages/tasks/tasks.dart';
import 'package:tasks/pages/team/team.dart';
import 'package:tasks/pages/trash/trash.dart';
import 'package:tasks/pages/ai/task_mate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'widgets/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tasks/providers/task_provider.dart';
import 'package:tasks/providers/notification_provider.dart';
import 'package:tasks/pages/groupchat/group_chat.dart';

class Home extends StatefulWidget {
  static const String routeName = 'Home';
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      final args = ModalRoute.of(context)?.settings.arguments;

      // Always fetch notifications when the home page initializes
      if (mounted) {
        Future.microtask(() {
          if (mounted) {
            Provider.of<NotificationProvider>(context, listen: false)
                .fetchNotifications();
          }
        });
      }

      // Fetch tasks if just logged in
      if (args is Map && args['justLoggedIn'] == true) {
        Future.microtask(() {
          if (mounted) {
            Provider.of<TaskProvider>(context, listen: false).fetchTasks();
          }
        });
      }

      _didInit = true;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _showProfileDialog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');

      if (userDataString == null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final userData = json.decode(userDataString);
      final String name = userData['name'] ?? 'N/A';
      final String email = userData['email'] ?? 'N/A';
      final String role = userData['role'] ?? 'user';
      final String? imageUrl = userData['image'];

      String formattedDate = 'N/A';
      if (userData['createdAt'] != null) {
        try {
          final DateTime createdAt =
              DateTime.parse(userData['createdAt'].toString());
          formattedDate =
              '${createdAt.day}/${createdAt.month}/${createdAt.year}';
        } catch (e) {
          formattedDate = 'Date format error';
        }
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => ProfileDialog(
          name: name,
          email: email,
          role: role,
          jobTitle: userData['jobTitle'] ?? 'Not specified',
          formattedDate: formattedDate,
          imageUrl: imageUrl,
          onProfileUpdated: () {
            // Refresh the UI after profile update
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const Dashboard();
      case 1:
        return const Tasks();
      case 2:
        return const Team();
      case 3:
        return const Trash();
      default:
        return const Dashboard();
    }
  }

  void _navigateToAi() {
    Navigator.pop(context); // Close the drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TaskMate()),
    );
  }

  void _navigateToGroupChat() {
    Navigator.pop(context); // Close the drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GroupChatPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.forum),
              title: const Text('Group Chat'),
              onTap: _navigateToGroupChat,
            ),
            ListTile(
              leading: const Icon(Icons.smart_toy),
              title: const Text('AI'),
              onTap: _navigateToAi,
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                _showProfileDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => const LogoutDialog(),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      body: _buildBody(),
    );
  }
}
