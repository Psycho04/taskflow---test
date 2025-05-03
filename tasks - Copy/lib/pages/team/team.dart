import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/widgets.dart';

class Team extends StatefulWidget {
  const Team({super.key});

  @override
  State<Team> createState() => _TeamState();
}

class _TeamState extends State<Team> {
  List<Map<String, dynamic>> _teamMembers = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDisposed = false;
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserRole();
    _fetchTeamMembers();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadCurrentUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');
      
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        if (!_isDisposed) {
          setState(() {
            _currentUserRole = (userData['role'] ?? 'user').toString().toLowerCase();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user role: $e');
    }
  }

  Future<void> _fetchTeamMembers() async {
    if (_isDisposed) return;
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/user'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'token': token,
        },
      );

      if (_isDisposed) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['users'] != null) {
          final users = data['users'] as List;
          
          if (!_isDisposed) {
            setState(() {
              _teamMembers = users.map((user) => {
                'id': user['_id']?.toString() ?? '',
                'fullName': user['name']?.toString() ?? '',
                'email': user['email']?.toString() ?? '',
                'role': user['role']?.toString().toUpperCase() ?? 'USER',
                'createdAt': user['createdAt']?.toString() ?? '',
              }).toList();
              _isLoading = false;
            });
          }
        } else {
          throw Exception('Invalid response format: missing users array');
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch team members');
      }
    } catch (e) {
      if (!_isDisposed) {
        setState(() {
          _errorMessage = 'Failed to load team members: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteMember(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.delete(
        Uri.parse('http://10.0.2.2:5000/api/user/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'token': token,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete user');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting member: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
      _fetchTeamMembers();
    }
  }

  Widget _buildErrorView() {
    return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _fetchTeamMembers,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF4B6BFF),
            ),
            label: const Text(
              'Try Again',
                      style: TextStyle(
                color: Color(0xFF4B6BFF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4B6BFF),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (_teamMembers.isEmpty) {
      return const Center(
                child: Text(
          'No team members found',
                  style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 15,
        ),
      ),
    );
  }

    return ListView.builder(
      itemCount: _teamMembers.length,
      itemBuilder: (context, index) {
        final member = _teamMembers[index];
        final names = member['fullName'].split(' ');
        final initials = names.length >= 2
            ? '${names[0][0]}${names[1][0]}'
            : names[0][0];

        return TeamMemberCard(
          member: member,
          onAvatarTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                opaque: false,
                pageBuilder: (context, animation, secondaryAnimation) {
                  return FadeTransition(
                    opacity: animation,
                    child: AvatarPreview(
                      initials: initials,
                      name: member['fullName'],
                    ),
                  );
                },
              ),
            );
          },
          isAdmin: _currentUserRole == 'admin',
          onDelete: _currentUserRole == 'admin' ? () {
            showDialog(
              context: context,
              builder: (context) => DeleteMemberDialog(
                member: member,
                onConfirm: () async {
                  await _deleteMember(member['id']);
                  if (!_isDisposed) {
                      setState(() {
                      _teamMembers.removeAt(index);
                    });
                  }
                },
              ),
            );
          } : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FF),
      child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            TeamHeader(memberCount: _teamMembers.length),
          const SizedBox(height: 24),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }
}
