import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error registering: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Add this method to AuthService class
  Future<String?> getCurrentUserEmail() async {
    final user = _auth.currentUser;
    return user?.email;
  }

  // Add this method
  Future<String?> getUserEmail() async {
    final user = _auth.currentUser;
    return user?.email;
  }

  // Add these methods to AuthService class
  Future<String?> getUsername() async {
    final user = _auth.currentUser;
    return user?.displayName;
  }

  Future<void> updateUsername(String username) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(username);
    }
  }
}
