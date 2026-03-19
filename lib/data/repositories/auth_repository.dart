import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants/app_constants.dart';
import '../../models/app_user.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<AppUser?> fetchUserProfile(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return AppUser.fromMap(snapshot.id, snapshot.data()!);
  }

  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String password,
    Map<String, dynamic>? onboardingData,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user!;
    await firebaseUser.updateDisplayName(fullName);
    await firebaseUser.sendEmailVerification();

    final profile = AppUser(
      uid: firebaseUser.uid,
      fullName: fullName,
      email: email,
      avatarUrl: null,
      avatarPlaceholder: _initialsFromName(fullName),
      createdAt: DateTime.now(),
      emailVerified: firebaseUser.emailVerified,
      onboardingData: _normalizedOnboarding(onboardingData),
    );

    await _firestore.collection('users').doc(firebaseUser.uid).set(profile.toMap());
    return profile;
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user!;
    return ensureUserProfile(
      firebaseUser: firebaseUser,
      preferredFullName: firebaseUser.displayName ?? 'Student',
      preferredEmail: firebaseUser.email ?? email,
      preferredAvatarUrl: firebaseUser.photoURL,
    );
  }

  Future<AppUser> signInWithGoogle({
    Map<String, dynamic>? onboardingData,
  }) async {
    UserCredential credential;

    if (kIsWeb) {
      credential = await _auth.signInWithPopup(GoogleAuthProvider());
    } else {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const GoogleSignInCancelledException();
      }

      final googleAuth = await googleUser.authentication;
      final authCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      credential = await _auth.signInWithCredential(authCredential);
    }

    final firebaseUser = credential.user!;
    return ensureUserProfile(
      firebaseUser: firebaseUser,
      preferredFullName: firebaseUser.displayName ?? 'Student',
      preferredEmail: firebaseUser.email ?? '',
      preferredAvatarUrl: firebaseUser.photoURL,
      onboardingData: onboardingData,
    );
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore local Google sign-out errors and still clear Firebase session.
    }

    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> resendVerificationEmail() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      return;
    }

    await firebaseUser.sendEmailVerification();
  }

  Future<void> reloadCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      return;
    }

    await firebaseUser.reload();
    final refreshedUser = _auth.currentUser;
    if (refreshedUser == null) {
      return;
    }

    await _firestore.collection('users').doc(refreshedUser.uid).set(
          {
            'emailVerified': refreshedUser.emailVerified,
          },
          SetOptions(merge: true),
        );
  }

  Future<void> updateProfile({
    required String uid,
    required String fullName,
    String? avatarUrl,
    Map<String, dynamic>? onboardingData,
  }) async {
    await _firestore.collection('users').doc(uid).set(
          {
            'fullName': fullName,
            'avatarUrl': avatarUrl,
            'avatarPlaceholder': _initialsFromName(fullName),
            ...?(onboardingData == null ? null : {'onboardingData': onboardingData}),
          },
          SetOptions(merge: true),
        );

    await _auth.currentUser?.updateDisplayName(fullName);
  }

  Future<AppUser> ensureUserProfile({
    required User firebaseUser,
    String? preferredFullName,
    String? preferredEmail,
    String? preferredAvatarUrl,
    Map<String, dynamic>? onboardingData,
  }) async {
    final existingProfile = await fetchUserProfile(firebaseUser.uid);

    if (existingProfile != null) {
      final syncedProfile = existingProfile.copyWith(
        fullName: existingProfile.fullName.isEmpty
            ? (preferredFullName ?? firebaseUser.displayName ?? 'Student')
            : existingProfile.fullName,
        email: existingProfile.email.isEmpty
            ? (preferredEmail ?? firebaseUser.email ?? '')
            : existingProfile.email,
        avatarUrl: existingProfile.avatarUrl ?? preferredAvatarUrl,
        emailVerified: firebaseUser.emailVerified,
      );

      await _firestore.collection('users').doc(firebaseUser.uid).set(
            syncedProfile.toMap(),
            SetOptions(merge: true),
          );

      return syncedProfile;
    }

    final fallbackName = preferredFullName ?? firebaseUser.displayName ?? 'Student';
    final fallbackProfile = AppUser(
      uid: firebaseUser.uid,
      fullName: fallbackName,
      email: preferredEmail ?? firebaseUser.email ?? '',
      avatarUrl: preferredAvatarUrl,
      avatarPlaceholder: _initialsFromName(fallbackName),
      createdAt: DateTime.now(),
      emailVerified: firebaseUser.emailVerified,
      onboardingData: _normalizedOnboarding(onboardingData),
    );

    await _firestore.collection('users').doc(firebaseUser.uid).set(
          fallbackProfile.toMap(),
          SetOptions(merge: true),
        );

    return fallbackProfile;
  }

  Map<String, dynamic> _normalizedOnboarding(Map<String, dynamic>? onboardingData) {
    final selectedSubjects =
        List<String>.from(onboardingData?['selectedSubjects'] as List<dynamic>? ?? const <String>[]);
    final dailyGoal = (onboardingData?['dailyGoalMinutes'] as num?)?.toInt();

    return {
      'hasCompletedOnboarding': true,
      'goal': 'Exam success',
      'selectedSubjects': selectedSubjects.isEmpty
          ? AppConstants.subjects.take(3).toList()
          : selectedSubjects,
      'dailyGoalMinutes': dailyGoal ?? 90,
      'streakDays': (onboardingData?['streakDays'] as num?)?.toInt() ?? 0,
      'isPremium': onboardingData?['isPremium'] as bool? ?? false,
    };
  }
}

String _initialsFromName(String fullName) {
  final parts = fullName
      .split(' ')
      .where((part) => part.trim().isNotEmpty)
      .take(2)
      .toList();

  if (parts.isEmpty) {
    return 'AS';
  }

  return parts.map((part) => part[0].toUpperCase()).join();
}

class GoogleSignInCancelledException implements Exception {
  const GoogleSignInCancelledException();
}
