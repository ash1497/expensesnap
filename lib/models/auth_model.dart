// ignore_for_file: avoid_print, use_rethrow_when_possible

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthModel {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Login with Email and Password
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Error logging in with email: $e");
      throw e;
    }
  }

  // Register with Email and Password
  Future<bool> registerWithEmailAndPassword(String email, String password, String username) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user?.updateDisplayName(username);
      await userCredential.user?.reload();
      return true; // Registration successful
    } catch (e) {
      print('Registration Error: $e');
      return false; // Registration failed
    }
  }

  // Login with Google
  Future<User?> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return null; // User canceled the login
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print("Error logging in with Google: $e");
      throw e;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  // Get Current User
  User? get currentUser => _auth.currentUser;
}
