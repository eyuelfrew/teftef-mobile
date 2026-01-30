import 'package:firebase_auth/firebase_auth.dart';

class AuthState {
  final User? user;
  final Map<String, dynamic>? backendUser;
  final bool isLoading;
  final bool isSigningIn;
  final String? error;

  AuthState({
    this.user,
    this.backendUser,
    this.isLoading = false,
    this.isSigningIn = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    Map<String, dynamic>? backendUser,
    bool? isLoading,
    bool? isSigningIn,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      backendUser: backendUser ?? this.backendUser,
      isLoading: isLoading ?? this.isLoading,
      isSigningIn: isSigningIn ?? this.isSigningIn,
      error: error ?? this.error,
    );
  }
}
