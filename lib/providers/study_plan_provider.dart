import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../models/topic_knowledge.dart';
import '../models/topic_search_result.dart';
import '../services/study_material_parser.dart';
import '../services/study_personalization_service.dart';
import '../services/study_plan_generator.dart';
import '../services/topic_knowledge_service.dart';

class StudyPlanProvider extends ChangeNotifier {
  StudyPlanProvider(
    this._repository, {
    StudyPlanGenerator? generator,
    TopicKnowledgeService? knowledgeService,
    StudyPersonalizationService? personalizationService,
    Uuid? uuid,
  })  : _generator = generator ?? StudyPlanGenerator(),
         _knowledgeService = knowledgeService ?? TopicKnowledgeService(),
         _personalizationService = personalizationService ?? const StudyPersonalizationService(),
         _uuid = uuid ?? const Uuid();

  final StudyRepository _repository;
  final StudyPlanGenerator _generator;
  final TopicKnowledgeService _knowledgeService;
  final StudyPersonalizationService _personalizationService;
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
  final Map<String, List<TopicSearchResult>> _topicSearchResults = <String, List<TopicSearchResult>>{};
  final Set<String> _loadingTopicSearchKeys = <String>{};
  final Map<String, String> _topicSearchErrors = <String, String>{};

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
    final exam = activeExam;
    if (exam == null) {
      return const <StudyTask>[];
    }

