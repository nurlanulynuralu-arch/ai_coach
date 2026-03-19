import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../data/repositories/study_repository.dart';
import '../models/exam.dart';
import '../models/flashcard.dart';
import '../models/progress_stats.dart';
import '../models/quiz_attempt.dart';
import '../models/quiz_question.dart';
import '../models/study_task.dart';
import '../models/study_topic.dart';
import '../services/study_plan_generator.dart';
import '../services/topic_knowledge_service.dart';

class StudyPlanProvider extends ChangeNotifier {
  StudyPlanProvider(
    this._repository, {
    StudyPlanGenerator? generator,
    TopicKnowledgeService? knowledgeService,
    Uuid? uuid,
  })  : _generator = generator ?? StudyPlanGenerator(),
        _knowledgeService = knowledgeService ?? TopicKnowledgeService(),
        _uuid = uuid ?? const Uuid();

  final StudyRepository _repository;
  final StudyPlanGenerator _generator;
  final TopicKnowledgeService _knowledgeService;
  final Uuid _uuid;

  StreamSubscription<List<Exam>>? _examSubscription;
  StreamSubscription<List<StudyTask>>? _taskSubscription;
  StreamSubscription<List<Flashcard>>? _flashcardSubscription;
  StreamSubscription<List<QuizAttempt>>? _attemptSubscription;

  String? _userId;
  String? _activeExamId;
  bool _isLoading = false;
  String? _errorMessage;

  List<Exam> _exams = <Exam>[];
  List<StudyTask> _allTasks = <StudyTask>[];
  List<Flashcard> _allFlashcards = <Flashcard>[];
  List<QuizAttempt> _allQuizAttempts = <QuizAttempt>[];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Exam> get exams => List<Exam>.unmodifiable(_exams);
  int get examCount => _exams.length;
  Exam? examById(String examId) => _exams.where((exam) => exam.id == examId).firstOrNull;
  Exam? get activeExam => _exams.where((exam) => exam.id == _activeExamId).firstOrNull;
  List<StudyTask> get tasks {
    final exam = activeExam;
    if (exam == null) {
      return const <StudyTask>[];
    }

    final filteredTasks = _allTasks.where((task) => task.examId == exam.id).toList();
    filteredTasks.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    return filteredTasks;
  }

  List<Flashcard> get flashcards {
    final exam = activeExam;
    if (exam == null) {
      return const <Flashcard>[];
    }

    final filteredCards = _allFlashcards.where((card) => card.examId == exam.id).toList();
    filteredCards.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return filteredCards;
  }
  List<QuizAttempt> get quizAttempts => activeExam == null
      ? const <QuizAttempt>[]
      : _allQuizAttempts.where((attempt) => attempt.examId == activeExam!.id).toList();
  List<StudyTask> tasksForExam(String examId) => _allTasks.where((task) => task.examId == examId).toList();
  List<Flashcard> flashcardsForExam(String examId) =>
      _allFlashcards.where((card) => card.examId == examId).toList();
  List<QuizAttempt> attemptsForExam(String examId) =>
      _allQuizAttempts.where((attempt) => attempt.examId == examId).toList();
  List<StudyTask> tasksForTopic(String topicTitle) {
    final normalizedTopic = topicTitle.trim().toLowerCase();
    final filteredTasks = tasks
        .where((task) => task.topicTitle.trim().toLowerCase() == normalizedTopic)
        .toList();
    filteredTasks.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    return filteredTasks;
  }

  List<Flashcard> flashcardsForTopic(String topicTitle) {
    final normalizedTopic = topicTitle.trim().toLowerCase();
    final filteredCards = flashcards
        .where((card) => card.topicTitle.trim().toLowerCase() == normalizedTopic)
        .toList();
    filteredCards.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return filteredCards;
  }

  StudyTopic? topicForTitle(String topicTitle) {
    final exam = activeExam;
    if (exam == null) {
      return null;
    }

    final normalizedTopic = topicTitle.trim().toLowerCase();
    return exam.topics
        .where((topic) => topic.title.trim().toLowerCase() == normalizedTopic)
        .firstOrNull;
  }

