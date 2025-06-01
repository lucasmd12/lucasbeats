import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:federacaomad/utils/constants.dart'; // Assuming constants.dart holds backendBaseUrl
import 'package:federacaomad/utils/logger.dart'; // Assuming logger.dart exists

class ApiService {
  final String _baseUrl = backendBaseUrl; // Use http for local dev, https for production
  final _secureStorage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _secureStorage.read(key: 'jwt_token');
  }

  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (includeAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // Helper to handle responses and errors
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    Log.info('API Response Status: $statusCode, Body: ${response.body}');

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isNotEmpty) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          Log.error('Error decoding JSON response: ${e.toString()}');
          throw Exception('Failed to decode JSON response');
        }
      } else {
        return null; // No content, but successful
      }
    } else if (statusCode == 401 || statusCode == 403) {
      // Handle unauthorized or forbidden access, maybe trigger logout
      Log.warning('API Authorization Error: $statusCode');
      throw Exception('Authorization Error: $statusCode');
    } else {
      String errorMessage = 'API Error: $statusCode';
      try {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody is Map && decodedBody.containsKey('msg')) {
          errorMessage = decodedBody['msg'];
        } else if (decodedBody is Map && decodedBody.containsKey('errors')) {
          // Handle validation errors from express-validator
          final errors = decodedBody['errors'] as List;
          errorMessage = errors.map((e) => e['msg']).join(', ');
        }
      } catch (_) {
        // Ignore if body is not JSON or doesn't contain expected error format
        errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
      }
      Log.error('API Error: $statusCode - $errorMessage');
      throw Exception(errorMessage);
    }
  }

  // --- HTTP Methods ---

  Future<dynamic> get(String endpoint, {bool requireAuth = true}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    Log.info('API GET Request: $url');
    try {
      final response = await http.get(
        url,
        headers: await _getHeaders(includeAuth: requireAuth),
      );
      return _handleResponse(response);
    } catch (e) {
      Log.error('API GET Error ($endpoint): ${e.toString()}');
      rethrow; // Rethrow the exception to be caught by the caller
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data, {bool requireAuth = true}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    Log.info('API POST Request: $url, Data: ${jsonEncode(data)}');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(includeAuth: requireAuth),
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      Log.error('API POST Error ($endpoint): ${e.toString()}');
      rethrow;
    }
  }

  // Add PUT, DELETE methods similarly if needed
  Future<dynamic> put(String endpoint, Map<String, dynamic> data, {bool requireAuth = true}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    Log.info('API PUT Request: $url, Data: ${jsonEncode(data)}');
    try {
      final response = await http.put(
        url,
        headers: await _getHeaders(includeAuth: requireAuth),
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      Log.error('API PUT Error ($endpoint): ${e.toString()}');
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint, {bool requireAuth = true}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    Log.info('API DELETE Request: $url');
    try {
      final response = await http.delete(
        url,
        headers: await _getHeaders(includeAuth: requireAuth),
      );
      return _handleResponse(response);
    } catch (e) {
      Log.error('API DELETE Error ($endpoint): ${e.toString()}');
      rethrow;
    }
  }
}

