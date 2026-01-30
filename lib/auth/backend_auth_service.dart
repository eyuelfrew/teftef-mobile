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

      // Store user data in secure storage (Firebase info as fallback)
      await _storeUserData(firebaseUser);

      // Send user data to backend API and get JWT
      final syncResult = await _syncUserWithBackend(firebaseUser, googleAuth.idToken);
      
      if (syncResult != null && syncResult['access_token'] != null) {
        // Fetch fresh profile from backend using the new JWT
        final backendProfile = await fetchBackendProfile();
        
        return AuthState(
          user: firebaseUser,
          backendUser: backendProfile,
          isLoading: false,
          isSigningIn: false,
        );
      }

      // Fallback if sync failed but Firebase succeeded
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

  /// Validate current session with Backend
  Future<bool> validateSession() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return false;
    
    // Also check Firebase as a secondary check
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
    // We already have Firebase user, this is just for offline/fallback
    final userData = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
    };
    await _storage.write(key: _userDataKey, value: jsonEncode(userData));
  }

  /// Sync user data with backend API
  Future<Map<String, dynamic>?> _syncUserWithBackend(User user, String? idToken) async {
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
        
        final data = responseData['data'];
        if (data != null) {
          // Store backend user ID
          if (data['user_id'] != null) {
            await _storage.write(key: 'backend_user_id', value: data['user_id'].toString());
          }
          
          // Store access token
          if (data['access_token'] != null) {
            await _storage.write(key: _accessTokenKey, value: data['access_token']);
            return data;
          }
        }
      } else {
        log('Failed to sync user data: ${response.statusCode} - ${response.body}');
      }
      return null;
    } catch (e, s) {
      log('Error syncing user with backend', error: e, stackTrace: s);
      return null;
    }
  }

  /// Fetch user profile from backend
  Future<Map<String, dynamic>?> fetchBackendProfile() async {
    try {
      final token = await getAccessToken();
      if (token == null) return null;

      log('Fetching profile from backend...');
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['data']['user'];
        }
      } else if (response.statusCode == 401) {
        log('Session expired (401). Clearing tokens.');
        await signOut();
      }
      return null;
    } catch (e) {
      log('Error fetching backend profile: $e');
      return null;
    }
  }
  /// Send OTP to phone number
  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Authentication required'};
      }

      log('Sending OTP to $phoneNumber...');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/send-otp'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'phone_number': phoneNumber}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': data['message'] ?? 'OTP sent successfully'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to send OTP'};
      }
    } catch (e) {
      log('Error sending OTP: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Verify OTP
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Authentication required'};
      }

      log('Verifying OTP for $phoneNumber...');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone_number': phoneNumber,
          'otp': otp,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Phone verified successfully'};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Invalid OTP'};
      }
    } catch (e) {
      log('Error verifying OTP: $e');
      return {'success': false, 'message': 'Connection error: $e'};
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