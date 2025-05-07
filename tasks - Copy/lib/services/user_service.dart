import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  // Base URL for API calls
  final String baseUrl = 'http://10.0.2.2:5000/api';

  // Get token from SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Print token for debugging
  Future<void> _debugToken() async {
    final token = await _getToken();
    print('DEBUG - Token: $token');
  }

  // Update user profile photo using a simpler approach
  Future<Map<String, dynamic>> updateProfilePhoto(File imageFile) async {
    try {
      // Debug the image file
      print('Image file path: ${imageFile.path}');
      print('Image file exists: ${await imageFile.exists()}');

      final token = await _getToken();
      print('Token for upload: $token');

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Create a simple form data approach
      var uri = Uri.parse('$baseUrl/auth/profilePhoto');

      // Create a multipart request
      var request = http.MultipartRequest('PUT', uri);

      // Add the file
      var multipartFile =
          await http.MultipartFile.fromPath('image', imageFile.path);
      request.files.add(multipartFile);

      // Add the token header
      request.headers['token'] = token;

      // Send the request
      var response = await request.send();

      // Get the response
      var responseData = await response.stream.bytesToString();
      print('Response status: ${response.statusCode}');
      print('Response data: $responseData');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseData);

        // Update user data in SharedPreferences
        if (jsonResponse['user'] != null) {
          await _updateUserData(jsonResponse['user']);
        }

        return jsonResponse;
      } else {
        throw Exception('Failed to update profile photo: $responseData');
      }
    } catch (e) {
      print('Profile photo update error: $e');
      throw Exception('Profile photo update error: $e');
    }
  }

  // Update user data in SharedPreferences
  Future<void> _updateUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingUserDataString = prefs.getString('userData');

      if (existingUserDataString != null) {
        final existingUserData = jsonDecode(existingUserDataString);
        // Merge the existing data with the new data
        final updatedUserData = {...existingUserData, ...userData};
        await prefs.setString('userData', jsonEncode(updatedUserData));
      }
    } catch (e) {
      print('Error updating user data in SharedPreferences: $e');
    }
  }
}
