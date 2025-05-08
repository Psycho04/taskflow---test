import 'package:flutter/foundation.dart';
import '../services/user_api_service.dart';

class UserRepository {
  final UserApiService _userApiService;
  List<Map<String, dynamic>> _normalUsers = [];
  
  UserRepository({UserApiService? userApiService})
      : _userApiService = userApiService ?? UserApiService();
  
  List<Map<String, dynamic>> get normalUsers => _normalUsers;
  
  // Fetch all users including admins
  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    try {
      final users = await _userApiService.fetchAllUsers();
      return users.map((user) => _userApiService.processUserData(user)).toList();
    } catch (e) {
      debugPrint('Error fetching all users: $e');
      return [];
    }
  }
  
  // Fetch normal users (non-admin)
  Future<List<Map<String, dynamic>>> fetchNormalUsers() async {
    try {
      final users = await _userApiService.fetchNormalUsers();
      
      // Process and store the users
      _normalUsers = users.map((user) {
        final processedUser = _userApiService.processUserData(user);
        return {
          'id': processedUser['_id'],
          'name': processedUser['fullName'],
          'email': processedUser['email'],
          'role': processedUser['role'],
        };
      }).toList();
      
      return users.map((user) => _userApiService.processUserData(user)).toList();
    } catch (e) {
      debugPrint('Error fetching normal users: $e');
      return [];
    }
  }
  
  // Get user details
  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    try {
      final userDetails = await _userApiService.getUserDetails(userId);
      return _userApiService.processUserData(userDetails);
    } catch (e) {
      debugPrint('Error getting user details: $e');
      return {
        '_id': userId,
        'fullName': 'Unknown User',
        'name': 'Unknown User',
        'email': '',
        'role': 'user',
        'jobTitle': 'Employee'
      };
    }
  }
}
