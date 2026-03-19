import 'package:flutter_test/flutter_test.dart';

import 'package:ai_study_coach/models/exam.dart';
import 'package:ai_study_coach/models/quiz_question.dart';
import 'package:ai_study_coach/models/study_topic.dart';
import 'package:ai_study_coach/services/study_plan_generator.dart';

void main() {
  test('study plan generator creates tasks, flashcards, and quiz questions', () {
    final generator = StudyPlanGenerator();
    final exam = Exam(
      id: 'exam-1',
      userId: 'user-1',
      title: 'Biology Midterm',
      subject: 'Biology',
      studyLevel: 'B1',
      examType: 'School exam',
      examDate: DateTime.now().add(const Duration(days: 10)),
      targetScore: 85,
      difficulty: 'Balanced',
      topics: const [
        StudyTopic(
          id: 'topic-1',
          title: 'Photosynthesis',
          importance: 2,
          referenceSummary: 'Photosynthesis converts light energy into chemical energy.',
          referenceTitle: 'Photosynthesis',
          referenceUrl: 'https://example.com/photosynthesis',
        ),
        StudyTopic(
          id: 'topic-2',
          title: 'Cell division',
          importance: 1,
        ),
      ],
      weakAreas: const ['Photosynthesis'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final content = generator.buildPlan(exam: exam);
    final questions = generator.buildQuizQuestions(exam: exam);

    expect(content.tasks, isNotEmpty);
    expect(content.flashcards, isNotEmpty);
    expect(questions, isNotEmpty);
    expect(
      questions.any((question) => question.type == QuizQuestionType.fillBlank),
      isTrue,
    );
    expect(
      questions.any((question) => question.type == QuizQuestionType.trueFalse),
      isTrue,
    );
    expect(
      content.tasks.any((task) => task.topicTitle == 'Photosynthesis'),
      isTrue,
    );
  });
}
