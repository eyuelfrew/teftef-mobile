import 'dart:developer' show log;

import 'package:firebase_auth/firebase_auth.dart';

import 'backend_auth_service.dart';
import 'auth_state.dart';

/// -------------------------------
/// Google + Firebase Auth Service
/// -------------------------------
class GoogleAuthService {
  final BackendAuthService _backendAuthService = BackendAuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Sign in with Google and authenticate with Firebase
  Future<AuthState> signInWithGoogle() async {
    try {
      log('Starting Google Sign-In with Firebase Integration');

      // Use the backend service for authentication (now using Firebase only)
      return await _backendAuthService.signInWithGoogle();
    } catch (e, s) {
      log('Google sign-in with Firebase failed', error: e, stackTrace: s);
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

  /// Sign out from Firebase and Google
  Future<void> signOut() async {
    await _backendAuthService.signOut();
  }

  /// Get current user profile from Backend
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    return await _backendAuthService.fetchBackendProfile();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _backendAuthService.validateSession();
  }

  /// Send OTP
  Future<Map<String, dynamic>> sendOtp({String? phoneNumber}) async {
    return await _backendAuthService.sendOtp(phoneNumber: phoneNumber);
  }

  /// Verify OTP
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    return await _backendAuthService.verifyOtp(phoneNumber, otp);
  }
}