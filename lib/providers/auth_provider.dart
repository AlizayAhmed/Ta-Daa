import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

/// Provider class for managing authentication state
/// Handles login, signup, logout, and session persistence
class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  User? _user;
  AppUser? _appUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _rememberMe = false;

  // Getters
  User? get user => _user;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get rememberMe => _rememberMe;

  AuthProvider() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _loadUserProfile();
        // Subscribe to FCM notifications for this user
        _notificationService.subscribeUserNotifications(user.uid);
      } else {
        _appUser = null;
      }
      notifyListeners();
    });

    // Check for saved login preference
    _checkRememberMe();
  }

  /// Check if user has Remember Me enabled
  Future<void> _checkRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    _rememberMe = prefs.getBool('remember_me') ?? false;
    notifyListeners();
  }

  /// Load user profile from Firestore
  Future<void> _loadUserProfile() async {
    if (_user == null) return;

    try {
      _appUser = await _firestoreService.getUserProfile(_user!.uid);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Create user account
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      if (credential.user != null) {
        final appUser = AppUser(
          uid: credential.user!.uid,
          name: name,
          email: email,
          createdAt: DateTime.now(),
        );

        await _firestoreService.createUserProfile(appUser);
        _appUser = appUser;
        _user = credential.user;
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(_getFirebaseErrorMessage(e.code));
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('An unexpected error occurred. Please try again.');
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = credential.user;

      // Save remember me preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', rememberMe);
      _rememberMe = rememberMe;

      // Load user profile
      if (_user != null) {
        await _loadUserProfile();
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(_getFirebaseErrorMessage(e.code));
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('An unexpected error occurred. Please try again.');
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _setLoading(false);
        return false; // User cancelled
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      _user = userCredential.user;

      // Check if user profile exists, if not create one
      if (_user != null) {
        try {
          _appUser = await _firestoreService.getUserProfile(_user!.uid);
        } catch (e) {
          // Profile doesn't exist, create it
          _appUser = AppUser(
            uid: _user!.uid,
            name: _user!.displayName ?? 'User',
            email: _user!.email ?? '',
            createdAt: DateTime.now(),
          );
          await _firestoreService.createUserProfile(_appUser!);
        }
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Google sign-in failed. Please try again.');
      debugPrint('Google sign-in error: $e');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);

    try {
      // Unsubscribe from FCM notifications before signing out
      if (_user != null) {
        await _notificationService.unsubscribeUserNotifications(_user!.uid);
      }

      await _auth.signOut();
      await _googleSignIn.signOut();

      // Clear remember me if not set
      final prefs = await SharedPreferences.getInstance();
      if (!_rememberMe) {
        await prefs.remove('remember_me');
      }

      _user = null;
      _appUser = null;
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to sign out. Please try again.');
      debugPrint('Sign out error: $e');
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(_getFirebaseErrorMessage(e.code));
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to send reset email. Please try again.');
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: currentPassword,
      );
      await _user!.reauthenticateWithCredential(credential);

      // Update password
      await _user!.updatePassword(newPassword);

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(_getFirebaseErrorMessage(e.code));
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to change password. Please try again.');
      return false;
    }
  }

  /// Update username
  Future<bool> updateUsername(String newName) async {
    if (_user == null || _appUser == null) return false;

    _setLoading(true);
    _clearError();

    try {
      // Update in Firestore
      await _firestoreService.updateUserProfile(_user!.uid, {'name': newName});

      // Update local state
      _appUser = AppUser(
        uid: _appUser!.uid,
        name: newName,
        email: _appUser!.email,
        createdAt: _appUser!.createdAt,
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to update username. Please try again.');
      return false;
    }
  }

  /// Helper: Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Helper: Set error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Helper: Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  /// Convert Firebase error codes to user-friendly messages
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'requires-recent-login':
        return 'Please log in again to perform this action.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}