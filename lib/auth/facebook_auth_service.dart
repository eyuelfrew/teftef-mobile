/*
import 'dart:developer' show log;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'backend_auth_service.dart';
import 'auth_state.dart';

/// -------------------------------
/// Facebook + Firebase Auth Service
/// -------------------------------
class FacebookAuthService {
  final BackendAuthService _backendAuthService = BackendAuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Sign in with Facebook and authenticate with Firebase
  Future<AuthState> signInWithFacebook() async {
    try {
      log('Starting Facebook Sign-In with Firebase Integration');

      // Use the backend service for authentication
      return await _backendAuthService.signInWithFacebook();
    } catch (e, s) {
      log('Facebook sign-in with Firebase failed', error: e, stackTrace: s);
      return AuthState(
        user: null,
        isLoading: false,
        isSigningIn: false,
        error: e.toString(),
      );
    }
  }

  /// Silent sign-in (check Firebase session)
  Future<User?> getCurrentUser() async {
    bool isValid = await _backendAuthService.validateSession();
    if (isValid) {
      return _firebaseAuth.currentUser;
    }
    return null;
  }

  /// Sign out from Firebase and Facebook
  Future<void> signOut() async {
    await _backendAuthService.signOut();
  }

  /// Get current user profile from Firebase
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    return await _backendAuthService.getCurrentUserProfile();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _backendAuthService.validateSession();
  }
}
*/