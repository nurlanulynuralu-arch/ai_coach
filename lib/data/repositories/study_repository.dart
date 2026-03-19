import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/exam.dart';
import '../../models/flashcard.dart';
import '../../models/quiz_attempt.dart';
import '../../models/study_task.dart';

class StudyRepository {
  StudyRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
    final batch = _firestore.batch();
    batch.set(_firestore.collection('exams').doc(exam.id), exam.toMap());

    for (final task in tasks) {
      batch.set(_firestore.collection('study_tasks').doc(task.id), task.toMap());
    }

    for (final flashcard in flashcards) {
      batch.set(_firestore.collection('flashcards').doc(flashcard.id), flashcard.toMap());
    }

    await batch.commit();
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
    final batch = _firestore.batch();

    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    for (final task in tasks) {
      batch.set(_firestore.collection('study_tasks').doc(task.id), task.toMap());
    }

    await batch.commit();
  }

  Future<void> replaceFlashcardsForExam({
    required String examId,
    required List<Flashcard> flashcards,
  }) async {
    final existing = await _firestore.collection('flashcards').where('examId', isEqualTo: examId).get();
    final batch = _firestore.batch();

    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    for (final flashcard in flashcards) {
      batch.set(_firestore.collection('flashcards').doc(flashcard.id), flashcard.toMap());
    }

    await batch.commit();
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

    final batch = _firestore.batch();
    batch.delete(_firestore.collection('exams').doc(examId));

    for (final doc in tasksSnapshot.docs) {
      batch.delete(doc.reference);
    }

    for (final doc in flashcardsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    for (final doc in attemptsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
