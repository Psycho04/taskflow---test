import 'package:flutter/material.dart';
import 'package:tasks/pages/dashboard/dashboard.dart';
import 'package:tasks/pages/tasks/tasks.dart';
import 'package:tasks/pages/team/team.dart';
import 'package:tasks/pages/trash/trash.dart';
import 'package:tasks/pages/ai/ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'widgets/widgets.dart';
import 'package:provider/provider.dart';
import 'package:tasks/providers/task_provider.dart';

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
      if (args is Map && args['justLoggedIn'] == true) {
        Future.microtask(() {
          final taskProvider = Provider.of<TaskProvider>(context, listen: false);
          taskProvider.fetchTasks();
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

  void _handleMenuItemSelected(String value) {
    switch (value) {
      case 'profile':
        _showProfileDialog();
        break;
      case 'logout':
        showDialog(
          context: context,
          builder: (context) => const LogoutDialog(),
        );
        break;
    }
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
      
      String formattedDate = 'N/A';
      if (userData['createdAt'] != null) {
        try {
          final DateTime createdAt = DateTime.parse(userData['createdAt'].toString());
          formattedDate = '${createdAt.day}/${createdAt.month}/${createdAt.year}';
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
          formattedDate: formattedDate,
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
        return const Ai();
      case 4:
        return const Trash();
      default:
        return const Dashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        onMenuItemSelected: _handleMenuItemSelected,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      body: _buildBody(),
    );
  }
}