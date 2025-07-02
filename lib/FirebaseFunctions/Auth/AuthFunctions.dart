import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again later.';
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again later.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again later.';
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.updatePhotoURL(photoURL);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again later.';
    }
  }

  // Change password
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw 'No user is signed in';

      // Re-authenticate user before changing password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again later.';
    }
  }

  // Delete user account
  Future<void> deleteAccount(String password) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw 'No user is signed in';

      // Re-authenticate user before deleting account
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again later.';
    }
  }

  // Helper method to handle Firebase Auth exceptions
  String _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please use a different email or try logging in.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'too-many-requests':
        return 'Too many unsuccessful login attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again later. Error: ${e.code}';
    }
  }
}
