import 'package:cloud_firestore/cloud_firestore.dart';

class StudyTask {
  const StudyTask({
    required this.id,
    required this.userId,
    required this.examId,
    required this.topicId,
    required this.topicTitle,
    required this.title,
    required this.description,
    required this.taskType,
    required this.scheduledFor,
    required this.estimatedMinutes,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  final String id;
  final String userId;
  final String examId;
  final String topicId;
  final String topicTitle;
  final String title;
  final String description;
  final String taskType;
  final DateTime scheduledFor;
  final int estimatedMinutes;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  String get topic => topicTitle;

  factory StudyTask.fromMap(String id, Map<String, dynamic> map) {
    return StudyTask(
      id: id,
      userId: map['userId'] as String? ?? '',
      examId: map['examId'] as String? ?? '',
      topicId: map['topicId'] as String? ?? '',
      topicTitle: map['topicTitle'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      taskType: map['taskType'] as String? ?? 'study',
      scheduledFor: _readDate(map['scheduledFor']),
      estimatedMinutes: (map['estimatedMinutes'] as num?)?.toInt() ?? 30,
      isCompleted: map['isCompleted'] as bool? ?? false,
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
      completedAt: map['completedAt'] == null ? null : _readDate(map['completedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'examId': examId,
      'topicId': topicId,
      'topicTitle': topicTitle,
      'title': title,
      'description': description,
      'taskType': taskType,
      'scheduledFor': Timestamp.fromDate(scheduledFor),
      'estimatedMinutes': estimatedMinutes,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'completedAt': completedAt == null ? null : Timestamp.fromDate(completedAt!),
    };
  }

  StudyTask copyWith({
    String? id,
    String? userId,
    String? examId,
    String? topicId,
    String? topicTitle,
    String? title,
    String? description,
    String? taskType,
    DateTime? scheduledFor,
    int? estimatedMinutes,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return StudyTask(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      examId: examId ?? this.examId,
      topicId: topicId ?? this.topicId,
      topicTitle: topicTitle ?? this.topicTitle,
      title: title ?? this.title,
      description: description ?? this.description,
      taskType: taskType ?? this.taskType,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
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
