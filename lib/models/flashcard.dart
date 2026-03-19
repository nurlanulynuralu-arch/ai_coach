import 'package:cloud_firestore/cloud_firestore.dart';

class Flashcard {
  const Flashcard({
    required this.id,
    required this.userId,
    required this.examId,
    required this.topicId,
    required this.topicTitle,
    required this.front,
    required this.back,
    required this.masteryLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String examId;
  final String topicId;
  final String topicTitle;
  final String front;
  final String back;
  final int masteryLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get reviewStage => masteryLevel;

  factory Flashcard.fromMap(String id, Map<String, dynamic> map) {
    return Flashcard(
      id: id,
      userId: map['userId'] as String? ?? '',
      examId: map['examId'] as String? ?? '',
      topicId: map['topicId'] as String? ?? '',
      topicTitle: map['topicTitle'] as String? ?? '',
      front: map['front'] as String? ?? '',
      back: map['back'] as String? ?? '',
      masteryLevel: (map['masteryLevel'] as num?)?.toInt() ?? 0,
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'examId': examId,
      'topicId': topicId,
      'topicTitle': topicTitle,
      'front': front,
      'back': back,
      'masteryLevel': masteryLevel,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Flashcard copyWith({
    String? id,
    String? userId,
    String? examId,
    String? topicId,
    String? topicTitle,
    String? front,
    String? back,
    int? masteryLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      examId: examId ?? this.examId,
      topicId: topicId ?? this.topicId,
      topicTitle: topicTitle ?? this.topicTitle,
      front: front ?? this.front,
      back: back ?? this.back,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
