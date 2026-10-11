import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<void>? _googleInitialization;
  Stream<User?> get changes => _auth.userChanges();
  User? get user => _auth.currentUser;
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signUp(String name, String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(name.trim());
  }

  Future<void> signInWithGoogle() async {
    _googleInitialization ??= GoogleSignIn.instance.initialize();
    try {
      await _googleInitialization;
    } catch (_) {
      _googleInitialization = null;
      rethrow;
    }
    final account = await GoogleSignIn.instance.authenticate();
    final token = account.authentication.idToken;
    if (token == null) {
      throw StateError(
        'Google did not return an identity token. Check OAuth setup.',
      );
    }
    await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: token),
    );
  }

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleInitialization != null) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        /* Firebase session is already closed. */
      }
    }
  }
}

String authError(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-credential' || 'wrong-password' || 'user-not-found' =>
        'That email and password did not work. Please try again.',
      'email-already-in-use' =>
        'An account already uses this email. Try signing in.',
      'weak-password' => 'Choose a stronger password (at least 8 characters).',
      'network-request-failed' => 'Check your connection, then try again.',
      'too-many-requests' =>
        'Too many attempts. Please wait a moment and try again.',
      'operation-not-allowed' =>
        'This sign-in method is not enabled in Firebase yet.',
      'user-disabled' => 'This account is disabled. Contact the project owner.',
      _ => error.message ?? 'Sign-in could not be completed. Please try again.',
    };
  }
  if (error is GoogleSignInException) {
    if (error.code == GoogleSignInExceptionCode.canceled) {
      return 'Google sign-in was canceled.';
    }
    return 'Google sign-in could not finish. Check your connection and Google sign-in configuration.';
  }
  return 'Something went wrong. Please try again.';
}