    final normalizedTopic = _normalizedTopicKey(
      subject: exam.subject,
      topicTitle: topicTitle,
    );
    final filteredTasks = tasks
        .where(
          (task) => _normalizedTopicKey(
            subject: exam.subject,
            topicTitle: task.topicTitle,
          ) ==
              normalizedTopic,
        )
        .toList();
    filteredTasks.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    return filteredTasks;
  }

  List<Flashcard> flashcardsForTopic(String topicTitle) {
    final exam = activeExam;
    if (exam == null) {
      return const <Flashcard>[];
    }

    final normalizedTopic = _normalizedTopicKey(
      subject: exam.subject,
      topicTitle: topicTitle,
    );
    final filteredCards = flashcards
        .where(
          (card) => _normalizedTopicKey(
            subject: exam.subject,
            topicTitle: card.topicTitle,
          ) ==
              normalizedTopic,
        )
        .toList();
    filteredCards.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return filteredCards;
  }

  StudyTopic? topicForTitle(String topicTitle) {
    final exam = activeExam;
    if (exam == null) {
      return null;
    }

    final normalizedTopic = _normalizedTopicKey(
      subject: exam.subject,
      topicTitle: topicTitle,
    );
    return exam.topics
        .where(
          (topic) => _normalizedTopicKey(
            subject: exam.subject,
            topicTitle: topic.title,
          ) ==
              normalizedTopic,
        )
        .firstOrNull;
  }

  String? topicSummaryFor(String topicTitle) {
    final exam = activeExam;
    if (exam == null) {
      return null;
    }

    final personalizedExam = _personalizedExam(
      exam,
      highlightedTopic: topicTitle,
    );
    final topic = _topicForExam(
      personalizedExam,
      topicTitle,
    );
    if (topic == null) {
      return null;
    }

    final mistakeCount = _personalizationService.mistakeCountForTopic(
      subject: personalizedExam.subject,
      topicTitle: topicTitle,
      attempts: attemptsForExam(personalizedExam.id),
    );
    final intro = _personalizationService.simplificationIntro(
      topicTitle: StudyMaterialParser.normalizeTopicTitle(
        subject: personalizedExam.subject,
        topic: topicTitle,
      ),
      mistakeCount: mistakeCount,
    );
    final note = _generator.buildTopicCoachNote(
      exam: personalizedExam,
      topic: topic,
    );

    return intro.isEmpty ? note : '$intro\n\n$note';
  }

  List<TopicSearchResult> topicSearchResultsFor(String topicTitle) {
    final exam = activeExam;
    if (exam == null) {
      return const <TopicSearchResult>[];
    }

    final key = _topicSearchCacheKey(
      subject: exam.subject,
      topicTitle: topicTitle,
    );
    return List<TopicSearchResult>.unmodifiable(
      _topicSearchResults[key] ?? const <TopicSearchResult>[],
    );
  }

  bool isTopicSearchLoading(String topicTitle) {
    final exam = activeExam;
    if (exam == null) {
      return false;
    }

    return _loadingTopicSearchKeys.contains(
      _topicSearchCacheKey(
        subject: exam.subject,
        topicTitle: topicTitle,
      ),
    );
  }

  String? topicSearchErrorFor(String topicTitle) {
    final exam = activeExam;
    if (exam == null) {
      return null;
    }

    return _topicSearchErrors[
      _topicSearchCacheKey(
        subject: exam.subject,
        topicTitle: topicTitle,
      )
    ];
  }

  Future<void> loadTopicSearchResults(
    String topicTitle, {
    bool forceRefresh = false,
  }) async {
    final exam = activeExam;
    if (exam == null) {
      return;
    }

    final key = _topicSearchCacheKey(
      subject: exam.subject,
      topicTitle: topicTitle,
    );
    if (!forceRefresh && _topicSearchResults.containsKey(key) && _topicSearchResults[key]!.isNotEmpty) {
      return;
    }
    if (_loadingTopicSearchKeys.contains(key)) {
      return;
    }

    _loadingTopicSearchKeys.add(key);
    _topicSearchErrors.remove(key);
    notifyListeners();

    try {
      final results = await _knowledgeService.searchTopicResults(
        subject: exam.subject,
        topic: topicTitle,
      );
      _topicSearchResults[key] = results;
    } catch (_) {
      _topicSearchErrors[key] = 'Could not load internet results for this topic right now.';
    } finally {
      _loadingTopicSearchKeys.remove(key);
      notifyListeners();
    }
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
    _topicSearchResults.clear();
    _loadingTopicSearchKeys.clear();
    _topicSearchErrors.clear();

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
      final normalizedNotes = StudyMaterialParser.normalizeImportedText(notes ?? '');
      final suggestedTopics = StudyMaterialParser.extractTopics(
        subject: subject,
        content: normalizedNotes,
        maxTopics: topics.isEmpty ? 10 : 6,
      );
      final normalizedTopics = topics
          .map(
            (topic) => StudyMaterialParser.normalizeTopicTitle(
              subject: subject,
              topic: topic.trim(),
            ),
          )
          .where((topic) => topic.isNotEmpty)
          .toSet()
          .toList();
      for (final topic in suggestedTopics) {
        final normalizedTopic = StudyMaterialParser.normalizeTopicTitle(
          subject: subject,
          topic: topic,
        );
        if (normalizedTopic.isEmpty) {
          continue;
        }
        final alreadyAdded = normalizedTopics.any(
          (existingTopic) => existingTopic.toLowerCase() == normalizedTopic.toLowerCase(),
        );
        if (!alreadyAdded) {
          normalizedTopics.add(normalizedTopic);
        }
      }
      final normalizedWeakAreas = weakAreas
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();
      final knowledgeByTopic = await _loadKnowledgeSafely(
        subject: subject,
        topics: normalizedTopics,
      );
      final topicModels = normalizedTopics.asMap().entries.map((entry) {
        final knowledge = knowledgeByTopic[entry.value];
        final existingTopic = existingExam?.topics
            .where((topic) => topic.title.toLowerCase() == entry.value.toLowerCase())
            .firstOrNull;
        final materialSummary = StudyMaterialParser.excerptForTopic(
          topic: entry.value,
          content: normalizedNotes,
        );
        final normalizedTitle = entry.value.toLowerCase();
        final isWeakArea = normalizedWeakAreas.any((item) {
          final normalizedWeakArea = item.toLowerCase();
          return normalizedWeakArea.contains(normalizedTitle) || normalizedTitle.contains(normalizedWeakArea);
        });
        final baseTopic = existingTopic ??
            StudyTopic(
              id: _uuid.v4(),
              title: entry.value,
              importance: isWeakArea ? 3 : (entry.key < 2 ? 2 : 1),
            );
        return StudyTopic(
          id: baseTopic.id,
          title: baseTopic.title,
          importance: isWeakArea ? 3 : (existingTopic?.importance ?? (entry.key < 2 ? 2 : 1)),
          referenceSummary: materialSummary ?? knowledge?.summary ?? baseTopic.referenceSummary,
          referenceTitle: knowledge?.pageTitle ??
              baseTopic.referenceTitle ??
              (materialSummary == null ? null : 'Your study materials'),
          referenceUrl: knowledge?.sourceUrl ?? baseTopic.referenceUrl,
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
        notes: normalizedNotes.isEmpty ? null : normalizedNotes,
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
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('saveExamPlan Firebase error [${error.code}]: ${error.message}\n$stackTrace');
      _errorMessage = _friendlySaveError(error);
      return false;
    } catch (error, stackTrace) {
      debugPrint('saveExamPlan error: $error\n$stackTrace');
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
      final normalizedTopics = topics
          .map(
            (topic) => StudyMaterialParser.normalizeTopicTitle(
              subject: subject,
              topic: topic,
            ).toLowerCase(),
          )
          .where((topic) => topic.isNotEmpty)
          .toSet();
      final matchingByTopic = _exams
          .where(
            (exam) => exam.topics.any(
              (topic) => normalizedTopics.contains(
                StudyMaterialParser.normalizeTopicTitle(
                  subject: exam.subject,
                  topic: topic.title,
                ).toLowerCase(),
              ),
            ),
          )
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

    final personalizedExam = _personalizedExam(exam);
    return _generator.buildQuizQuestions(
      exam: personalizedExam,
      focusTopics: focusTopics
          .map(
            (topic) => StudyMaterialParser.normalizeTopicTitle(
              subject: personalizedExam.subject,
              topic: topic,
            ),
          )
          .where((topic) => topic.isNotEmpty)
          .toList(),
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

    final personalizedExam = _personalizedExam(exam);
    return _generator.buildQuizQuestions(
      exam: personalizedExam,
      focusTopics: focusTopics
          .map(
            (topic) => StudyMaterialParser.normalizeTopicTitle(
              subject: personalizedExam.subject,
              topic: topic,
            ),
          )
          .where((topic) => topic.isNotEmpty)
          .toList(),
    );
  }

  Future<void> recordQuizAttempt({
    required int correctAnswers,
    required int totalQuestions,
    required List<String> weakTopics,
  }) async {
    final exam = activeExam;
    if (_userId == null || exam == null) {
      return;
    }

    final normalizedWeakTopics = weakTopics
        .map(
          (topic) => StudyMaterialParser.normalizeTopicTitle(
            subject: exam.subject,
            topic: topic,
          ),
        )
        .where((topic) => topic.isNotEmpty)
        .toSet()
        .toList();
    final score = totalQuestions == 0 ? 0 : ((correctAnswers / totalQuestions) * 100).round();
    final attempt = QuizAttempt(
      id: _uuid.v4(),
      userId: _userId!,
      examId: exam.id,
      scorePercent: score,
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      weakTopics: List<String>.from(normalizedWeakTopics),
      attemptedAt: DateTime.now(),
    );

    try {
      await _repository.saveQuizAttempt(attempt);
      _allQuizAttempts = <QuizAttempt>[
        attempt,
        ..._allQuizAttempts.where((item) => item.id != attempt.id),
      ];
      final personalizedExam = _personalizedExam(
        exam,
        latestWeakTopics: normalizedWeakTopics,
      );
      final updatedExam = exam.copyWith(
        topics: personalizedExam.topics,
        weakAreas: personalizedExam.weakAreas,
        updatedAt: DateTime.now(),
      );
      await _repository.updateExam(updatedExam);
      _replaceExamInMemory(updatedExam);
      await _scheduleRecoveryTasks(
        exam: updatedExam,
        weakTopics: normalizedWeakTopics,
      );
      notifyListeners();
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
    _topicSearchResults.clear();
    _loadingTopicSearchKeys.clear();
    _topicSearchErrors.clear();
    _activeExamId = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  int get completedTasksCount => tasks.where((task) => task.isCompleted).length;

  int get totalStudyMinutes => tasks
      .where((task) => task.isCompleted)
      .fold<int>(0, (totalMinutes, task) => totalMinutes + task.estimatedMinutes);

  int get todayPlannedMinutes =>
      todayTasks.fold<int>(0, (totalMinutes, task) => totalMinutes + task.estimatedMinutes);

  int get todayCompletedMinutes => todayTasks
      .where((task) => task.isCompleted)
      .fold<int>(0, (totalMinutes, task) => totalMinutes + task.estimatedMinutes);

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
          .fold<int>(0, (totalMinutes, task) => totalMinutes + task.estimatedMinutes);
    });

    final averageQuizScore = attempts.isEmpty
        ? 0
        : (attempts.fold<int>(0, (totalScore, item) => totalScore + item.scorePercent) / attempts.length)
            .round();

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

  Exam _personalizedExam(
    Exam exam, {
    List<String> latestWeakTopics = const <String>[],
    String? highlightedTopic,
  }) {
    return _personalizationService.personalizeExam(
      exam: exam,
      attempts: attemptsForExam(exam.id),
      latestWeakTopics: latestWeakTopics,
      highlightedTopic: highlightedTopic,
    );
  }

  StudyTopic? _topicForExam(Exam exam, String topicTitle) {
    final normalizedTopic = _normalizedTopicKey(
      subject: exam.subject,
      topicTitle: topicTitle,
    );
    return exam.topics
        .where(
          (topic) => _normalizedTopicKey(
            subject: exam.subject,
            topicTitle: topic.title,
          ) ==
              normalizedTopic,
        )
        .firstOrNull;
  }

  String _normalizedTopicKey({
    required String subject,
    required String topicTitle,
  }) {
    return _personalizationService.normalizedTopicKey(
      subject: subject,
      topicTitle: topicTitle,
    );
  }

  String _topicSearchCacheKey({
    required String subject,
    required String topicTitle,
  }) {
    return '${subject.trim().toLowerCase()}::${_normalizedTopicKey(subject: subject, topicTitle: topicTitle)}';
  }

  Future<Map<String, TopicKnowledge>> _loadKnowledgeSafely({
    required String subject,
    required List<String> topics,
  }) async {
    try {
      return await _knowledgeService.fetchTopicKnowledge(
        subject: subject,
        topics: topics,
      );
    } catch (error, stackTrace) {
      debugPrint('Topic knowledge fallback for $subject: $error\n$stackTrace');
      return <String, TopicKnowledge>{};
    }
  }

  String _friendlySaveError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Firestore blocked the save. Make sure you are signed in and that the published rules allow your account to update exams.';
      case 'unavailable':
        return 'Could not reach Firebase right now. Check your internet connection and try saving again.';
      case 'failed-precondition':
        return 'Firebase still needs one setup step for this save. If it keeps happening, reopen the app and try again.';
      case 'resource-exhausted':
      case 'invalid-argument':
        return 'This exam has too much content to save at once. Shorten the pasted study materials a little and try again.';
      default:
        final message = error.message?.trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
        return 'Could not save the exam and study plan. Please try again.';
    }
  }

  void _replaceExamInMemory(Exam exam) {
    final index = _exams.indexWhere((item) => item.id == exam.id);
    if (index == -1) {
      _exams.add(exam);
    } else {
      _exams[index] = exam;
    }
  }

  void _upsertTaskInMemory(StudyTask task) {
    final index = _allTasks.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      _allTasks.add(task);
    } else {
      _allTasks[index] = task;
    }
  }

  Future<void> _scheduleRecoveryTasks({
    required Exam exam,
    required List<String> weakTopics,
  }) async {
    if (weakTopics.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final today = _normalize(now);
    var dayOffset = 0;

    for (final weakTopic in weakTopics.take(2)) {
      final normalizedWeakTopic = _normalizedTopicKey(
        subject: exam.subject,
        topicTitle: weakTopic,
      );
      if (normalizedWeakTopic.isEmpty) {
        continue;
      }

      final hasUpcomingTask = _allTasks.any((task) {
        if (task.examId != exam.id || task.isCompleted) {
          return false;
        }
        final sameTopic = _normalizedTopicKey(
              subject: exam.subject,
              topicTitle: task.topicTitle,
            ) ==
            normalizedWeakTopic;
        final isUpcoming = !_normalize(task.scheduledFor).isBefore(today);
        final isFocusedTask = task.taskType == 'review' ||
            task.taskType == 'quiz' ||
            task.taskType == 'study';
        return sameTopic && isUpcoming && isFocusedTask;
      });
      if (hasUpcomingTask) {
        continue;
      }

      final topic = _topicForExam(exam, weakTopic);
      if (topic == null) {
        continue;
      }

      final mistakeCount = _personalizationService.mistakeCountForTopic(
        subject: exam.subject,
        topicTitle: weakTopic,
        attempts: attemptsForExam(exam.id),
      );
      final displayTitle = StudyMaterialParser.normalizeTopicTitle(
        subject: exam.subject,
        topic: weakTopic,
      );
      final scheduledFor = today.add(Duration(days: dayOffset));
      dayOffset += 1;

      final task = StudyTask(
        id: _uuid.v4(),
        userId: exam.userId,
        examId: exam.id,
        topicId: topic.id,
        topicTitle: topic.title,
        title: 'Recovery review: $displayTitle',
        description: mistakeCount >= StudyPersonalizationService.repeatedMistakeThreshold
            ? 'You have repeated mistakes on $displayTitle. Start with the simpler explanation, list 3 key ideas, write the main formula or rule if one exists, and retry one easy quiz question before moving back to exam difficulty.'
            : 'You missed $displayTitle in the last quiz. Review the topic summary, write the main idea in your own words, and retry one short question to correct the mistake immediately.',
        taskType: 'review',
        scheduledFor: scheduledFor,
        estimatedMinutes:
            mistakeCount >= StudyPersonalizationService.repeatedMistakeThreshold ? 24 : 18,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );

      await _repository.updateTask(task);
      _upsertTaskInMemory(task);
    }
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
    final trimmed = StudyMaterialParser.normalizeTopicTitle(
      subject: exam.subject,
      topic: title,
    );

    final existing = exam.topics
        .where(
          (topic) => _normalizedTopicKey(
            subject: exam.subject,
            topicTitle: topic.title,
          ) ==
              _normalizedTopicKey(
                subject: exam.subject,
                topicTitle: trimmed,
              ),
        )
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
