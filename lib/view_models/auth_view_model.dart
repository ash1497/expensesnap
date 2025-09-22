// ignore_for_file: use_rethrow_when_possible

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_application/models/auth_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receipt_application/view_models/image_view_model.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthModel _authModel = AuthModel();
  
  

  String? _uid;

  String? get uid => _uid;

  // Fetch user account details
  Map<String, String?> getAccountDetails() {
    final user = _authModel.currentUser;
    return {
      'email': user?.email,
      'username': user?.displayName,
    };
  }

  // Check login status
  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _uid = prefs.getString('uid');
    notifyListeners();
  }

  // Save UID locally
  Future<void> saveUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid);
    _uid = uid;
    notifyListeners();
  }

  // Get Firebase ID Token
  Future<String?> getIdToken() async {
    final user = _authModel.currentUser;
    return await user?.getIdToken();
  }

  // Login with Email/Password
  Future<bool> loginWithEmail(
      {required String email, required String password}) async {
    try {
      final user = await _authModel.loginWithEmail(email, password);
      if (user != null) {
        await saveUid(user.uid);
        return true; // Sign-in successful
      }
      return false; // Sign-in failed
    } catch (e) {
      return false; // Sign-in failed
    }
  }

  // Register with Email/Password/Username
  Future<bool> register(String email, String password, String username) async {
    return await _authModel.registerWithEmailAndPassword(
        email, password, username);
  }

  // Login with Google
  Future<dynamic> loginWithGoogle() async {
    try {
      final user = await _authModel.loginWithGoogle();
      if (user == null) {
        return null; // User canceled the Google Sign-In
      }
      await saveUid(user.uid);
      return true; // Return user data or some success indicator
    } catch (e) {
      return false; // Sign-in failed
    }
  }

  // Logout
  Future<void> logout(BuildContext context) async {
    await _authModel.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('uid');
    _uid = null;

    //Reset ImageViewmodel upon logout
    if (context.mounted){
      final imageViewModel = Provider.of<ImageViewModel>(context, listen: false);
      imageViewModel.resetImageViewModel();
    }
    
    notifyListeners();
  }
}
