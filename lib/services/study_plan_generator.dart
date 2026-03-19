import 'dart:math';

import 'package:uuid/uuid.dart';

import '../models/exam.dart';
import '../models/flashcard.dart';
import '../models/quiz_question.dart';
import '../models/study_task.dart';
import '../models/study_topic.dart';

class GeneratedStudyContent {
  const GeneratedStudyContent({
    required this.tasks,
    required this.flashcards,
  });

  final List<StudyTask> tasks;
  final List<Flashcard> flashcards;
}

class StudyPlanGenerator {
  StudyPlanGenerator({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  GeneratedStudyContent buildPlan({
    required Exam exam,
  }) {
    final topics = _prioritizedTopics(exam);
    final now = DateTime.now();
    final flashcards = _buildFlashcards(exam: exam, topics: topics);
    final taskDrafts = <_TaskDraft>[
      for (final topic in topics) _TaskDraft(topic: topic, template: _studyTemplateFor(exam, topic)),
      if (topics.length > 1)
        _TaskDraft(
          topic: topics.first,
          template: _mixedRevisionTemplate(
            exam,
            title: 'Revision day',
            focusTopics: topics.take(min(3, topics.length)).map((topic) => topic.title).toList(),
          ),
        ),
      for (final topic in topics) _TaskDraft(topic: topic, template: _practiceTemplateFor(exam, topic)),
      for (final topic in topics) _TaskDraft(topic: topic, template: _flashcardTemplateFor(exam, topic)),
      for (final topic in topics.where((topic) => _isWeakTopic(exam, topic)))
        _TaskDraft(topic: topic, template: _weakAreaReviewTemplate(exam, topic)),
      _TaskDraft(
        topic: topics.first,
        template: _mixedRevisionTemplate(
          exam,
          title: 'Mock test',
          focusTopics: topics.take(min(4, topics.length)).map((topic) => topic.title).toList(),
        ),
      ),
    ];

    final startDate = _normalize(now);
    final lastStudyDate = exam.examDate.isAfter(startDate)
        ? _normalize(exam.examDate.subtract(const Duration(days: 1)))
        : startDate;
    final availableDays = max(lastStudyDate.difference(startDate).inDays + 1, 1);

    final tasks = taskDrafts.asMap().entries.map((entry) {
      final draft = entry.value;
      final scheduledIndex =
          _spreadIndex(index: entry.key, itemCount: taskDrafts.length, dayCount: availableDays);
      final scheduledDate = startDate.add(Duration(days: scheduledIndex));

      return StudyTask(
        id: _uuid.v4(),
        userId: exam.userId,
        examId: exam.id,
        topicId: draft.topic.id,
        topicTitle: draft.topic.title,
        title: '${draft.template.label}: ${draft.topic.title}',
        description: _buildTaskDescription(
          exam: exam,
          topic: draft.topic,
          template: draft.template,
        ),
        taskType: draft.template.type,
        scheduledFor: scheduledDate,
        estimatedMinutes: _minutesForTask(
          exam: exam,
          topic: draft.topic,
          template: draft.template,
        ),
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );
    }).toList()
      ..sort((first, second) => first.scheduledFor.compareTo(second.scheduledFor));

    return GeneratedStudyContent(tasks: tasks, flashcards: flashcards);
  }

  List<QuizQuestion> buildQuizQuestions({
    required Exam exam,
    List<String> focusTopics = const <String>[],
  }) {
    final sourceTopics = _quizTopics(
      exam: exam,
      focusTopics: focusTopics,
    );
    if (sourceTopics.isEmpty) {
      return const <QuizQuestion>[];
    }

    final selectedTopics = sourceTopics.take(sourceTopics.length == 1 ? 1 : min(3, sourceTopics.length)).toList();
    final questions = <QuizQuestion>[];

    for (var index = 0; index < selectedTopics.length; index += 1) {
      final topic = selectedTopics[index];
      questions
        ..add(_buildMultipleChoiceQuestion(exam: exam, topic: topic, pool: sourceTopics, index: index))
        ..add(_buildFillBlankQuestion(exam: exam, topic: topic, index: index))
        ..add(_buildTrueFalseQuestion(exam: exam, topic: topic, index: index));
    }

    var bonusIndex = 0;
    while (questions.length < 5) {
      final topic = selectedTopics[bonusIndex % selectedTopics.length];
      questions.add(_buildBonusQuestion(exam: exam, topic: topic, index: bonusIndex));
      bonusIndex += 1;
    }

    return questions.take(10).toList();
  }

  String buildTopicCoachNote({
    required Exam exam,
    required StudyTopic topic,
  }) {
    final explanation = buildTopicExplanation(exam: exam, topic: topic);
    final example = buildTopicExample(exam: exam, topic: topic);
    final reminder = _isWeakTopic(exam, topic)
        ? 'Review this topic again in a later session because you marked it as a weak area.'
        : 'Come back to this topic with a short quiz or flashcard review after your study block.';
    return 'Simple explanation: $explanation Example: $example Review reminder: $reminder';
  }

  String buildTopicExplanation({
    required Exam exam,
    required StudyTopic topic,
  }) {
    final reference = topic.referenceSummary?.trim();
    if (reference != null && reference.isNotEmpty) {
      final trimmed = reference.length > 150 ? '${reference.substring(0, 147).trimRight()}...' : reference;
      if (_usesSimpleLanguage(exam.studyLevel)) {
        return trimmed;
      }
      return '$trimmed Focus on the main idea, why it matters, and how it appears in ${exam.examType.toLowerCase()}.';
    }

    if (_usesSimpleLanguage(exam.studyLevel)) {
      return '${topic.title} is a core ${exam.subject.toLowerCase()} topic. Learn the meaning first, then practice one short example.';
    }

    return '${topic.title} is an exam-relevant ${exam.subject.toLowerCase()} concept. Be ready to define it, connect it to related ideas, and use it in a short answer.';
  }

  String buildTopicExample({
    required Exam exam,
    required StudyTopic topic,
  }) {
    if (exam.subject.toLowerCase() == 'english') {
      return 'Example: Use ${topic.title} in one sentence, then explain why it is correct.';
    }

    if (exam.subject.toLowerCase() == 'mathematics') {
      return 'Example: Solve one short ${topic.title.toLowerCase()} problem and explain each step aloud.';
    }

    if (exam.subject.toLowerCase() == 'physics' || exam.subject.toLowerCase() == 'chemistry') {
      return 'Example: Link ${topic.title} to one formula, process, or real-world scenario you can describe clearly.';
    }

    return 'Example: Explain ${topic.title} in simple words and connect it to one exam-style example.';
  }

  List<Flashcard> _buildFlashcards({
    required Exam exam,
    required List<StudyTopic> topics,
  }) {
    final now = DateTime.now();
    final cards = <Flashcard>[];
    final cardsPerTopic = switch (topics.length) {
      0 => 0,
      1 => 5,
      2 || 3 => 3,
      _ => 2,
    };

    for (final topic in topics) {
      if (cards.length >= 15) {
        break;
      }

      final explanation = buildTopicExplanation(exam: exam, topic: topic);
      final example = buildTopicExample(exam: exam, topic: topic);
      final sourceLabel = topic.referenceTitle == null ? '' : ' Source: ${topic.referenceTitle}.';

      final topicCards = <Flashcard>[
        Flashcard(
          id: _uuid.v4(),
          userId: exam.userId,
          examId: exam.id,
          topicId: topic.id,
          topicTitle: topic.title,
          front: 'What does ${topic.title} mean?',
          back: 'Definition: $explanation Example: $example$sourceLabel',
          masteryLevel: 0,
          createdAt: now,
          updatedAt: now,
        ),
        Flashcard(
          id: _uuid.v4(),
          userId: exam.userId,
          examId: exam.id,
          topicId: topic.id,
          topicTitle: topic.title,
          front: 'What should you remember about ${topic.title}?',
          back:
              'Key point: ${_oneLineKeyPoint(explanation)} Exam check: Explain ${topic.title} in your own words, then give one example.',
          masteryLevel: 0,
          createdAt: now,
          updatedAt: now,
        ),
        Flashcard(
          id: _uuid.v4(),
          userId: exam.userId,
          examId: exam.id,
          topicId: topic.id,
          topicTitle: topic.title,
          front: 'How might ${topic.title} appear in the exam?',
          back:
              'Practice prompt: Write a short answer on ${topic.title}. Then test yourself with one quiz question or recall drill.',
          masteryLevel: 0,
          createdAt: now,
          updatedAt: now,
        ),
        Flashcard(
          id: _uuid.v4(),
          userId: exam.userId,
          examId: exam.id,
          topicId: topic.id,
          topicTitle: topic.title,
          front: 'What is a common mistake in ${topic.title}?',
          back:
              'Avoid this: reviewing ${topic.title} only once. Revisit it later and compare your new answer with your first one.',
          masteryLevel: 0,
          createdAt: now,
          updatedAt: now,
        ),
        Flashcard(
          id: _uuid.v4(),
          userId: exam.userId,
          examId: exam.id,
          topicId: topic.id,
          topicTitle: topic.title,
          front: 'What is your next step after studying ${topic.title}?',
          back:
              'Next step: take a short quiz, check mistakes, and schedule a later review block for spaced repetition.',
          masteryLevel: 0,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      cards.addAll(topicCards.take(cardsPerTopic));
    }

    return cards.take(15).toList();
  }

  QuizQuestion _buildMultipleChoiceQuestion({
    required Exam exam,
    required StudyTopic topic,
    required List<StudyTopic> pool,
    required int index,
  }) {
    final explanation = buildTopicExplanation(exam: exam, topic: topic);
    final options = <String>[
      topic.title,
      ...pool
          .where((candidate) => candidate.id != topic.id)
          .map((candidate) => candidate.title)
          .take(3),
    ];

    while (options.length < 4) {
      options.add('${exam.subject} review ${options.length}');
    }

    final shuffledOptions = List<String>.from(options)..shuffle();

    return QuizQuestion(
      id: _uuid.v4(),
      examId: exam.id,
      topicId: topic.id,
      topicTitle: topic.title,
      subject: exam.subject,
      type: QuizQuestionType.multipleChoice,
      question: 'Choose the correct topic for this explanation: "$explanation"',
      options: shuffledOptions,
      correctAnswer: topic.title,
      acceptedAnswers: [topic.title],
      explanation:
          '${topic.title} is correct because it matches the explanation for this topic. After choosing it, try to explain it again without looking.',
      example: buildTopicExample(exam: exam, topic: topic),
      difficultyLabel: index == 0 ? 'Easy' : 'Medium',
    );
  }

  QuizQuestion _buildFillBlankQuestion({
    required Exam exam,
    required StudyTopic topic,
    required int index,
  }) {
    return QuizQuestion(
      id: _uuid.v4(),
      examId: exam.id,
      topicId: topic.id,
      topicTitle: topic.title,
      subject: exam.subject,
      type: QuizQuestionType.fillBlank,
      question:
          'Fill in the blank: In your ${exam.examType.toLowerCase()}, ______ is one of the topics you should explain clearly and support with one example.',
      options: const <String>[],
      correctAnswer: topic.title,
      acceptedAnswers: [topic.title, topic.title.toLowerCase()],
      explanation:
          'The missing answer is ${topic.title}. Strong exam answers define the topic first and then connect it to one example or application.',
      example: buildTopicExample(exam: exam, topic: topic),
      hint: 'Use the topic name from your study plan.',
      difficultyLabel: index == 0 ? 'Easy' : 'Medium',
    );
  }

  QuizQuestion _buildTrueFalseQuestion({
    required Exam exam,
    required StudyTopic topic,
    required int index,
  }) {
    final isTrueStatement = index.isEven;
    final statement = isTrueStatement
        ? buildTopicExplanation(exam: exam, topic: topic)
        : 'You should leave ${topic.title} until the night before the exam and skip all review sessions.';

    return QuizQuestion(
      id: _uuid.v4(),
      examId: exam.id,
      topicId: topic.id,
      topicTitle: topic.title,
      subject: exam.subject,
      type: QuizQuestionType.trueFalse,
      question: 'True or False: $statement',
      options: const ['True', 'False'],
      correctAnswer: isTrueStatement ? 'True' : 'False',
      acceptedAnswers: isTrueStatement ? const ['True', 'T'] : const ['False', 'F'],
      explanation: isTrueStatement
          ? 'True is correct because the statement describes the topic accurately in simple language.'
          : 'False is correct because difficult topics need spaced review, not last-minute cramming.',
      example: buildTopicExample(exam: exam, topic: topic),
      difficultyLabel: index == 0 ? 'Medium' : 'Hard',
    );
  }

  QuizQuestion _buildBonusQuestion({
    required Exam exam,
    required StudyTopic topic,
    required int index,
  }) {
    return QuizQuestion(
      id: _uuid.v4(),
      examId: exam.id,
      topicId: topic.id,
      topicTitle: topic.title,
      subject: exam.subject,
      type: QuizQuestionType.multipleChoice,
      question: 'What is the best next step after studying ${topic.title}?',
      options: const [
        'Do one short practice check and review mistakes',
        'Skip directly to a random new topic',
        'Stop without testing recall',
        'Read the same note again only once',
      ],
      correctAnswer: 'Do one short practice check and review mistakes',
      acceptedAnswers: const ['Do one short practice check and review mistakes'],
      explanation:
          'A quick practice check turns explanation into memory and helps you catch weak areas early.',
      example: buildTopicExample(exam: exam, topic: topic),
      difficultyLabel: index.isEven ? 'Medium' : 'Hard',
    );
  }

  String _buildTaskDescription({
    required Exam exam,
    required StudyTopic topic,
    required _TaskTemplate template,
  }) {
    final explanation = buildTopicExplanation(exam: exam, topic: topic);
    final example = buildTopicExample(exam: exam, topic: topic);
    final weakAreaLine = _isWeakTopic(exam, topic)
        ? ' This topic is marked as a weak area, so give it extra review time.'
        : '';
    return '${template.description.replaceAll('{topic}', topic.title)} Simple explanation: $explanation Example: $example$weakAreaLine';
  }

  List<StudyTopic> _prioritizedTopics(Exam exam) {
    final normalizedTopics = exam.topics.isEmpty
        ? [
            StudyTopic(
              id: _uuid.v4(),
              title: '${exam.subject} fundamentals',
              importance: 1,
            ),
          ]
        : List<StudyTopic>.from(exam.topics);

    normalizedTopics.sort((first, second) {
      final firstScore = first.importance + (_isWeakTopic(exam, first) ? 2 : 0);
      final secondScore = second.importance + (_isWeakTopic(exam, second) ? 2 : 0);
      return secondScore.compareTo(firstScore);
    });

    return normalizedTopics;
  }

  List<StudyTopic> _quizTopics({
    required Exam exam,
    required List<String> focusTopics,
  }) {
    final prioritized = _prioritizedTopics(exam);
    if (focusTopics.isEmpty) {
      return prioritized;
    }

    final normalizedFocusTopics = focusTopics.map((item) => item.trim().toLowerCase()).toSet();
    final filtered = prioritized
        .where((topic) => normalizedFocusTopics.contains(topic.title.trim().toLowerCase()))
        .toList();
    return filtered.isEmpty ? prioritized : filtered;
  }

  _TaskTemplate _studyTemplateFor(Exam exam, StudyTopic topic) {
    final label = _usesSimpleLanguage(exam.studyLevel) ? 'Simple explanation' : 'Concept study';
    return _TaskTemplate(
      label,
      'Explain {topic} in clear language, write the core idea, and add one example you can remember later.',
      'study',
      _usesSimpleLanguage(exam.studyLevel) ? 20 : 28,
    );
  }

  _TaskTemplate _practiceTemplateFor(Exam exam, StudyTopic topic) {
    final practiceLabel = exam.examType.toLowerCase().contains('ielts') ||
            exam.examType.toLowerCase().contains('toefl')
        ? 'Timed language practice'
        : 'Practice session';
    return _TaskTemplate(
      practiceLabel,
      'Complete 2-3 practice questions on {topic}, then check why each answer is right or wrong.',
      'quiz',
      exam.difficulty.toLowerCase() == 'advanced' ? 35 : 30,
    );
  }

  _TaskTemplate _flashcardTemplateFor(Exam exam, StudyTopic topic) {
    return _TaskTemplate(
      'Flashcard review',
      'Review the flashcards for {topic}, say the answer aloud, and mark the prompts that still feel weak.',
      'flashcards',
      _usesSimpleLanguage(exam.studyLevel) ? 15 : 18,
    );
  }

  _TaskTemplate _weakAreaReviewTemplate(Exam exam, StudyTopic topic) {
    return _TaskTemplate(
      'Weak area review',
      'Return to {topic}, reteach it in your own words, and repeat one short quiz to check improvement.',
      'review',
      25,
    );
  }

  _TaskTemplate _mixedRevisionTemplate(
    Exam exam, {
    required String title,
    required List<String> focusTopics,
  }) {
    final joinedTopics = focusTopics.join(', ');
    return _TaskTemplate(
      title,
      'Review $joinedTopics in one session, revisit mistakes, and finish with a short self-test before moving on.',
      'review',
      exam.difficulty.toLowerCase() == 'advanced' ? 40 : 32,
    );
  }

  int _minutesForTask({
    required Exam exam,
    required StudyTopic topic,
    required _TaskTemplate template,
  }) {
    var minutes = template.minutes + (topic.importance * 4);
    if (_isWeakTopic(exam, topic)) {
      minutes += 6;
    }
    if (exam.difficulty.toLowerCase() == 'advanced') {
      minutes += 4;
    }
    if (_usesSimpleLanguage(exam.studyLevel)) {
      minutes -= 3;
    }
    return minutes.clamp(15, 60);
  }

  bool _isWeakTopic(Exam exam, StudyTopic topic) => _isWeakTopicTitle(exam, topic.title);

  bool _isWeakTopicTitle(Exam exam, String topicTitle) {
    final normalizedTopic = topicTitle.trim().toLowerCase();
    return exam.weakAreas.any((weakArea) {
      final normalizedWeakArea = weakArea.trim().toLowerCase();
      return normalizedWeakArea.contains(normalizedTopic) || normalizedTopic.contains(normalizedWeakArea);
    });
  }

  bool _usesSimpleLanguage(String studyLevel) {
    final normalizedLevel = studyLevel.trim().toUpperCase();
    return normalizedLevel == 'A1' || normalizedLevel == 'A2' || normalizedLevel == 'B1';
  }

  String _oneLineKeyPoint(String explanation) {
    final firstSentence = explanation.split('.').first.trim();
    return firstSentence.isEmpty ? explanation : '$firstSentence.';
  }

  int _spreadIndex({
    required int index,
    required int itemCount,
    required int dayCount,
  }) {
    if (dayCount <= 1 || itemCount <= 1) {
      return 0;
    }

    return ((index * (dayCount - 1)) / (itemCount - 1)).round().clamp(0, dayCount - 1);
  }

  DateTime _normalize(DateTime value) => DateTime(value.year, value.month, value.day);
}

class _TaskDraft {
  const _TaskDraft({
    required this.topic,
    required this.template,
  });

  final StudyTopic topic;
  final _TaskTemplate template;
}

class _TaskTemplate {
  const _TaskTemplate(this.label, this.description, this.type, this.minutes);

  final String label;
  final String description;
  final String type;
  final int minutes;
}
