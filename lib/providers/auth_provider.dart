import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  AuthStatus _status = AuthStatus.unknown;
  String? _error;
  bool _loading = false;

  // Flag: if we already have the user from signIn/signUp,
  // skip the Firestore re-fetch in the auth state listener.
  bool _skipNextAuthStateChange = false;

  UserModel? get user => _user;
  AuthStatus get status => _status;
  String? get error => _error;
  bool get loading => _loading;
  bool get isVendor => _user?.isVendor ?? false;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    // Skip Firestore re-fetch if signIn/signUp already set the user
    if (_skipNextAuthStateChange && _user != null) {
      _skipNextAuthStateChange = false;
      return;
    }

    // Cold start — fetch user from Firestore (app opened while already logged in)
    try {
      _user = await _authService.getUserModel(firebaseUser.uid);
    } catch (_) {}
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<bool> signUp(String name, String email, String password) async {
    _error = null;
    _loading = true;
    notifyListeners();
    try {
      _user = await _authService.signUp(
        email: email,
        password: password,
        name: name,
      );
      _status = AuthStatus.authenticated;
      _error = null;
      _skipNextAuthStateChange = true; // prevent double fetch
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _authError(e.code);
      return false;
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _error = null;
    _loading = true;
    notifyListeners();
    try {
      _user = await _authService.signIn(email: email, password: password);
      _status = AuthStatus.authenticated;
      _error = null;
      _skipNextAuthStateChange = true; // prevent double fetch
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _authError(e.code);
      return false;
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _skipNextAuthStateChange = false;
    notifyListeners();
  }

  /// Update the logged-in user's display name (and optional photoUrl).
  /// Returns null on success, or an error message string on failure.
  Future<String?> updateProfile({
    required String name,
    String? photoUrl,
    String? businessName,
    String? businessAddress,
    String? businessPhone,
    String? description,
  }) async {
    if (_user == null) return 'Not logged in.';
    _loading = true;
    notifyListeners();
    try {
      await _authService.updateProfile(
        uid: _user!.id,
        name: name,
        photoUrl: photoUrl,
        businessName: businessName,
        businessAddress: businessAddress,
        businessPhone: businessPhone,
        description: description,
      );
      _user = _user!.copyWith(
        name: name,
        photoUrl: photoUrl,
        businessName: businessName,
        businessAddress: businessAddress,
        businessPhone: businessPhone,
        description: description,
      );
      _error = null;
      return null; // success
    } catch (e) {
      _error = e.toString();
      return e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      default:
        return 'Error ($code). Please try again.';
    }
  }
}
