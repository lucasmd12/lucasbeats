import 'package:flutter/material.dart';
import 'package:federacaomad/services/auth_service.dart';
import 'package:federacaomad/services/socket_service.dart';
import 'package:federacaomad/models/user_model.dart';
import 'package:federacaomad/utils/logger.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final SocketService _socketService;

  AuthStatus _authStatus = AuthStatus.unknown;
  AuthStatus get authStatus => _authStatus;

  User? get currentUser => _authService.currentUser;

  AuthProvider(this._authService, this._socketService) {
    Log.info('AuthProvider initialized. Listening to AuthService changes.');
    // Listen to changes in AuthService to update AuthStatus and manage Socket connection
    _authService.addListener(_authListener);
    // Initialize status based on AuthService's initial state (after auto-login attempt)
    _updateAuthStatus();
  }

  void _authListener() {
    Log.info('AuthProvider received notification from AuthService.');
    _updateAuthStatus();
  }

  void _updateAuthStatus() {
    if (_authService.isAuthenticated) {
      if (_authStatus != AuthStatus.authenticated) {
        Log.info('AuthProvider: Status changed to Authenticated.');
        _authStatus = AuthStatus.authenticated;
        // Connect SocketService when authenticated
        Log.info('AuthProvider: Connecting SocketService...');
        _socketService.connect();
        notifyListeners();
      }
    } else {
      if (_authStatus != AuthStatus.unauthenticated) {
        Log.info('AuthProvider: Status changed to Unauthenticated.');
        _authStatus = AuthStatus.unauthenticated;
        // Disconnect SocketService when unauthenticated
        Log.info('AuthProvider: Disconnecting SocketService...');
        _socketService.disconnect();
        notifyListeners();
      }
    }
    // Handle the initial unknown state - it transitions once AuthService resolves auto-login
    if (_authStatus == AuthStatus.unknown && !_authService.isAuthenticated) {
       Log.info('AuthProvider: Initial status resolved to Unauthenticated.');
      _authStatus = AuthStatus.unauthenticated;
      notifyListeners();
    }
     // If authService is still processing auto-login, status remains unknown initially.
  }

  // Expose login/register/logout methods that call AuthService and handle state
  Future<bool> login(String email, String password) async {
    try {
      final success = await _authService.login(email, password);
      // Status update will be handled by the listener
      return success;
    } catch (e) {
      Log.error('AuthProvider login failed: ${e.toString()}');
      // Status update (to unauthenticated) should also be handled by listener via AuthService error handling
      rethrow; // Let the UI handle the error display
    }
  }

  Future<bool> register(String username, String email, String password) async {
    try {
      final success = await _authService.register(username, email, password);
      // Status update handled by listener
      return success;
    } catch (e) {
      Log.error('AuthProvider register failed: ${e.toString()}');
      // Status update handled by listener
      rethrow;
    }
  }

  Future<void> logout() async {
    Log.info('AuthProvider: Initiating logout.');
    await _authService.logout();
    // Status update handled by listener
    // Socket disconnection is also handled by the listener reacting to logout
  }

  @override
  void dispose() {
    Log.info('Disposing AuthProvider.');
    _authService.removeListener(_authListener);
    super.dispose();
  }
}

