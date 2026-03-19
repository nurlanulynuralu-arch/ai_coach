import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/exam.dart';
import '../../models/flashcard.dart';
import '../../models/quiz_attempt.dart';
import '../../models/study_task.dart';

class StudyRepository {
  StudyRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const int _batchChunkSize = 400;

  Stream<List<Exam>> watchExams(String userId) {
    return _firestore
        .collection('exams')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => Exam.fromMap(doc.id, doc.data()))
              .toList();
          items.sort((a, b) => a.examDate.compareTo(b.examDate));
          return items;
        });
  }

  Stream<List<StudyTask>> watchTasks(String userId) {
    return _firestore
        .collection('study_tasks')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => StudyTask.fromMap(doc.id, doc.data()))
              .toList();
          items.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
          return items;
        });
  }

  Stream<List<Flashcard>> watchFlashcards(String userId) {
    return _firestore
        .collection('flashcards')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => Flashcard.fromMap(doc.id, doc.data()))
              .toList();
          items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return items;
        });
  }

  Stream<List<QuizAttempt>> watchQuizAttempts(String userId) {
    return _firestore
        .collection('quiz_attempts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => QuizAttempt.fromMap(doc.id, doc.data()))
              .toList();
          items.sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
          return items;
        });
  }

  Future<void> saveGeneratedPlan({
    required Exam exam,
    required List<StudyTask> tasks,
    required List<Flashcard> flashcards,
  }) async {
    await _commitChunked(
      <void Function(WriteBatch)>[
        (batch) => batch.set(_firestore.collection('exams').doc(exam.id), exam.toMap()),
        ...tasks.map(
          (task) => (WriteBatch batch) => batch.set(
                _firestore.collection('study_tasks').doc(task.id),
                task.toMap(),
              ),
        ),
        ...flashcards.map(
          (flashcard) => (WriteBatch batch) => batch.set(
                _firestore.collection('flashcards').doc(flashcard.id),
                flashcard.toMap(),
              ),
        ),
      ],
    );
  }

  Future<void> updateExam(Exam exam) async {
    await _firestore.collection('exams').doc(exam.id).set(
          exam.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> replaceTasksForExam({
    required String examId,
    required List<StudyTask> tasks,
  }) async {
    final existing = await _firestore.collection('study_tasks').where('examId', isEqualTo: examId).get();
    await _commitChunked(
      <void Function(WriteBatch)>[
        ...existing.docs.map((doc) => (WriteBatch batch) => batch.delete(doc.reference)),
        ...tasks.map(
          (task) => (WriteBatch batch) => batch.set(
                _firestore.collection('study_tasks').doc(task.id),
                task.toMap(),
              ),
        ),
      ],
    );
  }

  Future<void> replaceFlashcardsForExam({
    required String examId,
    required List<Flashcard> flashcards,
  }) async {
    final existing = await _firestore.collection('flashcards').where('examId', isEqualTo: examId).get();
    await _commitChunked(
      <void Function(WriteBatch)>[
        ...existing.docs.map((doc) => (WriteBatch batch) => batch.delete(doc.reference)),
        ...flashcards.map(
          (flashcard) => (WriteBatch batch) => batch.set(
                _firestore.collection('flashcards').doc(flashcard.id),
                flashcard.toMap(),
              ),
        ),
      ],
    );
  }

  Future<void> updateTask(StudyTask task) {
    return _firestore.collection('study_tasks').doc(task.id).set(
          task.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> deleteTask(String taskId) {
    return _firestore.collection('study_tasks').doc(taskId).delete();
  }

  Future<void> saveFlashcard(Flashcard flashcard) {
    return _firestore.collection('flashcards').doc(flashcard.id).set(
          flashcard.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> deleteFlashcard(String flashcardId) {
    return _firestore.collection('flashcards').doc(flashcardId).delete();
  }

  Future<void> saveQuizAttempt(QuizAttempt attempt) {
    return _firestore.collection('quiz_attempts').doc(attempt.id).set(attempt.toMap());
  }

  Future<void> deleteExam(String examId) async {
    final tasksSnapshot = await _firestore.collection('study_tasks').where('examId', isEqualTo: examId).get();
    final flashcardsSnapshot = await _firestore.collection('flashcards').where('examId', isEqualTo: examId).get();
    final attemptsSnapshot = await _firestore.collection('quiz_attempts').where('examId', isEqualTo: examId).get();
    await _commitChunked(
      <void Function(WriteBatch)>[
        (batch) => batch.delete(_firestore.collection('exams').doc(examId)),
        ...tasksSnapshot.docs.map((doc) => (WriteBatch batch) => batch.delete(doc.reference)),
        ...flashcardsSnapshot.docs.map((doc) => (WriteBatch batch) => batch.delete(doc.reference)),
        ...attemptsSnapshot.docs.map((doc) => (WriteBatch batch) => batch.delete(doc.reference)),
      ],
    );
  }

  Future<void> _commitChunked(List<void Function(WriteBatch)> operations) async {
    if (operations.isEmpty) {
      return;
    }

    for (var start = 0; start < operations.length; start += _batchChunkSize) {
      final batch = _firestore.batch();
      final end = math.min(start + _batchChunkSize, operations.length);
      for (final operation in operations.sublist(start, end)) {
        operation(batch);
      }
      await batch.commit();
    }
  }
}
