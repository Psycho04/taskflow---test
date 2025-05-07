import 'package:flutter/material.dart';

class TeamMemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final VoidCallback onAvatarTap;
  final VoidCallback? onDelete;
  final bool isAdmin;

  const TeamMemberCard({
    super.key,
    required this.member,
    required this.onAvatarTap,
    this.onDelete,
    this.isAdmin = false,
  });

  String _getInitials(String fullName) {
    final names = fullName.split(' ');
    return names.length >= 2 ? '${names[0][0]}${names[1][0]}' : names[0][0];
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(member['fullName']);

    return Dismissible(
      key: Key(member['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEEEE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete  ',
              style: TextStyle(
                color: Colors.red.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(
              Icons.delete_outline_rounded,
              color: Colors.red.shade400,
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (!isAdmin) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Only administrators can delete team members'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Delete Member',
                style: TextStyle(
                  color: Color(0xFF1A1C1E),
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Text(
                'Are you sure you want to remove ${member['fullName']}?',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) => onDelete?.call(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: Hero(
                  tag: 'avatar-${member['fullName']}',
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        initials.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF4B6BFF),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['fullName'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1C1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member['email'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    if (member['jobTitle'] != null &&
                        member['jobTitle'].toString().isNotEmpty &&
                        member['jobTitle'] != 'Not specified') ...[
                      const SizedBox(height: 4),
                      Text(
                        member['jobTitle'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: member['role'].toString().toUpperCase() == 'ADMIN'
                      ? const Color(0xFFEEF2FF)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  member['role'].toString().toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: member['role'].toString().toUpperCase() == 'ADMIN'
                        ? const Color(0xFF4B6BFF)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
