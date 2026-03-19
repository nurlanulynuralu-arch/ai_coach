import 'package:cloud_firestore/cloud_firestore.dart';

import 'study_topic.dart';

class Exam {
  Exam({
    required this.id,
    required this.userId,
    required this.title,
    required this.subject,
    required this.studyLevel,
    required this.examType,
    required this.examDate,
    required this.targetScore,
    required this.difficulty,
    required List<StudyTopic> topics,
    required List<String> weakAreas,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  })  : topics = List<StudyTopic>.from(topics),
        weakAreas = List<String>.from(weakAreas);

  final String id;
  final String userId;
  final String title;
  final String subject;
  final String studyLevel;
  final String examType;
  final DateTime examDate;
  final int targetScore;
  final String difficulty;
  final List<StudyTopic> topics;
  final List<String> weakAreas;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;

  String get name => title;
  int get readinessScore {
    final pressurePenalty = daysLeft > 21 ? 0 : (21 - daysLeft) * 2;
    final baseScore = targetScore - pressurePenalty + (topics.length * 4);
    return baseScore.clamp(35, 98);
  }

  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final examDay = DateTime(examDate.year, examDate.month, examDate.day);
    final difference = examDay.difference(today).inDays;
    return difference < 0 ? 0 : difference;
  }

  factory Exam.fromMap(String id, Map<String, dynamic> map) {
    return Exam(
      id: id,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      studyLevel: map['studyLevel'] as String? ?? 'B1',
      examType: map['examType'] as String? ?? 'School exam',
      examDate: _readDate(map['examDate']),
      targetScore: (map['targetScore'] as num?)?.toInt() ?? 80,
      difficulty: map['difficulty'] as String? ?? 'Balanced',
      topics: (map['topics'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => StudyTopic.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
      weakAreas: List<String>.from(map['weakAreas'] as List<dynamic>? ?? const <String>[]),
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'subject': subject,
      'studyLevel': studyLevel,
      'examType': examType,
      'examDate': Timestamp.fromDate(examDate),
      'targetScore': targetScore,
      'difficulty': difficulty,
      'topics': topics.map((topic) => topic.toMap()).toList(),
      'weakAreas': weakAreas,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'notes': notes,
    };
  }

  Exam copyWith({
    String? id,
    String? userId,
    String? title,
    String? subject,
    String? studyLevel,
    String? examType,
    DateTime? examDate,
    int? targetScore,
    String? difficulty,
    List<StudyTopic>? topics,
    List<String>? weakAreas,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) {
    return Exam(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      studyLevel: studyLevel ?? this.studyLevel,
      examType: examType ?? this.examType,
      examDate: examDate ?? this.examDate,
      targetScore: targetScore ?? this.targetScore,
      difficulty: difficulty ?? this.difficulty,
      topics: List<StudyTopic>.from(topics ?? this.topics),
      weakAreas: List<String>.from(weakAreas ?? this.weakAreas),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
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
