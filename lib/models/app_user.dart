import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.createdAt,
    required Map<String, dynamic> onboardingData,
    required this.avatarPlaceholder,
    this.avatarUrl,
    this.emailVerified = false,
  }) : onboardingData = _deepCopyMap(onboardingData);

  final String uid;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String avatarPlaceholder;
  final DateTime createdAt;
  final bool emailVerified;
  final Map<String, dynamic> onboardingData;

  String get name => fullName;
  List<String> get selectedSubjects => List<String>.from(
        onboardingData['selectedSubjects'] as List<dynamic>? ?? const <String>[],
      );
  bool get isPremium => onboardingData['isPremium'] as bool? ?? false;
  int get dailyGoalMinutes => (onboardingData['dailyGoalMinutes'] as num?)?.toInt() ?? 90;
  int get streakDays => (onboardingData['streakDays'] as num?)?.toInt() ?? 0;

  String get initials {
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

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    final fallbackName = map['fullName'] as String? ?? 'Student';

    return AppUser(
      uid: uid,
      fullName: fallbackName,
      email: map['email'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String?,
      avatarPlaceholder: map['avatarPlaceholder'] as String? ?? _initialsFromName(fallbackName),
      createdAt: _readDate(map['createdAt']),
      emailVerified: map['emailVerified'] as bool? ?? false,
      onboardingData: _deepCopyMap(
        Map<String, dynamic>.from(map['onboardingData'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'avatarUrl': avatarUrl,
      'avatarPlaceholder': avatarPlaceholder,
      'createdAt': Timestamp.fromDate(createdAt),
      'emailVerified': emailVerified,
      'onboardingData': onboardingData,
    };
  }

  AppUser copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? avatarUrl,
    String? avatarPlaceholder,
    DateTime? createdAt,
    bool? emailVerified,
    Map<String, dynamic>? onboardingData,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarPlaceholder: avatarPlaceholder ?? this.avatarPlaceholder,
      createdAt: createdAt ?? this.createdAt,
      emailVerified: emailVerified ?? this.emailVerified,
      onboardingData: _deepCopyMap(onboardingData ?? this.onboardingData),
    );
  }
}

DateTime _readDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }

  return DateTime.now();
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

Map<String, dynamic> _deepCopyMap(Map<String, dynamic> source) {
  final copy = <String, dynamic>{};

  for (final entry in source.entries) {
    final value = entry.value;
    if (value is Map) {
      copy[entry.key] = _deepCopyMap(Map<String, dynamic>.from(value));
    } else if (value is List) {
      copy[entry.key] = List<dynamic>.from(
        value.map((item) {
          if (item is Map) {
            return _deepCopyMap(Map<String, dynamic>.from(item));
          }
          if (item is List) {
            return List<dynamic>.from(item);
          }
          return item;
        }),
      );
    } else {
      copy[entry.key] = value;
    }
  }

  return copy;
}
