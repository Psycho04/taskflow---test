import 'package:flutter/material.dart';
import 'package:tasks/services/profile_service.dart';

class ProfileDialog extends StatefulWidget {
  final String name;
  final String email;
  final String role;
  final String jobTitle;
  final String formattedDate;
  final String? imageUrl;
  final Function? onProfileUpdated;

  const ProfileDialog({
    super.key,
    required this.name,
    required this.email,
    required this.role,
    required this.jobTitle,
    required this.formattedDate,
    this.imageUrl,
    this.onProfileUpdated,
  });

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  final ProfileService _profileService = ProfileService();
  bool _isUploading = false;
  String? _errorMessage;

  Future<void> _pickAndUploadImage() async {
    try {
      setState(() {
        _isUploading = true;
        _errorMessage = null;
      });

      // Skip image picking and directly use default image
      if (mounted) {
        try {
          // Use the ProfileService with default image
          final result = await _profileService.updateProfileWithDefaultImage();

          // Update user data in SharedPreferences
          await _profileService.updateUserData(result['user']);

          _handleSuccess();
        } catch (innerError) {
          if (mounted) {
            setState(() {
              _isUploading = false;
              _errorMessage = 'Error updating profile: $innerError';
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = 'Failed to update profile photo: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    }
  }

  void _handleSuccess() {
    if (mounted) {
      setState(() {
        _isUploading = false;
      });

      // Close the dialog and notify parent about the update
      Navigator.of(context).pop();
      if (widget.onProfileUpdated != null) {
        widget.onProfileUpdated!();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Center(
        child: Text(
          'Profile',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            // Profile Avatar
            Center(
              child: Stack(
                children: [
                  widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                      ? CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(
                            'http://10.0.2.2:5000/uploads/${widget.imageUrl}',
                          ),
                          backgroundColor: Colors.blue.shade100,
                        )
                      : CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.blue,
                          ),
                        ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _isUploading ? null : _pickAndUploadImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: _isUploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.photo_camera,
                                size: 16,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // User Name
            Center(
              child: Text(
                widget.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(
              child: Text(
                widget.email,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // User Details Card
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withAlpha(13), // Equivalent to opacity 0.05
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Role Info
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue
                            .withAlpha(26), // Equivalent to opacity 0.1
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.work, color: Colors.blue),
                    ),
                    title: const Text(
                      'Role',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    subtitle: Text(
                      widget.role,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Job Title
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange
                            .withAlpha(26), // Equivalent to opacity 0.1
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.business_center,
                          color: Colors.orange),
                    ),
                    title: const Text(
                      'Job Title',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    subtitle: Text(
                      widget.jobTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Member Since
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green
                            .withAlpha(26), // Equivalent to opacity 0.1
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.calendar_today, color: Colors.green),
                    ),
                    title: const Text(
                      'Member Since',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    subtitle: Text(
                      widget.formattedDate,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _isUploading ? null : _pickAndUploadImage,
          child: _isUploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Edit Profile'),
        ),
      ],
      // Error message will be shown in the content
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      actionsPadding: const EdgeInsets.all(16),
      // Show error message if there is one
      insetPadding: _errorMessage != null
          ? const EdgeInsets.only(bottom: 40)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
    );
  }
}
