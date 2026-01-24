import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'auth_state.dart';
// import 'facebook_auth_service.dart'; // Facebook auth commented out due to business profile requirements

class AuthController with ChangeNotifier {
  final GoogleAuthService _authService = GoogleAuthService();
  // final FacebookAuthService _facebookAuthService = FacebookAuthService(); // Facebook auth commented out due to business profile requirements
  AuthState _state = AuthState(isLoading: true);

  AuthState get state => _state;

  AuthController() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      // Check if we have a valid session with the backend
      final user = await _authService.getCurrentUser();

      _state = AuthState(
        user: user,
        isLoading: false,
        isSigningIn: false
      );
      notifyListeners();
    } catch (e) {
      log('Auth initialization failed: $e');
      _state = AuthState(
        user: null,
        isLoading: false,
        isSigningIn: false
      );
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    _state = _state.copyWith(isSigningIn: true, error: null);
    notifyListeners();
    try {
      final authState = await _authService.signInWithGoogle();

      // Update state based on the result from backend service
      _state = authState;
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isSigningIn: false,
        error: 'Sign-in failed: ${e.toString()}'
      );
      notifyListeners();
    }
  }

  /*
  Future<void> signInWithFacebook() async {
    _state = _state.copyWith(isSigningIn: true, error: null);
    notifyListeners();
    try {
      final authState = await _facebookAuthService.signInWithFacebook();

      // Update state based on the result from backend service
      _state = authState;
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isSigningIn: false,
        error: 'Sign-in failed: ${e.toString()}'
      );
      notifyListeners();
    }
  }
  */

  Future<void> signOut() async {
    await _authService.signOut();
    _state = AuthState(user: null, isLoading: false, isSigningIn: false);
    notifyListeners();
  }
}

