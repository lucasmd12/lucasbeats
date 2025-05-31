import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  bool _isUserDataLoaded = false; // Flag to track if data has been loaded

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isUserDataLoaded => _isUserDataLoaded;

  UserProvider() {
    // Listen to auth state changes to automatically load/clear user data
    FirebaseAuth.instance.authStateChanges().listen((User? firebaseUser) {
      if (firebaseUser == null) {
        Logger.info('Auth state changed: User logged out. Clearing user data.');
        clearUser();
      } else {
        Logger.info('Auth state changed: User logged in (${firebaseUser.uid}). Loading user data.');
        loadUserData(firebaseUser.uid);
      }
    });
  }

  Future<void> loadUserData(String uid) async {
    if (_isLoading) return; // Prevent concurrent loads

    setLoading(true);
    _isUserDataLoaded = false; // Reset flag before loading
    try {
      Logger.info('Fetching Firestore user document for UID: $uid');
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        _user = UserModel.fromFirestore(userDoc); // Corrected: Use fromFirestore factory
        Logger.info('User data loaded successfully for: ${_user?.displayName} (${_user?.uid})');
        _isUserDataLoaded = true; // Set flag after successful load
      } else {
        Logger.warning('Firestore user document not found for UID: $uid. User might need to complete profile or document creation failed.');
        // Handle case where user exists in Auth but not Firestore (e.g., prompt profile setup)
        _user = null; // Ensure user is null if Firestore data is missing
      }
    } catch (e, stackTrace) {
      Logger.error('Failed to load user data from Firestore', error: e, stackTrace: stackTrace);
      _user = null; // Clear user data on error
    } finally {
      setLoading(false);
      notifyListeners(); // Notify listeners after loading attempt (success or fail)
    }
  }

  void setUser(UserModel user) {
    _user = user;
    _isUserDataLoaded = true; // Assume data is loaded if set manually
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    _isLoading = false;
    _isUserDataLoaded = false; // Reset flag on clear
    notifyListeners();
  }

  void setLoading(bool loading) {
    if (_isLoading != loading) { // Avoid unnecessary notifications
      _isLoading = loading;
      notifyListeners();
    }
  }

  // Use Firebase Auth state for login status
  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null && _isUserDataLoaded;

  // Roles based on loaded user data
  bool get isAdmin => _user != null && (_user!.role == 'admin' || _user!.role == 'owner');
  bool get isOwner => _user != null && _user!.role == 'owner';
  bool get isSubLeader => _user != null && _user!.role == 'sublider';
  bool get isRecruta => _user != null && _user!.role == 'recruta';

  // Method to update user data in Firestore (e.g., profile update)
  Future<void> updateUserData(Map<String, dynamic> data) async {
    if (_user == null) {
      Logger.warning('Cannot update user data: User is not loaded.');
      return;
    }
    setLoading(true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update(data);
      // Re-load data to reflect changes locally
      await loadUserData(_user!.uid);
      Logger.info('User data updated successfully in Firestore.');
    } catch (e, stackTrace) {
      Logger.error('Failed to update user data in Firestore', error: e, stackTrace: stackTrace);
      // Optionally show an error message to the user
    } finally {
      setLoading(false);
    }
  }
}

