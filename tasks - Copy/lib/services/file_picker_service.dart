import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FilePickerService {
  // Base URL for API calls
  final String baseUrl = 'http://10.0.2.2:5000/api';

  // Get token from SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Create a simple colored circle as a profile image
  Future<Map<String, dynamic>> updateProfilePhotoWithSample(
      BuildContext context) async {
    try {
      // Create a simple image programmatically
      final File imageFile = await _createSampleProfileImage();

      // Check if file was created successfully
      if (!await imageFile.exists()) {
        throw Exception('Failed to create sample profile image');
      }

      return await _uploadProfilePhoto(imageFile);
    } catch (e) {
      throw Exception('Profile photo update error: $e');
    }
  }

  // Create a simple profile image programmatically
  Future<File> _createSampleProfileImage() async {
    try {
      // Get temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/temp_profile.png';

      // Create a simple image with a colored circle
      final File file = File(tempPath);

      // Create a simple byte array for a small PNG image (1x1 pixel, blue)
      // This is a very basic approach - in a real app, you'd generate a proper image
      final List<int> bytes = [
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
        0,
        0,
        0,
        13,
        73,
        72,
        68,
        82,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        1,
        8,
        2,
        0,
        0,
        0,
        144,
        119,
        83,
        222,
        0,
        0,
        0,
        12,
        73,
        68,
        65,
        84,
        8,
        215,
        99,
        248,
        207,
        240,
        31,
        0,
        5,
        0,
        1,
        226,
        52,
        148,
        121,
        0,
        0,
        0,
        0,
        73,
        69,
        78,
        68,
        174,
        66,
        96,
        130
      ];

      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      throw Exception('Error creating sample profile image: $e');
    }
  }

  // Upload the profile photo
  Future<Map<String, dynamic>> _uploadProfilePhoto(File imageFile) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Create a multipart request
      var uri = Uri.parse('$baseUrl/auth/profilePhoto');
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

      if (response.statusCode == 200) {
        final jsonResponse = Map<String, dynamic>.from(
            Map<String, dynamic>.from({
          'success': true,
          'message': 'Profile photo updated successfully'
        }));

        return jsonResponse;
      } else {
        throw Exception('Failed to update profile photo: $responseData');
      }
    } catch (e) {
      throw Exception('Profile photo upload error: $e');
    }
  }
}
