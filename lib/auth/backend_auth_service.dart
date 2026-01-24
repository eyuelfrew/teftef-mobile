import 'dart:developer' show log;
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'auth_state.dart';

class BackendAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // API Configuration
  static const String baseUrl = "http://localhost:5000/api";
  
  // Keys for storing tokens in secure storage
  static const String _accessTokenKey = 'access_token';
  static const String _userDataKey = 'user_data';

  /// Sign in with Google using Firebase only (no backend API)
  Future<AuthState> signInWithGoogle() async {
    try {
      log('Starting Google Sign-In with Firebase');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      log('Google Sign-In account obtained');
      log('Google User: ${googleUser?.email}');
      log('Google User ID: ${googleUser?.id}');
      if (googleUser == null) {
        log('User cancelled Google Sign-In');
        return AuthState(user: null, isLoading: false, isSigningIn: false);
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Get Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase to get user details
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Firebase authentication failed');
      }

      // Store user data in secure storage
      await _storeUserData(firebaseUser);

      // Send user data to backend API
      await _syncUserWithBackend(firebaseUser, googleAuth.idToken);

      // Update last login
      await _updateLastLogin(firebaseUser.uid);

      // Return success state with user info
      return AuthState(
        user: firebaseUser,
        isLoading: false,
        isSigningIn: false,
      );
    } catch (e, s) {
      log('Firebase auth failed', error: e, stackTrace: s);
      return AuthState(
        user: null,
        isLoading: false,
        isSigningIn: false,
        error: e.toString(),
      );
    }
  }

  /*
  /// Sign in with Facebook using Firebase only (no backend API)
  Future<AuthState> signInWithFacebook() async {
    try {
      log('Starting Facebook Sign-In with Firebase');

      // Trigger the Facebook Sign-In popup
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );

      if (result.status == LoginStatus.success) {
        log('Facebook Sign-In successful');

        // Create a credential for Firebase
        final credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);

        // Sign in to Firebase
        final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
        final User? firebaseUser = userCredential.user;

        if (firebaseUser == null) {
          throw Exception('Firebase authentication failed');
        }

        // Store user data in secure storage
        await _storeUserData(firebaseUser);

        // Update last login
        await _updateLastLogin(firebaseUser.uid);

        // Return success state with user info
        return AuthState(
          user: firebaseUser,
          isLoading: false,
          isSigningIn: false,
        );
      } else {
        log('Facebook Sign-In cancelled or failed');
        return AuthState(user: null, isLoading: false, isSigningIn: false, error: 'Login failed');
      }
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
  */

  /// Validate current session with Firebase
  Future<bool> validateSession() async {
    final user = _firebaseAuth.currentUser;
    return user != null;
  }

  /// Get current user profile from Firebase
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'phoneNumber': user.phoneNumber,
        'emailVerified': user.emailVerified,
      };
      // Update stored user data
      await _storeUserData(user);
      return userData;
    }
    return null;
  }

  /// Sign out from Firebase and clear local tokens
  Future<void> signOut() async {
    try {
      // Clear local tokens
      await _clearTokens();
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      log('Logout failed', error: e);
    }
  }

  /// Store user data securely
  Future<void> _storeUserData(User user) async {
    final userData = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'phoneNumber': user.phoneNumber,
      'emailVerified': user.emailVerified,
    };
    await _storage.write(key: _userDataKey, value: jsonEncode(userData));
  }

  /// Sync user data with backend API
  Future<void> _syncUserWithBackend(User user, String? idToken) async {
    try {
      log('Syncing user data with backend...');
      
      final userData = {
        'firebase_uid': user.uid,
        'email': user.email,
        'display_name': user.displayName,
        'photo_url': user.photoURL,
        'phone_number': user.phoneNumber,
        'email_verified': user.emailVerified,
        'provider': 'google',
        'id_token': idToken,
        'metadata': {
          'creation_time': user.metadata.creationTime?.toIso8601String(),
          'last_sign_in_time': user.metadata.lastSignInTime?.toIso8601String(),
        }
      };

      final response = await http.post(
        Uri.parse('$baseUrl/auth/sync-user'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('User data synced successfully');
        final responseData = jsonDecode(response.body);
        
        // Store backend user ID if provided
        if (responseData['data'] != null && responseData['data']['user_id'] != null) {
          await _storage.write(
            key: 'backend_user_id',
            value: responseData['data']['user_id'].toString(),
          );
        }
        
        // Store access token if provided
        if (responseData['data'] != null && responseData['data']['access_token'] != null) {
          await _storage.write(
            key: _accessTokenKey,
            value: responseData['data']['access_token'],
          );
        }
      } else {
        log('Failed to sync user data: ${response.statusCode} - ${response.body}');
      }
    } catch (e, s) {
      log('Error syncing user with backend', error: e, stackTrace: s);
      // Don't throw error - allow login to continue even if backend sync fails
    }
  }


  /// Clear stored tokens
  Future<void> _clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _userDataKey);
  }

  /// Update last login timestamp
  Future<void> _updateLastLogin(String firebaseUid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_login_firebase_uid', firebaseUid);
    await prefs.setInt('last_login_time', DateTime.now().millisecondsSinceEpoch);
  }

  /// Get stored user data as map
  Map<String, dynamic>? getStoredUser() {
    // This is a simplified version - in a real app you'd retrieve from secure storage
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      return {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
      };
    }
    return null;
  }

  /// Helper method to encode JSON


  /// Get backend user ID
  Future<String?> getBackendUserId() async {
    return await _storage.read(key: 'backend_user_id');
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }


  /// Silent sign-in (check if we have valid session)
  User? get currentUser {
    return _firebaseAuth.currentUser;
  }
}