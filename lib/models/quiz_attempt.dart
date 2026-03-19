import 'package:cloud_firestore/cloud_firestore.dart';

class QuizAttempt {
  QuizAttempt({
    required this.id,
    required this.userId,
    required this.examId,
    required this.scorePercent,
    required this.correctAnswers,
    required this.totalQuestions,
    required List<String> weakTopics,
    required this.attemptedAt,
  }) : weakTopics = List<String>.from(weakTopics);

  final String id;
  final String userId;
  final String examId;
  final int scorePercent;
  final int correctAnswers;
  final int totalQuestions;
  final List<String> weakTopics;
  final DateTime attemptedAt;

  factory QuizAttempt.fromMap(String id, Map<String, dynamic> map) {
    return QuizAttempt(
      id: id,
      userId: map['userId'] as String? ?? '',
      examId: map['examId'] as String? ?? '',
      scorePercent: (map['scorePercent'] as num?)?.toInt() ?? 0,
      correctAnswers: (map['correctAnswers'] as num?)?.toInt() ?? 0,
      totalQuestions: (map['totalQuestions'] as num?)?.toInt() ?? 0,
      weakTopics: List<String>.from(map['weakTopics'] as List<dynamic>? ?? const <String>[]),
      attemptedAt: _readDate(map['attemptedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'examId': examId,
      'scorePercent': scorePercent,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'weakTopics': weakTopics,
      'attemptedAt': Timestamp.fromDate(attemptedAt),
    };
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
