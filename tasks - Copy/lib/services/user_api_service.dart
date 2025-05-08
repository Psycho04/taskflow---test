import '../services/api_base.dart';
import '../services/api_constants.dart';

class UserApiService {
  // Fetch all users including admins
  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    final response = await ApiBase.get<Map<String, dynamic>>(
      ApiConstants.usersEndpoint,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      if (data['users'] != null && data['users'] is List) {
        return (data['users'] as List)
            .map((user) => {
                  'id': user['_id']?.toString() ?? '',
                  'name': user['name']?.toString() ?? '',
                  'email': user['email']?.toString() ?? '',
                  'role': user['role']?.toString() ?? 'user',
                  'image': user['image']?.toString(),
                  'jobTitle': user['jobTitle']?.toString() ?? '',
                })
            .toList();
      }
    }

    if (response.error != null) {
      throw Exception(response.error);
    }

    return [];
  }

  // Fetch normal users (non-admin)
  Future<List<Map<String, dynamic>>> fetchNormalUsers() async {
    final response = await ApiBase.get<Map<String, dynamic>>(
      ApiConstants.normalUsersEndpoint,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      if (data['users'] != null && data['users'] is List) {
        return (data['users'] as List)
            .map((user) => {
                  'id': user['_id']?.toString() ?? '',
                  'name': user['name']?.toString() ?? '',
                  'email': user['email']?.toString() ?? '',
                  'role': user['role']?.toString() ?? 'user',
                  'image': user['image']?.toString(),
                  'jobTitle': user['jobTitle']?.toString() ?? '',
                })
            .toList();
      }
    }

    if (response.error != null) {
      throw Exception(response.error);
    }

    return [];
  }

  // Get user details
  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    final response = await ApiBase.get<Map<String, dynamic>>(
      '${ApiConstants.usersEndpoint}/$userId',
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      if (data['user'] != null) {
        return data['user'] as Map<String, dynamic>;
      } else {
        return data;
      }
    }

    throw Exception(response.error ?? 'Failed to load user details');
  }

  // Process user data to ensure it has all required fields
  Map<String, dynamic> processUserData(Map<String, dynamic> user) {
    // Get the full name from the user data
    String fullName = user['fullName']?.toString() ?? '';

    // If fullName is empty, try to get it from name field
    if (fullName.isEmpty) {
      fullName = user['name']?.toString() ?? '';
    }

    // If still empty, generate from email
    if (fullName.isEmpty) {
      final email = user['email']?.toString() ?? '';
      if (email.isNotEmpty) {
        // Extract username part before @
        final username = email.split('@')[0];
        // Split by common separators and capitalize each part
        fullName = username
            .split(RegExp(r'[._-]'))
            .where((part) => part.isNotEmpty)
            .map((part) =>
                part[0].toUpperCase() + part.substring(1).toLowerCase())
            .join(' ');
      }
    }

    // If still empty, use a default name
    if (fullName.isEmpty) {
      fullName = 'User ${user['_id']?.toString().substring(0, 4) ?? ''}';
    }

    return {
      '_id': user['_id']?.toString() ?? '',
      'fullName': fullName,
      'name': fullName,
      'email': user['email']?.toString() ?? '',
      'role': user['role']?.toString() ?? 'user',
      'jobTitle': user['jobTitle']?.toString() ?? 'Employee'
    };
  }
}
