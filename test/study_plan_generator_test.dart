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

  test('physics content stays subject-specific and avoids biology fallback text', () {
    final generator = StudyPlanGenerator();
    final exam = Exam(
      id: 'exam-physics',
      userId: 'user-1',
      title: 'Physics Final',
      subject: 'Physics',
      studyLevel: 'B2',
      examType: 'Final exam',
      examDate: DateTime.now().add(const Duration(days: 12)),
      targetScore: 90,
      difficulty: 'Advanced',
      topics: const [
        StudyTopic(
          id: 'topic-physics-1',
          title: 'Electric circuits',
          importance: 3,
        ),
      ],
      weakAreas: const ['Units'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final explanation = generator.buildTopicExplanation(
      exam: exam,
      topic: exam.topics.first,
    );
    final example = generator.buildTopicExample(
      exam: exam,
      topic: exam.topics.first,
    );
    final content = generator.buildPlan(exam: exam);

    expect(explanation.toLowerCase(), contains('physics'));
    expect(example.toLowerCase(), anyOf(contains('formula'), contains('unit')));
    expect(
      content.tasks.any(
        (task) => task.description.toLowerCase().contains('photosynthesis'),
      ),
      isFalse,
    );
    expect(
      content.tasks.any(
        (task) =>
            task.description.toLowerCase().contains('equation') ||
            task.description.toLowerCase().contains('unit'),
      ),
      isTrue,
    );
  });

  test('topic coach note uses the exact topic and the required A-F structure', () {
    final generator = StudyPlanGenerator();
    final exam = Exam(
      id: 'exam-thermo',
      userId: 'user-1',
      title: 'Physics Final',
      subject: 'Physics',
      studyLevel: 'B1',
      examType: 'School exam',
      examDate: DateTime.now().add(const Duration(days: 7)),
      targetScore: 88,
      difficulty: 'Balanced',
      topics: const [
        StudyTopic(
          id: 'topic-thermo',
          title: 'Physics: Thermodynamics',
          importance: 3,
        ),
      ],
      weakAreas: const ['Formula selection'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final note = generator.buildTopicCoachNote(
      exam: exam,
      topic: exam.topics.first,
    );

    expect(note, contains('A) Simple Explanation'));
    expect(note, contains('B) Key Concepts'));
    expect(note, contains('C) Important Formulas'));
    expect(note, contains('D) Real-life Example'));
    expect(note, contains('E) Quick Quiz'));
    expect(note, contains('F) Flashcards'));
    expect(note.toLowerCase(), contains('thermodynamics'));
    expect(note.toLowerCase(), isNot(contains('photosynthesis')));
    expect(note, contains('Q = mc x delta T'));
  });
}
