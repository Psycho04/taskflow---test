import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_constants.dart';

class TokenManager {
  // Get token from SharedPreferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.tokenKey);
  }
  
  // Save token to SharedPreferences
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConstants.tokenKey, token);
  }
  
  // Remove token from SharedPreferences
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.tokenKey);
  }
  
  // Decode token to get user information
  static Map<String, dynamic>? decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }
      
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      return payload;
    } catch (e) {
      print('Error decoding token: $e');
      return null;
    }
  }
  
  // Get user ID from token
  static String? getUserIdFromToken(String token) {
    final payload = decodeToken(token);
    return payload?['userId']?.toString();
  }
  
  // Check if user is admin
  static bool isUserAdmin(String token) {
    final payload = decodeToken(token);
    return payload?['role']?.toString().toLowerCase() == 'admin';
  }
}