  String? topicSummaryFor(String topicTitle) {
    final topic = topicForTitle(topicTitle);
    final exam = activeExam;
    if (topic == null || exam == null) {
      return null;
    }

    return _generator.buildTopicCoachNote(
      exam: exam,
      topic: topic,
    );
  }

  Map<String, double> get topicCompletionRatios => _topicCompletionRatios();
  StudyTask? get nextPendingTask => tasks.where((task) => !task.isCompleted).firstOrNull;
  List<StudyTask> get todayTasks {
    final today = _normalize(DateTime.now());
    return tasks.where((task) => _normalize(task.scheduledFor) == today).toList()
      ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
  }

  String get motivationalMessage {
    if (completedTasksCount == 0) {
      return 'Create your first study plan and start building momentum.';
    }
    return AppConstants.motivationMessages[completedTasksCount % AppConstants.motivationMessages.length];
  }

  Future<void> syncUser(String? userId) async {
    if (_userId == userId) {
      return;
    }

    await _cancelSubscriptions();
    _userId = userId;
    _activeExamId = null;

    if (userId == null) {
      reset();
      return;
    }

    _setLoading(true);
    _errorMessage = null;

    _examSubscription = _repository.watchExams(userId).listen(
      (items) {
        _exams = List<Exam>.from(items);
        if (_activeExamId == null || !_exams.any((exam) => exam.id == _activeExamId)) {
          _activeExamId = _exams.isEmpty ? null : _exams.first.id;
        }
        _setLoading(false);
        notifyListeners();
      },
      onError: (_) {
        _errorMessage = 'Could not load your exam workspace from Firestore.';
        _setLoading(false);
      },
    );

    _taskSubscription = _repository.watchTasks(userId).listen(
      (items) {
        _allTasks = List<StudyTask>.from(items);
        notifyListeners();
      },
      onError: (_) {
        _errorMessage = 'Could not sync study tasks.';
        notifyListeners();
      },
    );

    _flashcardSubscription = _repository.watchFlashcards(userId).listen(
      (items) {
        _allFlashcards = List<Flashcard>.from(items);
        notifyListeners();
      },
      onError: (_) {
        _errorMessage = 'Could not sync flashcards.';
        notifyListeners();
      },
    );

    _attemptSubscription = _repository.watchQuizAttempts(userId).listen(
      (items) {
        _allQuizAttempts = List<QuizAttempt>.from(items);
        notifyListeners();
      },
      onError: (_) {
        _errorMessage = 'Could not sync quiz attempts.';
        notifyListeners();
      },
    );
  }

  Future<void> loadDashboard() async {
    if (_userId == null) {
      return;
    }

    if (_exams.isNotEmpty && _activeExamId == null) {
      _activeExamId = _exams.first.id;
      notifyListeners();
    }
  }

