import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

Future<AuthState> signInWithFacebook() async {
  try {
    // 1. Trigger the Facebook Sign-In popup
    final LoginResult result = await FacebookAuth.instance.login(
      permissions: ['public_profile', 'email'],
    );

    if (result.status == LoginStatus.success) {
      // 2. Create a credential for Firebase
      final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);

      // 3. Sign in to Firebase
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      // Store data & return state (reusing your existing logic)
      await _storeUserData(userCredential.user!);
      return AuthState(user: userCredential.user, isLoading: false, isSigningIn: false);
    }
    return AuthState(user: null, isLoading: false, isSigningIn: false, error: 'Login failed');
  } catch (e) {
    return AuthState(user: null, isLoading: false, isSigningIn: false, error: e.toString());
  }
}