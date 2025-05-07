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
import 'package:tasks/providers/inbox_provider.dart';
import 'package:tasks/providers/group_chat_provider.dart';
import 'package:tasks/pages/groupchat/group_chat.dart';
import 'package:tasks/pages/inbox/users_list.dart';

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

      // Always fetch notifications, inbox senders, and group chat messages when the home page initializes
      if (mounted) {
        // Use addPostFrameCallback to ensure the widget is fully built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Provider.of<NotificationProvider>(context, listen: false)
                .fetchNotifications();
            Provider.of<InboxProvider>(context, listen: false).fetchSenders();
            Provider.of<GroupChatProvider>(context, listen: false)
                .fetchGroupChatMessages();
          }
        });
      }

      // Fetch tasks if just logged in
      if (args is Map && args['justLoggedIn'] == true) {
        // Use addPostFrameCallback to ensure the widget is fully built
        WidgetsBinding.instance.addPostFrameCallback((_) {
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

  void _navigateToInbox() {
    Navigator.pop(context); // Close the drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UsersListPage()),
    );
  }

  // Helper method to build menu items with consistent styling
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: color ?? Colors.blue.shade700,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: color ?? Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        hoverColor: Colors.blue.shade50,
        tileColor: Colors.transparent,
      ),
    );
  }

  // Helper method to build menu items with badge count
  Widget _buildMenuItemWithBadge({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required int badgeCount,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: color ?? Colors.blue.shade700,
          size: 22,
        ),
        title: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: color ?? Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        hoverColor: Colors.blue.shade50,
        tileColor: Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      drawer: Drawer(
        elevation: 10,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Get user data from SharedPreferences
            final prefs = snapshot.data!;
            final userDataString = prefs.getString('userData');
            String name = 'User';
            String email = '';
            String? imageUrl;
            String role = 'user';

            if (userDataString != null) {
              final userData = json.decode(userDataString);
              name = userData['name'] ?? 'User';
              email = userData['email'] ?? '';
              imageUrl = userData['image'];
              role = userData['role'] ?? 'user';
            }

            return Column(
              children: [
                // Enhanced Drawer Header with user info
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue.shade700, Colors.blue.shade500],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26), // ~0.1 opacity
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User avatar
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withAlpha(51), // ~0.2 opacity
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white,
                              backgroundImage: imageUrl != null
                                  ? NetworkImage(
                                      'http://10.0.2.2:5000/uploads/$imageUrl')
                                  : null,
                              child: imageUrl == null
                                  ? Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: TextStyle(
                                    color: Colors.white
                                        .withAlpha(230), // ~0.9 opacity
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withAlpha(51), // ~0.2 opacity
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    role.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
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

                // Menu Items
                Expanded(
                  child: Container(
                    color: Colors.grey.shade50,
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        const SizedBox(height: 8),

                        // Communication Section
                        const Padding(
                          padding:
                              EdgeInsets.only(left: 16, top: 16, bottom: 8),
                          child: Text(
                            'COMMUNICATION',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Group Chat with unread count
                        Consumer<GroupChatProvider>(
                          builder: (context, groupChatProvider, child) {
                            final unreadCount = groupChatProvider.unreadCount;
                            return _buildMenuItemWithBadge(
                              icon: Icons.forum,
                              title: 'Group Chat',
                              onTap: _navigateToGroupChat,
                              badgeCount: unreadCount,
                            );
                          },
                        ),

                        // Chats with unread count
                        Consumer<InboxProvider>(
                          builder: (context, inboxProvider, child) {
                            final unreadCount = inboxProvider.unreadCount;
                            return _buildMenuItemWithBadge(
                              icon: Icons.chat,
                              title: 'Chats',
                              onTap: _navigateToInbox,
                              badgeCount: unreadCount,
                            );
                          },
                        ),

                        const Divider(),

                        // Tools Section
                        const Padding(
                          padding:
                              EdgeInsets.only(left: 16, top: 16, bottom: 8),
                          child: Text(
                            'TOOLS',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // AI
                        _buildMenuItem(
                          icon: Icons.smart_toy,
                          title: 'AI',
                          onTap: _navigateToAi,
                        ),

                        const Divider(),

                        // Account Section
                        const Padding(
                          padding:
                              EdgeInsets.only(left: 16, top: 16, bottom: 8),
                          child: Text(
                            'ACCOUNT',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Profile
                        _buildMenuItem(
                          icon: Icons.person,
                          title: 'Profile',
                          onTap: () {
                            Navigator.pop(context);
                            _showProfileDialog();
                          },
                        ),

                        // Logout
                        _buildMenuItem(
                          icon: Icons.logout,
                          title: 'Logout',
                          color: Colors.red,
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
                ),
              ],
            );
          },
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