  Future<bool> saveExamPlan({
    String? examId,
    required String subject,
    required String examName,
    required String studyLevel,
    required String examType,
    required DateTime examDate,
    required String difficulty,
    required List<String> topics,
    required List<String> weakAreas,
    required int targetScore,
    String? notes,
  }) async {
    if (_userId == null) {
      _errorMessage = 'You must be signed in to create an exam.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final now = DateTime.now();
      final existingExam = examId == null
          ? null
          : _exams.where((exam) => exam.id == examId).firstOrNull;
      final normalizedTopics = topics
          .map((topic) => topic.trim())
          .where((topic) => topic.isNotEmpty)
          .toSet()
          .toList();
      final normalizedWeakAreas = weakAreas
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();
      final knowledgeByTopic = await _knowledgeService.fetchTopicKnowledge(
        subject: subject,
        topics: normalizedTopics,
      );
      final topicModels = normalizedTopics.asMap().entries.map((entry) {
        final knowledge = knowledgeByTopic[entry.value];
        final existingTopic = existingExam?.topics
            .where((topic) => topic.title.toLowerCase() == entry.value.toLowerCase())
            .firstOrNull;
        final normalizedTitle = entry.value.toLowerCase();
        final isWeakArea = normalizedWeakAreas.any((item) {
          final normalizedWeakArea = item.toLowerCase();
          return normalizedWeakArea.contains(normalizedTitle) || normalizedTitle.contains(normalizedWeakArea);
        });
        return (existingTopic ??
            StudyTopic(
              id: _uuid.v4(),
              title: entry.value,
              importance: isWeakArea ? 3 : (entry.key < 2 ? 2 : 1),
            ))
            .copyWith(
              importance: isWeakArea ? 3 : (existingTopic?.importance ?? (entry.key < 2 ? 2 : 1)),
              referenceSummary: knowledge?.summary ?? existingTopic?.referenceSummary,
              referenceTitle: knowledge?.pageTitle ?? existingTopic?.referenceTitle,
              referenceUrl: knowledge?.sourceUrl ?? existingTopic?.referenceUrl,
            );
      }).toList();

      final exam = Exam(
        id: existingExam?.id ?? _uuid.v4(),
        userId: _userId!,
        title: examName,
        subject: subject,
        studyLevel: studyLevel,
        examType: examType,
        examDate: examDate,
        targetScore: targetScore,
        difficulty: difficulty,
        topics: topicModels,
        weakAreas: normalizedWeakAreas,
        createdAt: existingExam?.createdAt ?? now,
        updatedAt: now,
        notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      );

      final content = _generator.buildPlan(exam: exam);
      if (existingExam == null) {
        await _repository.saveGeneratedPlan(
          exam: exam,
          tasks: content.tasks,
          flashcards: content.flashcards,
        );
      } else {
        await _repository.updateExam(exam);
        await _repository.replaceTasksForExam(
          examId: exam.id,
          tasks: content.tasks,
        );
        await _repository.replaceFlashcardsForExam(
          examId: exam.id,
          flashcards: content.flashcards,
        );
      }
      _activeExamId = exam.id;
      return true;
    } catch (_) {
      _errorMessage = 'Could not save the exam and study plan. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteExam(String examId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _repository.deleteExam(examId);
      if (_activeExamId == examId) {
        _activeExamId = _exams.where((exam) => exam.id != examId).firstOrNull?.id;
      }
    } catch (_) {
      _errorMessage = 'Could not delete the exam.';
    } finally {
      _setLoading(false);
    }
  }

  void setActiveExam(String examId) {
    _activeExamId = examId;
    notifyListeners();
  }

