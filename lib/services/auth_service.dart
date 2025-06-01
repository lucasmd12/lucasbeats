import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:federacaomad/services/api_service.dart';
import 'package:federacaomad/utils/logger.dart';
import 'package:federacaomad/models/user_model.dart'; // Assuming UserModel exists and matches backend response

class AuthService with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final _secureStorage = const FlutterSecureStorage();

  User? _currentUser;
  User? get currentUser => _currentUser;

  String? _token;
  String? get token => _token;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  AuthService() {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    Log.info('Attempting auto-login...');
    final storedToken = await _secureStorage.read(key: 'jwt_token');
    if (storedToken != null) {
      Log.info('Found stored token.');
      _token = storedToken;
      try {
        // Optionally verify token validity by fetching profile
        await fetchUserProfile(); // This will set _currentUser and _isAuthenticated if successful
        Log.info('Auto-login successful.');
      } catch (e) {
        Log.warning('Auto-login failed: Token validation error or expired. ${e.toString()}');
        await logout(); // Clear invalid token
      }
    } else {
      Log.info('No stored token found.');
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiService.post(
        '/api/auth/login',
        {'username': username, 'password': password},
        requireAuth: false, // Login doesn't require prior auth
      );

      if (response != null && response['token'] != null) {
        _token = response['token'];
        await _secureStorage.write(key: 'jwt_token', value: _token);
        // Assuming the response also contains user details
        _currentUser = User.fromJson(response); // Adapt User.fromJson if needed
        _isAuthenticated = true;
        Log.info('Login successful for user: ${currentUser?.username}');
        notifyListeners();
        return true;
      } else {
        Log.error('Login failed: Invalid response format or missing token.');
        _handleAuthError();
        return false;
      }
    } catch (e) {
      Log.error('Login error: ${e.toString()}');
      _handleAuthError();
      // Rethrow or handle specific error messages for UI
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<bool> register(String username, String password) async {
    try {
      final response = await _apiService.post(
        '/api/auth/register',
        {'username': username, 'password': password},
        requireAuth: false, // Registration doesn't require prior auth
      );

      if (response != null && response['token'] != null) {
        _token = response['token'];
        await _secureStorage.write(key: 'jwt_token', value: _token);
        _currentUser = User.fromJson(response);
        _isAuthenticated = true;
        Log.info('Registration successful for user: ${currentUser?.username}');
        notifyListeners();
        return true;
      } else {
        Log.error('Registration failed: Invalid response format or missing token.');
         _handleAuthError();
        return false;
      }
    } catch (e) {
      Log.error('Registration error: ${e.toString()}');
       _handleAuthError();
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<void> fetchUserProfile() async {
    if (_token == null) {
      // Attempt to read from storage if token is null in memory
      _token = await _secureStorage.read(key: 'jwt_token');
      if (_token == null) {
         Log.warning('Cannot fetch profile: No token available.');
         _handleAuthError();
         throw Exception('Not authenticated');
      }
    }

    try {
      final response = await _apiService.get('/api/auth/profile', requireAuth: true);
      if (response != null) {
        _currentUser = User.fromJson(response);
        _isAuthenticated = true;
        Log.info('User profile fetched: ${currentUser?.username}');
        notifyListeners();
      } else {
         Log.warning('Fetch profile failed: No user data received.');
         _handleAuthError(); // Consider if this should trigger logout
         throw Exception('Failed to fetch profile data');
      }
    } catch (e) {
      Log.error('Fetch profile error: ${e.toString()}');
      _handleAuthError(); // Token might be invalid/expired
      rethrow;
    }
  }

  Future<void> logout() async {
    Log.info('Logging out user...');
    _token = null;
    _currentUser = null;
    _isAuthenticated = false;
    await _secureStorage.delete(key: 'jwt_token');
    // Optionally notify backend or perform other cleanup
    notifyListeners();
  }

  void _handleAuthError() {
     // Central place to handle auth errors, potentially trigger logout
     if (_isAuthenticated) {
        Log.warning('Authentication error occurred, logging out.');
        logout();
     } else {
        // If already logged out, just ensure state is clean
        _token = null;
        _currentUser = null;
        _isAuthenticated = false;
        _secureStorage.delete(key: 'jwt_token');
        notifyListeners();
     }
  }
}

