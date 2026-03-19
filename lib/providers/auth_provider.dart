import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/repositories/auth_repository.dart';
import '../models/app_user.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository) {
    _subscription = _repository.authStateChanges().listen((firebaseUser) {
      unawaited(_handleAuthChanged(firebaseUser));
    });
    unawaited(_bootstrapAuthState());
  }

  final AuthRepository _repository;
  StreamSubscription<User?>? _subscription;

  AppUser? _user;
  User? _firebaseUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  AppUser? get user => _user;
  User? get firebaseUser => _firebaseUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null && _user != null;
  bool get needsEmailVerification => _firebaseUser != null && !_firebaseUser!.emailVerified;

  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
    Map<String, dynamic>? onboardingData,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final profile = await _repository.signUp(
        fullName: fullName,
        email: email,
        password: password,
        onboardingData: onboardingData,
      );
      _firebaseUser = _repository.currentUser;
      _user = profile.copyWith(
        emailVerified: _firebaseUser?.emailVerified ?? profile.emailVerified,
      );
      _isInitialized = true;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _authMessage(error);
      return false;
    } on FirebaseException catch (error) {
      _errorMessage = error.message ?? 'Could not save your profile to Firestore.';
      return false;
    } catch (_) {
      _errorMessage = 'Failed to create the account. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final profile = await _repository.signIn(
        email: email,
        password: password,
      );
      _firebaseUser = _repository.currentUser;
      _user = profile.copyWith(
        emailVerified: _firebaseUser?.emailVerified ?? profile.emailVerified,
      );
      _isInitialized = true;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _authMessage(error);
      return false;
    } on FirebaseException catch (error) {
      _errorMessage = error.message ?? 'Could not load your account data.';
      return false;
    } catch (_) {
      _errorMessage = 'Sign in failed. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle({
    Map<String, dynamic>? onboardingData,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final profile = await _repository.signInWithGoogle(
        onboardingData: onboardingData,
      );
      _firebaseUser = _repository.currentUser;
      _user = profile.copyWith(
        emailVerified: _firebaseUser?.emailVerified ?? profile.emailVerified,
      );
      _isInitialized = true;
      notifyListeners();
      return true;
    } on GoogleSignInCancelledException {
      _errorMessage = null;
      return false;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _authMessage(error);
      return false;
    } on FirebaseException catch (error) {
      _errorMessage = error.message ?? 'Could not load your Google account data.';
      return false;
    } on UnsupportedError catch (error) {
      _errorMessage = error.message ?? 'Google sign-in is not supported on this platform.';
      return false;
    } catch (_) {
      _errorMessage = 'Google sign-in failed. Enable Google in Firebase Authentication and try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _errorMessage = null;
  }

  Future<void> logout() => signOut();

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _repository.sendPasswordReset(email);
      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _authMessage(error);
      return false;
    } catch (_) {
      _errorMessage = 'Could not send reset email right now.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resendVerificationEmail() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _repository.resendVerificationEmail();
    } on FirebaseAuthException catch (error) {
      _errorMessage = _authMessage(error);
    } catch (_) {
      _errorMessage = 'Could not resend the verification email.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> reloadUser() async {
    await _repository.reloadCurrentUser();
    await _handleAuthChanged(_repository.currentUser);
  }

  Future<bool> updateProfile({
    required String fullName,
    String? avatarUrl,
    Map<String, dynamic>? onboardingData,
  }) async {
    if (_user == null) {
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      await _repository.updateProfile(
        uid: _user!.uid,
        fullName: fullName,
        avatarUrl: avatarUrl,
        onboardingData: onboardingData,
      );
      await _handleAuthChanged(_repository.currentUser);
      return true;
    } catch (_) {
      _errorMessage = 'Could not update your profile.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _handleAuthChanged(User? firebaseUser) async {
    _firebaseUser = firebaseUser;

    if (firebaseUser == null) {
      _user = null;
      _isInitialized = true;
      notifyListeners();
      return;
    }

    try {
      _user = await _repository
          .ensureUserProfile(
        firebaseUser: firebaseUser,
        preferredFullName: firebaseUser.displayName,
        preferredEmail: firebaseUser.email,
        preferredAvatarUrl: firebaseUser.photoURL,
      )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      _user = null;
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _bootstrapAuthState() async {
    if (_isInitialized) {
      return;
    }

    await _handleAuthChanged(_repository.currentUser);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> updateDailyGoalMinutes(int minutes) async {
    if (_user == null) {
      return;
    }

    final updatedOnboarding = Map<String, dynamic>.from(_user!.onboardingData)
      ..['dailyGoalMinutes'] = minutes;

    await updateProfile(
      fullName: _user!.fullName,
      avatarUrl: _user!.avatarUrl,
      onboardingData: updatedOnboarding,
    );
  }

  Future<void> updateSelectedSubjects(List<String> subjects) async {
    if (_user == null) {
      return;
    }

    final updatedOnboarding = Map<String, dynamic>.from(_user!.onboardingData)
      ..['selectedSubjects'] = subjects;

    await updateProfile(
      fullName: _user!.fullName,
      avatarUrl: _user!.avatarUrl,
      onboardingData: updatedOnboarding,
    );
  }

  Future<void> setPremium(bool value) async {
    if (_user == null) {
      return;
    }

    final updatedOnboarding = Map<String, dynamic>.from(_user!.onboardingData)
      ..['isPremium'] = value;

    await updateProfile(
      fullName: _user!.fullName,
      avatarUrl: _user!.avatarUrl,
      onboardingData: updatedOnboarding,
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _authMessage(FirebaseAuthException error) {
    final rawMessage = (error.message ?? '').toLowerCase();

    if (rawMessage.contains('configuration_not_found') ||
        rawMessage.contains('configuration-not-found')) {
      return 'Firebase Authentication is not fully configured. Open Firebase Console and enable Email/Password sign-in.';
    }

    if (rawMessage.contains('sign_in_failed') ||
        rawMessage.contains('google') && rawMessage.contains('sign in')) {
      return 'Google sign-in is not fully configured. Enable Google in Firebase Authentication, add SHA-1/SHA-256 for Android, then download an updated google-services.json.';
    }

    if (rawMessage.contains('api key not valid')) {
      return 'Firebase API key is invalid. Check your google-services.json or firebase_options.dart configuration.';
    }

    if (rawMessage.contains('does not have permission') ||
        rawMessage.contains('permission-denied')) {
      return 'Firestore denied access. Open Firestore Database -> Rules and allow user profile writes, or use test mode while you are setting up the app.';
    }

    switch (error.code) {
      case 'network-request-failed':
        return 'Firebase could not reach the network. Check that your emulator or device has internet access, then try again.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'operation-not-allowed':
      case 'configuration-not-found':
        return 'Email/Password sign-in is disabled in Firebase Console. Enable it in Authentication.';
      case 'account-exists-with-different-credential':
        return 'This email is already linked to another sign-in method. Try logging in with the original provider first.';
      case 'email-already-in-use':
        return 'This email is already linked to another account.';
      case 'weak-password':
        return 'Use a stronger password with at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'permission-denied':
        return 'Firestore denied access. Check your Firestore rules in Firebase Console.';
      default:
        return error.message ?? 'Authentication error. Please try again.';
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