  Future<void> toggleTask(String taskId) async {
    final task = tasks.where((item) => item.id == taskId).firstOrNull;
    if (task == null) {
      return;
    }

    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: task.isCompleted ? null : DateTime.now(),
      clearCompletedAt: task.isCompleted,
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.updateTask(updatedTask);
    } catch (_) {
      _errorMessage = 'Could not update task completion.';
      notifyListeners();
    }
  }

  Future<bool> saveTaskDraft({
    String? taskId,
    required String title,
    required String description,
    required String topicTitle,
    required String taskType,
    required DateTime scheduledFor,
    required int estimatedMinutes,
  }) async {
    final exam = activeExam;
    if (_userId == null || exam == null) {
      _errorMessage = 'Create or select an exam before adding study tasks.';
      notifyListeners();
      return false;
    }

    try {
      final topic = await _ensureTopic(topicTitle);
      final existingTask = taskId == null
          ? null
          : tasks.where((task) => task.id == taskId).firstOrNull;
      final now = DateTime.now();

      final task = StudyTask(
        id: existingTask?.id ?? _uuid.v4(),
        userId: _userId!,
        examId: exam.id,
        topicId: topic.id,
        topicTitle: topic.title,
        title: title.trim(),
        description: description.trim(),
        taskType: taskType.trim(),
        scheduledFor: _normalize(scheduledFor),
        estimatedMinutes: estimatedMinutes,
        isCompleted: existingTask?.isCompleted ?? false,
        createdAt: existingTask?.createdAt ?? now,
        updatedAt: now,
        completedAt: existingTask?.completedAt,
      );

      await _repository.updateTask(task);
      return true;
    } catch (_) {
      _errorMessage = 'Could not save the study task.';
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _repository.deleteTask(taskId);
    } catch (_) {
      _errorMessage = 'Could not delete the study task.';
      notifyListeners();
    }
  }

  Future<bool> saveFlashcardDraft({
    String? flashcardId,
    required String topicTitle,
    required String front,
    required String back,
  }) async {
    final exam = activeExam;
    if (_userId == null || exam == null) {
      _errorMessage = 'Create or select an exam before adding flashcards.';
      notifyListeners();
      return false;
    }

    try {
      final topic = await _ensureTopic(topicTitle);
      final existingCard = flashcardId == null
          ? null
          : flashcards.where((card) => card.id == flashcardId).firstOrNull;
      final now = DateTime.now();

      final flashcard = Flashcard(
        id: existingCard?.id ?? _uuid.v4(),
        userId: _userId!,
        examId: exam.id,
        topicId: topic.id,
        topicTitle: topic.title,
        front: front.trim(),
        back: back.trim(),
        masteryLevel: existingCard?.masteryLevel ?? 0,
        createdAt: existingCard?.createdAt ?? now,
        updatedAt: now,
      );

      await _repository.saveFlashcard(flashcard);
      return true;
    } catch (_) {
      _errorMessage = 'Could not save the flashcard.';
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteFlashcard(String flashcardId) async {
    try {
      await _repository.deleteFlashcard(flashcardId);
    } catch (_) {
      _errorMessage = 'Could not delete the flashcard.';
      notifyListeners();
    }
  }

  Future<void> reviewFlashcard(String flashcardId, {required bool mastered}) async {
    final flashcard = flashcards.where((item) => item.id == flashcardId).firstOrNull;
    if (flashcard == null) {
      return;
    }

    final nextLevel = mastered
        ? (flashcard.masteryLevel + 1).clamp(0, 5)
        : (flashcard.masteryLevel - 1).clamp(0, 5);

    await _repository.saveFlashcard(
      flashcard.copyWith(
        masteryLevel: nextLevel,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> loadFlashcardsForSubject(
    String subject, {
    List<String> topics = const <String>[],
  }) async {
    final matchingExam = _exams.where((exam) => exam.subject == subject).firstOrNull;
    if (matchingExam != null) {
      _activeExamId = matchingExam.id;
      notifyListeners();
      return;
    }

    if (topics.isNotEmpty) {
      final matchingByTopic = _exams
          .where((exam) => exam.topics.any((topic) => topics.contains(topic.title)))
          .firstOrNull;
      if (matchingByTopic != null) {
        _activeExamId = matchingByTopic.id;
        notifyListeners();
      }
    }
  }

  List<QuizQuestion> buildQuizQuestions({
    List<String> focusTopics = const <String>[],
  }) {
    final exam = activeExam;
    if (exam == null) {
      return const <QuizQuestion>[];
    }

    return _generator.buildQuizQuestions(
      exam: exam,
      focusTopics: focusTopics,
    );
  }

  List<QuizQuestion> buildQuizQuestionsForExam(
    String examId, {
    List<String> focusTopics = const <String>[],
  }) {
    final exam = examById(examId);
    if (exam == null) {
      return const <QuizQuestion>[];
    }

    return _generator.buildQuizQuestions(
      exam: exam,
      focusTopics: focusTopics,
    );
  }

  Future<void> recordQuizAttempt({
    required int correctAnswers,
    required int totalQuestions,
    required List<String> weakTopics,
  }) async {
    if (_userId == null || activeExam == null) {
      return;
    }

    final score = totalQuestions == 0 ? 0 : ((correctAnswers / totalQuestions) * 100).round();
    final attempt = QuizAttempt(
      id: _uuid.v4(),
      userId: _userId!,
      examId: activeExam!.id,
      scorePercent: score,
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      weakTopics: List<String>.from(weakTopics),
      attemptedAt: DateTime.now(),
    );

    try {
      await _repository.saveQuizAttempt(attempt);
    } catch (_) {
      _errorMessage = 'Could not record the quiz attempt.';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _exams = <Exam>[];
    _allTasks = <StudyTask>[];
    _allFlashcards = <Flashcard>[];
    _allQuizAttempts = <QuizAttempt>[];
    _activeExamId = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  int get completedTasksCount => tasks.where((task) => task.isCompleted).length;

  int get totalStudyMinutes => tasks
      .where((task) => task.isCompleted)
      .fold<int>(0, (sum, task) => sum + task.estimatedMinutes);

  int get todayPlannedMinutes => todayTasks.fold<int>(0, (sum, task) => sum + task.estimatedMinutes);

  int get todayCompletedMinutes => todayTasks
      .where((task) => task.isCompleted)
      .fold<int>(0, (sum, task) => sum + task.estimatedMinutes);

  Map<DateTime, List<StudyTask>> get tasksByDate {
    final grouped = SplayTreeMap<DateTime, List<StudyTask>>();
    for (final task in tasks) {
      final date = _normalize(task.scheduledFor);
      grouped.putIfAbsent(date, () => <StudyTask>[]).add(task);
    }
    return grouped;
  }

  ProgressStats get progressStats {
    final totalTasks = tasks.length;
    final completedTasks = completedTasksCount;
    final topicCompletion = _topicCompletionRatios();
    final attempts = quizAttempts;
    final completedTopics = topicCompletion.values.where((ratio) => ratio >= 0.75).length;
    final weakTopics = <String>[
      ...topicCompletion.entries.where((entry) => entry.value < 0.55).map((entry) => entry.key),
      ...attempts.expand((attempt) => attempt.weakTopics),
      ...?activeExam?.weakAreas,
    ].fold<List<String>>(<String>[], (items, topic) {
      if (!items.contains(topic)) {
        items.add(topic);
      }
      return items;
    }).take(3).toList();

    final weekStart = _normalize(DateTime.now()).subtract(const Duration(days: 6));
    final weeklyMinutes = List<int>.generate(7, (index) {
      final day = weekStart.add(Duration(days: index));
      return tasks
          .where((task) {
            final completionDay = _normalize(task.completedAt ?? task.scheduledFor);
            return task.isCompleted && completionDay == day;
          })
          .fold<int>(0, (sum, task) => sum + task.estimatedMinutes);
    });

    final averageQuizScore = attempts.isEmpty
        ? 0
        : (attempts.fold<int>(0, (sum, item) => sum + item.scorePercent) / attempts.length).round();

    return ProgressStats(
      progressPercent: totalTasks == 0 ? 0 : completedTasks / totalTasks,
      completedTasks: completedTasks,
      totalTasks: totalTasks,
      completedTopics: completedTopics,
      totalTopics: activeExam?.topics.length ?? 0,
      weakTopics: weakTopics,
      streakDays: _calculateStreakDays(),
      totalStudyMinutes: totalStudyMinutes,
      quizzesCompleted: attempts.length,
      averageQuizScore: averageQuizScore,
      weeklyMinutes: weeklyMinutes,
    );
  }

  Map<String, double> _topicCompletionRatios() {
    final totals = <String, int>{};
    final completed = <String, int>{};

    for (final task in tasks) {
      totals.update(task.topicTitle, (value) => value + 1, ifAbsent: () => 1);
      if (task.isCompleted) {
        completed.update(task.topicTitle, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    final ratios = <String, double>{};
    for (final topic in totals.keys) {
      ratios[topic] = (completed[topic] ?? 0) / totals[topic]!;
    }
    return ratios;
  }

  int _calculateStreakDays() {
    final completedDays = tasks
        .where((task) => task.isCompleted)
        .map((task) => _normalize(task.completedAt ?? task.scheduledFor))
        .toSet();

    var streak = 0;
    var cursor = _normalize(DateTime.now());

    while (completedDays.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  Future<StudyTopic> _ensureTopic(String title) async {
    final exam = activeExam!;
    final trimmed = title.trim();

    final existing = exam.topics
        .where((topic) => topic.title.toLowerCase() == trimmed.toLowerCase())
        .firstOrNull;
    if (existing != null) {
      return existing;
    }

    final topic = StudyTopic(
      id: _uuid.v4(),
      title: trimmed,
      importance: 1,
    );

    final updatedExam = exam.copyWith(
      topics: [...exam.topics, topic],
      updatedAt: DateTime.now(),
    );
    await _repository.updateExam(updatedExam);
    return topic;
  }

  DateTime _normalize(DateTime value) => DateTime(value.year, value.month, value.day);

  Future<void> _cancelSubscriptions() async {
    await _examSubscription?.cancel();
    await _taskSubscription?.cancel();
    await _flashcardSubscription?.cancel();
    await _attemptSubscription?.cancel();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
