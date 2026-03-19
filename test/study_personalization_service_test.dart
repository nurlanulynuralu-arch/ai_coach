import 'package:flutter_test/flutter_test.dart';

import 'package:ai_study_coach/models/exam.dart';
import 'package:ai_study_coach/models/quiz_attempt.dart';
import 'package:ai_study_coach/models/study_topic.dart';
import 'package:ai_study_coach/services/study_personalization_service.dart';

void main() {
  const service = StudyPersonalizationService();

  final baseExam = Exam(
    id: 'exam-1',
    userId: 'user-1',
    title: 'Physics Final',
    subject: 'Physics',
    studyLevel: 'B2',
    examType: 'School exam',
    examDate: DateTime(2026, 5, 20),
    targetScore: 90,
    difficulty: 'Balanced',
    topics: const [
      StudyTopic(
        id: 'topic-1',
        title: 'Thermodynamics',
        importance: 1,
      ),
      StudyTopic(
        id: 'topic-2',
        title: 'Electric circuits',
        importance: 1,
      ),
    ],
    weakAreas: const ['Units'],
    createdAt: DateTime(2026, 3, 19),
    updatedAt: DateTime(2026, 3, 19),
  );

  test('repeated quiz mistakes trigger simpler support for a topic', () {
    final attempts = [
      QuizAttempt(
        id: 'attempt-1',
        userId: 'user-1',
        examId: 'exam-1',
        scorePercent: 50,
        correctAnswers: 2,
        totalQuestions: 4,
        weakTopics: const ['Physics: Thermodynamics'],
        attemptedAt: DateTime(2026, 3, 19),
      ),
      QuizAttempt(
        id: 'attempt-2',
        userId: 'user-1',
        examId: 'exam-1',
        scorePercent: 40,
        correctAnswers: 2,
        totalQuestions: 5,
        weakTopics: const ['Thermodynamics'],
        attemptedAt: DateTime(2026, 3, 20),
      ),
    ];

    expect(
      service.shouldSimplifyTopic(
        exam: baseExam,
        topicTitle: 'Thermodynamics',
        attempts: attempts,
      ),
      isTrue,
    );
  });

  test('personalized exam boosts weak topics and merges tracked weak areas', () {
    final attempts = [
      QuizAttempt(
        id: 'attempt-1',
        userId: 'user-1',
        examId: 'exam-1',
        scorePercent: 55,
        correctAnswers: 3,
        totalQuestions: 6,
        weakTopics: const ['Thermodynamics', 'Electric circuits'],
        attemptedAt: DateTime(2026, 3, 19),
      ),
      QuizAttempt(
        id: 'attempt-2',
        userId: 'user-1',
        examId: 'exam-1',
        scorePercent: 45,
        correctAnswers: 2,
        totalQuestions: 6,
        weakTopics: const ['Thermodynamics'],
        attemptedAt: DateTime(2026, 3, 20),
      ),
    ];

    final personalizedExam = service.personalizeExam(
      exam: baseExam,
      attempts: attempts,
      highlightedTopic: 'Thermodynamics',
    );

    expect(personalizedExam.studyLevel, 'A2');
    expect(personalizedExam.weakAreas.map((item) => item.toLowerCase()), contains('thermodynamics'));
    expect(personalizedExam.weakAreas.map((item) => item.toLowerCase()), contains('electric circuits'));
    expect(personalizedExam.weakAreas.map((item) => item.toLowerCase()), contains('units'));
    expect(
      personalizedExam.topics
          .firstWhere((topic) => topic.title == 'Thermodynamics')
          .importance,
      3,
    );
  });
}
