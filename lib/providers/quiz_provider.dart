import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/quiz_question.dart';

class QuizProvider extends ChangeNotifier {
  QuizProvider({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;
  bool _isLoading = false;
  bool _isSubmitted = false;
  List<QuizQuestion> _questions = <QuizQuestion>[];
  final Map<String, String> _selectedAnswers = <String, String>{};

  bool get isLoading => _isLoading;
  bool get isSubmitted => _isSubmitted;
  List<QuizQuestion> get questions => List<QuizQuestion>.unmodifiable(_questions);
  Map<String, String> get selectedAnswers => Map<String, String>.unmodifiable(_selectedAnswers);

  Future<void> loadFallbackQuestions({
    required String subject,
    List<String> topics = const <String>[],
  }) async {
    _isLoading = true;
    _isSubmitted = false;
    _selectedAnswers.clear();
    notifyListeners();

    final sourceTopics = topics.isEmpty ? <String>['Core concepts', 'Practice', 'Revision'] : topics;
    final generatedQuestions = <QuizQuestion>[];

    for (var index = 0; index < sourceTopics.length; index += 1) {
      final topic = sourceTopics[index];
      generatedQuestions
        ..add(
          QuizQuestion(
            id: _uuid.v4(),
            examId: 'ad-hoc-$subject',
            topicId: _uuid.v4(),
            topicTitle: topic,
            subject: subject,
            type: QuizQuestionType.multipleChoice,
            question: 'Which strategy best helps you remember $topic in $subject?',
            options: const [
              'Active recall and spaced repetition',
              'Studying once without testing',
              'Skipping weak topics',
              'Only reading headlines',
            ],
            correctAnswer: 'Active recall and spaced repetition',
            acceptedAnswers: const ['Active recall and spaced repetition'],
            explanation:
                'Active recall plus spaced repetition is the strongest memory loop for long-term retention.',
            example: 'Example: explain $topic, take a short quiz, then review it again later.',
            difficultyLabel: index == 0 ? 'Easy' : 'Medium',
          ),
        )
        ..add(
          QuizQuestion(
            id: _uuid.v4(),
            examId: 'ad-hoc-$subject',
            topicId: _uuid.v4(),
            topicTitle: topic,
            subject: subject,
            type: QuizQuestionType.fillBlank,
            question: 'Fill in the blank: After studying ______, your next step should be a short practice check.',
            options: const <String>[],
            correctAnswer: topic,
            acceptedAnswers: [topic, topic.toLowerCase()],
            explanation: 'The missing topic is $topic. A short practice check turns study time into real recall.',
            example: 'Example: review $topic, answer one question, and correct your mistake immediately.',
            hint: 'Use the topic you selected.',
            difficultyLabel: 'Easy',
          ),
        )
        ..add(
          QuizQuestion(
            id: _uuid.v4(),
            examId: 'ad-hoc-$subject',
            topicId: _uuid.v4(),
            topicTitle: topic,
            subject: subject,
            type: QuizQuestionType.trueFalse,
            question: 'True or False: $topic should appear again in a later review session if it feels difficult.',
            options: const ['True', 'False'],
            correctAnswer: 'True',
            acceptedAnswers: const ['True', 'T'],
            explanation: 'True is correct because spaced repetition helps difficult topics stay in memory.',
            example: 'Example: mark $topic as weak, then return to it in tomorrow\'s or next week\'s plan.',
            difficultyLabel: 'Medium',
          ),
        );
    }

    _questions = generatedQuestions.take(10).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadQuestionsForSubject({
    required String subject,
    List<String> topics = const <String>[],
  }) {
    return loadFallbackQuestions(subject: subject, topics: topics);
  }

  void setQuestions(List<QuizQuestion> questions) {
    _questions = questions
        .map(
          (question) => question.copyWith(
            options: List<String>.from(question.options),
            acceptedAnswers: List<String>.from(question.acceptedAnswers),
          ),
        )
        .toList();
    _isSubmitted = false;
    _isLoading = false;
    _selectedAnswers.clear();
    notifyListeners();
  }

  void selectOption(String questionId, String answer) {
    if (_isSubmitted) {
      return;
    }

    _selectedAnswers[questionId] = answer;
    notifyListeners();
  }

  void updateTextAnswer(String questionId, String value) {
    if (_isSubmitted) {
      return;
    }

    if (value.trim().isEmpty) {
      _selectedAnswers.remove(questionId);
    } else {
      _selectedAnswers[questionId] = value.trim();
    }
    notifyListeners();
  }

  void submitQuiz() {
    _isSubmitted = true;
    notifyListeners();
  }

  void resetQuiz() {
    _isSubmitted = false;
    _selectedAnswers.clear();
    notifyListeners();
  }

  String? answerFor(String questionId) => _selectedAnswers[questionId];

  bool isQuestionAnswered(QuizQuestion question) {
    final answer = _selectedAnswers[question.id];
    return answer != null && answer.trim().isNotEmpty;
  }

  bool isCorrect(QuizQuestion question) => question.matchesAnswer(_selectedAnswers[question.id]);

  int get correctAnswersCount {
    return _questions.where(isCorrect).length;
  }

  int get scorePercent {
    if (_questions.isEmpty) {
      return 0;
    }

    return ((correctAnswersCount / _questions.length) * 100).round();
  }

  List<String> get weakTopics {
    final incorrectTopics = <String>[];
    for (final question in _questions) {
      if (!isCorrect(question)) {
        incorrectTopics.add(question.topicTitle);
      }
    }
    return incorrectTopics.toSet().toList();
  }
}
