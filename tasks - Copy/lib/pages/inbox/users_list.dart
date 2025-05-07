import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasks/providers/task_provider.dart';
import 'package:tasks/providers/inbox_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'chat_screen.dart';

class UsersListPage extends StatefulWidget {
  static const String routeName = 'UsersList';

  const UsersListPage({Key? key}) : super(key: key);

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _filteredUsers = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserData();
        _fetchUsers();
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
            _currentUserId = userData['_id'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get providers before async operations
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final inboxProvider = Provider.of<InboxProvider>(context, listen: false);

      // Use fetchAllUsers to get both normal users and admins
      final users = await taskProvider.fetchAllUsers();

      // Also fetch senders to check for unread messages
      if (mounted) {
        await inboxProvider.fetchSenders();
      }

      if (mounted) {
        setState(() {
          // Filter out the current user from the list
          _filteredUsers =
              users.where((user) => user['id'] != _currentUserId).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching users: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Message'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // User list or loading/empty state
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'There are no other users in the system',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredUsers.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          indent: 72,
                          endIndent: 16,
                          thickness: 0.5,
                        ),
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          // Get name from either 'name' or 'fullName' field
                          final String name =
                              user['name'] ?? user['fullName'] ?? 'Unknown';
                          final String email = user['email'] ?? '';
                          final String role = user['role'] ?? 'user';
                          // For admin users, show "Admin" as job title, otherwise use the actual job title
                          final String jobTitle = role.toLowerCase() == 'admin'
                              ? 'Admin'
                              : user['jobTitle'] ?? 'Employee';

                          // Generate a consistent color based on the user's name
                          Color avatarColor;

                          // Special case for Zain Omar to ensure consistent color
                          if (name.toLowerCase().contains("zain")) {
                            avatarColor =
                                Colors.orange.shade300; // Fixed color for Zain
                          } else {
                            final int nameHash = name.hashCode;
                            final List<Color> avatarColors = [
                              Colors.blue.shade300,
                              Colors.green.shade300,
                              Colors.purple.shade300,
                              Colors.orange.shade300,
                              Colors.teal.shade300,
                              Colors.pink.shade300,
                            ];
                            avatarColor = avatarColors[
                                nameHash.abs() % avatarColors.length];
                          }

                          // Add a staggered animation effect
                          return AnimatedUserListItem(
                            index: index,
                            user: user,
                            name: name,
                            email: email,
                            jobTitle: jobTitle,
                            avatarColor: avatarColor,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    userId: user['id'],
                                    userName: name,
                                    userImage: user['image'],
                                    userJobTitle: jobTitle,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class AnimatedUserListItem extends StatefulWidget {
  final int index;
  final Map<String, dynamic> user;
  final String name;
  final String email;
  final String jobTitle;
  final Color avatarColor;
  final VoidCallback onTap;

  const AnimatedUserListItem({
    Key? key,
    required this.index,
    required this.user,
    required this.name,
    required this.email,
    required this.jobTitle,
    required this.avatarColor,
    required this.onTap,
  }) : super(key: key);

  @override
  State<AnimatedUserListItem> createState() => _AnimatedUserListItemState();
}

class _AnimatedUserListItemState extends State<AnimatedUserListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Stagger the animations based on index
    final delay = Duration(milliseconds: widget.index * 50);
    Future.delayed(delay, () {
      if (mounted) {
        _controller.forward();
      }
    });

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: widget.avatarColor,
            // Force all users to show initials
            child: Builder(
              builder: (context) {
                // Generate initials from name
                String initials = '?';

                // Special case for Zain Omar
                if (widget.name.toLowerCase().contains("zain")) {
                  initials = "ZO";
                } else if (widget.name.isNotEmpty) {
                  final nameParts = widget.name.split(' ');
                  if (nameParts.length > 1) {
                    // First letter of first name + first letter of last name
                    initials =
                        '${nameParts[0][0]}${nameParts.last[0]}'.toUpperCase();
                  } else if (nameParts[0].length > 1) {
                    // For single names, use first two letters
                    initials = nameParts[0].substring(0, 2).toUpperCase();
                  } else {
                    // Just first letter of name if it's only one character
                    initials = nameParts[0][0].toUpperCase();
                  }
                }

                return Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                );
              },
            ),
          ),
          title: Consumer<InboxProvider>(
            builder: (context, inboxProvider, child) {
              // Check if this user has sent unread messages
              final hasSentMessages = inboxProvider.senders.any((sender) =>
                  sender['_id'] == widget.user['id'] &&
                  sender['lastMessage'] != null &&
                  sender['lastMessage']['isRead'] == false);

              return Row(
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Show a message icon to indicate this user sent you a message
                  if (hasSentMessages)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.mail,
                            size: 14,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'New',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          subtitle: Text(
            widget.jobTitle,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
          trailing: Consumer<InboxProvider>(
            builder: (context, inboxProvider, child) {
              // Check if this user has sent unread messages
              final hasSentMessages = inboxProvider.senders.any((sender) =>
                  sender['_id'] == widget.user['id'] &&
                  sender['lastMessage'] != null &&
                  sender['lastMessage']['isRead'] == false);

              return Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  if (hasSentMessages)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          onTap: widget.onTap,
        ),
      ),
    );
  }
}
