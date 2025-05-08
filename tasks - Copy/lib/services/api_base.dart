import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_constants.dart';
import '../services/token_manager.dart';

class ApiResponse<T> {
  final T? data;
  final String? error;
  final int statusCode;
  
  ApiResponse({this.data, this.error, required this.statusCode});
  
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class ApiBase {
  // Common headers for API requests
  static Future<Map<String, String>> getHeaders() async {
    final token = await TokenManager.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'token': token,
    };
  }
  
  // GET request
  static Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final headers = await getHeaders();
      
      var uri = Uri.parse('${ApiConstants.apiBaseUrl}$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      
      print('GET request to: $uri');
      
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
            'Connection timed out. Please check your server status.');
        },
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      final jsonData = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (fromJson != null) {
          final data = fromJson(jsonData);
          return ApiResponse(data: data, statusCode: response.statusCode);
        }
        return ApiResponse(data: jsonData as T, statusCode: response.statusCode);
      } else {
        final error = jsonData['message'] ?? jsonData['error'] ?? 'Unknown error';
        return ApiResponse(error: error, statusCode: response.statusCode);
      }
    } catch (e) {
      print('Error in GET request: $e');
      return ApiResponse(error: e.toString(), statusCode: 500);
    }
  }
  
  // POST request
  static Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final headers = await getHeaders();
      final uri = Uri.parse('${ApiConstants.apiBaseUrl}$endpoint');
      
      print('POST request to: $uri');
      if (body != null) {
        print('Request body: ${json.encode(body)}');
      }
      
      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      ).timeout(
        ApiConstants.timeout,
        onTimeout: () {
          throw TimeoutException(
            'Connection timed out. Please check your server status.');
        },
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      final jsonData = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (fromJson != null) {
          final data = fromJson(jsonData);
          return ApiResponse(data: data, statusCode: response.statusCode);
        }
        return ApiResponse(data: jsonData as T, statusCode: response.statusCode);
      } else {
        final error = jsonData['message'] ?? jsonData['error'] ?? 'Unknown error';
        return ApiResponse(error: error, statusCode: response.statusCode);
      }
    } catch (e) {
      print('Error in POST request: $e');
      return ApiResponse(error: e.toString(), statusCode: 500);
    }
  }
  
  // PUT request
  static Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final headers = await getHeaders();
      final uri = Uri.parse('${ApiConstants.apiBaseUrl}$endpoint');
      
      print('PUT request to: $uri');
      if (body != null) {
        print('Request body: ${json.encode(body)}');
      }
      
      final response = await http.put(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
            'Connection timed out. Please check your server status.');
        },
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      final jsonData = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (fromJson != null) {
          final data = fromJson(jsonData);
          return ApiResponse(data: data, statusCode: response.statusCode);
        }
        return ApiResponse(data: jsonData as T, statusCode: response.statusCode);
      } else {
        final error = jsonData['message'] ?? jsonData['error'] ?? 'Unknown error';
        return ApiResponse(error: error, statusCode: response.statusCode);
      }
    } catch (e) {
      print('Error in PUT request: $e');
      return ApiResponse(error: e.toString(), statusCode: 500);
    }
  }
  
  // DELETE request
  static Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final headers = await getHeaders();
      final uri = Uri.parse('${ApiConstants.apiBaseUrl}$endpoint');
      
      print('DELETE request to: $uri');
      
      final request = http.Request('DELETE', uri);
      request.headers.addAll(headers);
      if (body != null) {
        request.body = json.encode(body);
      }
      
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
            'Connection timed out. Please check your server status.');
        },
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      final jsonData = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (fromJson != null) {
          final data = fromJson(jsonData);
          return ApiResponse(data: data, statusCode: response.statusCode);
        }
        return ApiResponse(data: jsonData as T, statusCode: response.statusCode);
      } else {
        final error = jsonData['message'] ?? jsonData['error'] ?? 'Unknown error';
        return ApiResponse(error: error, statusCode: response.statusCode);
      }
    } catch (e) {
      print('Error in DELETE request: $e');
      return ApiResponse(error: e.toString(), statusCode: 500);
    }
  }
  
  // PATCH request
  static Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final headers = await getHeaders();
      final uri = Uri.parse('${ApiConstants.apiBaseUrl}$endpoint');
      
      print('PATCH request to: $uri');
      if (body != null) {
        print('Request body: ${json.encode(body)}');
      }
      
      final response = await http.patch(
        uri,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
            'Connection timed out. Please check your server status.');
        },
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      final jsonData = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (fromJson != null) {
          final data = fromJson(jsonData);
          return ApiResponse(data: data, statusCode: response.statusCode);
        }
        return ApiResponse(data: jsonData as T, statusCode: response.statusCode);
      } else {
        final error = jsonData['message'] ?? jsonData['error'] ?? 'Unknown error';
        return ApiResponse(error: error, statusCode: response.statusCode);
      }
    } catch (e) {
      print('Error in PATCH request: $e');
      return ApiResponse(error: e.toString(), statusCode: 500);
    }
  }
}
