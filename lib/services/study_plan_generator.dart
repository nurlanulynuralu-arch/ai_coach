import 'dart:math';

import 'package:uuid/uuid.dart';

import '../core/constants/subject_content_catalog.dart';
import '../models/exam.dart';
import '../models/flashcard.dart';
import '../models/quiz_question.dart';
import '../models/study_task.dart';
import '../models/study_topic.dart';
import 'study_material_parser.dart';

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
      for (final topic in topics)
        _TaskDraft(topic: topic, template: _studyTemplateFor(exam, topic)),
      if (topics.length > 1)
        _TaskDraft(
          topic: topics.first,
          template: _mixedRevisionTemplate(
            exam,
            title: 'Revision day',
            focusTopics: topics.take(min(3, topics.length)).map((topic) => topic.title).toList(),
          ),
        ),
      for (final topic in topics)
        _TaskDraft(topic: topic, template: _practiceTemplateFor(exam, topic)),
      for (final topic in topics)
        _TaskDraft(topic: topic, template: _flashcardTemplateFor(exam, topic)),
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
      final scheduledIndex = _spreadIndex(
        index: entry.key,
        itemCount: taskDrafts.length,
        dayCount: availableDays,
      );
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

    final selectedTopics = sourceTopics
        .take(sourceTopics.length == 1 ? 1 : min(3, sourceTopics.length))
        .toList();
    final questions = <QuizQuestion>[];

    for (var index = 0; index < selectedTopics.length; index += 1) {
      final topic = selectedTopics[index];
      questions
        ..add(
          _buildMultipleChoiceQuestion(
            exam: exam,
            topic: topic,
            pool: sourceTopics,
            index: index,
          ),
        )
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
    final focusedTopic = _focusedTopicTitle(exam, topic);
    final explanation = buildTopicExplanation(exam: exam, topic: topic);
    final keyConcepts = _keyConceptsFor(
      exam: exam,
      topic: topic,
      explanation: explanation,
    );
    final formulas = _importantFormulasFor(exam: exam, topic: topic);
    final example = buildTopicExample(exam: exam, topic: topic);
    final quizQuestions = _quickQuizFor(
      topicTitle: focusedTopic,
      formulas: formulas,
    );
    final flashcards = _flashcardsFor(
      topicTitle: focusedTopic,
      explanation: explanation,
      keyConcepts: keyConcepts,
      formulas: formulas,
    );

    final buffer = StringBuffer()
      ..writeln('A) Simple Explanation')
      ..writeln(explanation)
      ..writeln()
      ..writeln('B) Key Concepts');

    for (final concept in keyConcepts) {
      buffer.writeln('- $concept');
    }

    buffer
      ..writeln()
      ..writeln('C) Important Formulas');

    if (formulas.isEmpty) {
      buffer.writeln(
        '- No single core formula for ${topic.title}. Focus on the main idea, key process, and how it appears in exam questions.',
      );
    } else {
      for (final formula in formulas) {
        buffer.writeln('- $formula');
      }
    }

    buffer
      ..writeln()
      ..writeln('D) Real-life Example')
      ..writeln('- $example')
      ..writeln()
      ..writeln('E) Quick Quiz');

    for (var index = 0; index < quizQuestions.length; index += 1) {
      buffer.writeln('${index + 1}. ${quizQuestions[index]}');
    }

    buffer
      ..writeln()
      ..writeln('F) Flashcards');

    for (final flashcard in flashcards) {
      buffer.writeln('- $flashcard');
    }

    return buffer.toString().trim();
  }

  String buildTopicExplanation({
    required Exam exam,
    required StudyTopic topic,
  }) {
    final simpleLanguage = _usesSimpleLanguage(exam.studyLevel);
    final focusedTopic = _focusedTopicTitle(exam, topic);
    final reference = topic.referenceSummary?.trim();
    if (reference != null && reference.isNotEmpty) {
      final trimmed =
          reference.length > 150 ? '${reference.substring(0, 147).trimRight()}...' : reference;
      if (trimmed.toLowerCase().contains(focusedTopic.toLowerCase())) {
        return trimmed;
      }
      return '$focusedTopic: $trimmed';
    }

    return SubjectContentCatalog.explanationFor(
      subject: exam.subject,
      topic: focusedTopic,
      simpleLanguage: simpleLanguage,
      examType: exam.examType,
    );
  }

  String buildTopicExample({
    required Exam exam,
    required StudyTopic topic,
  }) {
    return SubjectContentCatalog.exampleFor(
      subject: exam.subject,
      topic: _focusedTopicTitle(exam, topic),
    );
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

      final focusedTopic = _focusedTopicTitle(exam, topic);
      final explanation = buildTopicExplanation(exam: exam, topic: topic);
      final example = buildTopicExample(exam: exam, topic: topic);
      final coachingLine = SubjectContentCatalog.coachingLineFor(
        subject: exam.subject,
        topic: focusedTopic,
        simpleLanguage: _usesSimpleLanguage(exam.studyLevel),
        examType: exam.examType,
      );
      final sourceLabel = topic.referenceTitle == null ? '' : ' Source: ${topic.referenceTitle}.';

      final topicCards = <Flashcard>[
        Flashcard(
          id: _uuid.v4(),
          userId: exam.userId,
          examId: exam.id,
          topicId: topic.id,
          topicTitle: topic.title,
          front: 'What does $focusedTopic mean?',
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
          front: 'What should you remember about $focusedTopic?',
          back:
              'Key point: ${_oneLineKeyPoint(explanation)} Coach tip: $coachingLine Exam check: Explain $focusedTopic in your own words, then give one example.',
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
          front: 'How might $focusedTopic appear in the exam?',
          back:
              'Practice prompt: Write a short answer on $focusedTopic. Then test yourself with one quiz question or recall drill.',
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
          front: 'What is a common mistake in $focusedTopic?',
          back:
              'Avoid this: reviewing $focusedTopic only once. Revisit it later and compare your new answer with your first one.',
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
          front: 'What is your next step after studying $focusedTopic?',
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
    final focusedTopic = _focusedTopicTitle(exam, topic);
    final explanation = buildTopicExplanation(exam: exam, topic: topic);
    final options = <String>[
      focusedTopic,
      ...pool
          .where((candidate) => candidate.id != topic.id)
          .map((candidate) => _focusedTopicTitle(exam, candidate))
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
      correctAnswer: focusedTopic,
      acceptedAnswers: [
        focusedTopic,
        topic.title,
        topic.title.toLowerCase(),
      ],
      explanation:
          '$focusedTopic is correct because it matches the explanation for this topic. After choosing it, try to explain it again without looking.',
      example: buildTopicExample(exam: exam, topic: topic),
      difficultyLabel: index == 0 ? 'Easy' : 'Medium',
    );
  }

  QuizQuestion _buildFillBlankQuestion({
    required Exam exam,
    required StudyTopic topic,
    required int index,
  }) {
    final focusedTopic = _focusedTopicTitle(exam, topic);
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
      correctAnswer: focusedTopic,
      acceptedAnswers: [focusedTopic, topic.title, topic.title.toLowerCase()],
      explanation:
          'The missing answer is $focusedTopic. Strong exam answers define the topic first and then connect it to one example or application.',
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
    final focusedTopic = _focusedTopicTitle(exam, topic);
    final isTrueStatement = index.isEven;
    final statement = isTrueStatement
        ? buildTopicExplanation(exam: exam, topic: topic)
        : 'You should leave $focusedTopic until the night before the exam and skip all review sessions.';

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
    final focusedTopic = _focusedTopicTitle(exam, topic);
    return QuizQuestion(
      id: _uuid.v4(),
      examId: exam.id,
      topicId: topic.id,
      topicTitle: topic.title,
      subject: exam.subject,
      type: QuizQuestionType.multipleChoice,
      question: 'What is the best next step after studying $focusedTopic?',
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
    final focusedTopic = _focusedTopicTitle(exam, topic);
    final explanation = buildTopicExplanation(exam: exam, topic: topic);
    final example = buildTopicExample(exam: exam, topic: topic);
    final coachingLine = SubjectContentCatalog.coachingLineFor(
      subject: exam.subject,
      topic: focusedTopic,
      simpleLanguage: _usesSimpleLanguage(exam.studyLevel),
      examType: exam.examType,
    );
    final weakAreaLine = _isWeakTopic(exam, topic)
        ? ' This topic is marked as a weak area, so give it extra review time.'
        : '';
    return '${template.description.replaceAll('{topic}', topic.title)} Simple explanation: $explanation Coach tip: $coachingLine Example: $example$weakAreaLine';
  }

  List<String> _keyConceptsFor({
    required Exam exam,
    required StudyTopic topic,
    required String explanation,
  }) {
    final concepts = <String>[];
    final focusedTopic = _focusedTopicTitle(exam, topic);
    final reference = topic.referenceSummary?.trim();

    if (reference != null && reference.isNotEmpty) {
      concepts.add(_oneLineKeyPoint(reference));
    } else {
      concepts.add(_oneLineKeyPoint(explanation));
    }

    switch (exam.subject.toLowerCase()) {
      case 'physics':
        concepts
          ..add('Identify the law, variables, units, and assumptions linked to $focusedTopic.')
          ..add('Explain how $focusedTopic appears in calculations, graphs, or real systems.');
        break;
      case 'mathematics':
        concepts
          ..add('Know the method for $focusedTopic step by step, not just the final answer.')
          ..add('Check where signs, substitutions, algebra steps, or calculator use can go wrong.');
        break;
      case 'biology':
        concepts
          ..add('Describe the process, structures, and function involved in $focusedTopic.')
          ..add('Connect $focusedTopic to one organism, cell system, or exam-style example.');
        break;
      case 'chemistry':
        concepts
          ..add('Track what happens to particles, quantities, and equations in $focusedTopic.')
          ..add('Link $focusedTopic to observations, conditions, and calculations when relevant.');
        break;
      case 'history':
        concepts
          ..add('Know the causes, timeline, and consequences linked to $focusedTopic.')
          ..add('Support $focusedTopic with one precise example, source, or historical detail.');
        break;
      case 'english':
        concepts
          ..add('Define $focusedTopic clearly and recognise it in a sentence, text, or response.')
          ..add('Use one correct example and explain why it is effective or accurate.');
        break;
      case 'computer science':
        concepts
          ..add('Explain what $focusedTopic does, how it works, and where it is used.')
          ..add('Describe the logic, structure, or trade-off behind $focusedTopic.');
        break;
      default:
        concepts
          ..add('Define $focusedTopic in your own words.')
          ..add('Connect $focusedTopic to one clear exam example.');
        break;
    }

    return concepts.take(3).toList();
  }

  List<String> _importantFormulasFor({
    required Exam exam,
    required StudyTopic topic,
  }) {
    final subject = exam.subject.toLowerCase();
    final normalizedTopic = _focusedTopicTitle(exam, topic).toLowerCase();

    if (subject == 'physics') {
      if (_containsAny(normalizedTopic, ['thermodynamic', 'thermal', 'heat'])) {
        return const [
          'Q = mc x delta T - heat energy change equals mass times specific heat capacity times temperature change.',
          'delta U = Q - W - internal energy change equals heat added minus work done by the system.',
          'eta = (useful output energy / input energy) x 100% - efficiency of a thermal process.',
        ];
      }
      if (_containsAny(normalizedTopic, ['kinematic', 'motion', 'acceleration'])) {
        return const [
          'v = u + at - final velocity.',
          's = ut + 1/2at^2 - displacement with constant acceleration.',
          'v^2 = u^2 + 2as - link between speed, acceleration, and distance.',
        ];
      }
      if (_containsAny(normalizedTopic, ['force', 'newton'])) {
        return const [
          'F = ma - net force equals mass times acceleration.',
          'W = mg - weight equals mass times gravitational field strength.',
        ];
      }
      if (_containsAny(normalizedTopic, ['energy', 'power', 'work'])) {
        return const [
          'W = Fd - work done by a force.',
          'E_k = 1/2mv^2 - kinetic energy.',
          'P = W/t - power equals work done per unit time.',
        ];
      }
      if (_containsAny(normalizedTopic, ['momentum', 'collision'])) {
        return const [
          'p = mv - momentum.',
          'F x delta t = delta p - impulse equals change in momentum.',
        ];
      }
      if (_containsAny(normalizedTopic, ['circuit', 'electric', 'voltage', 'current', 'resistance'])) {
        return const [
          'V = IR - Ohm\'s law.',
          'P = VI - electrical power.',
          'Q = It - charge equals current times time.',
        ];
      }
      if (_containsAny(normalizedTopic, ['wave', 'optic', 'light'])) {
        return const [
          'v = f lambda - wave speed equals frequency times wavelength.',
          'n = c/v - refractive index.',
        ];
      }
    }

    if (subject == 'mathematics') {
      if (_containsAny(normalizedTopic, ['quadratic'])) {
        return const [
          'x = (-b +/- sqrt(b^2 - 4ac)) / 2a - quadratic formula.',
          'D = b^2 - 4ac - discriminant.',
        ];
      }
      if (_containsAny(normalizedTopic, ['derivative', 'differenti'])) {
        return const [
          'd/dx (x^n) = nx^(n-1) - power rule.',
          'd/dx (constant) = 0 - derivative of a constant.',
        ];
      }
      if (_containsAny(normalizedTopic, ['integral', 'integration'])) {
        return const [
          'Integral of x^n dx = x^(n+1)/(n+1) + C - power rule for integration.',
          'Integral of k dx = kx + C - integral of a constant.',
        ];
      }
      if (_containsAny(normalizedTopic, ['probability', 'statistics'])) {
        return const [
          'P(A) = favourable outcomes / total outcomes.',
          'P(A and B) = P(A) x P(B) for independent events.',
        ];
      }
      if (_containsAny(normalizedTopic, ['trigonometry', 'triangle', 'sine', 'cosine', 'tangent'])) {
        return const [
          'sin^2(theta) + cos^2(theta) = 1 - core trigonometric identity.',
          'SOHCAHTOA - basic right-triangle ratios.',
        ];
      }
      if (_containsAny(normalizedTopic, ['sequence', 'series', 'arithmetic'])) {
        return const [
          'a_n = a_1 + (n - 1)d - nth term of an arithmetic sequence.',
          'S_n = n/2 (2a_1 + (n - 1)d) - sum of an arithmetic series.',
        ];
      }
    }

    if (subject == 'chemistry') {
      if (_containsAny(normalizedTopic, ['stoichiometry', 'mole'])) {
        return const [
          'n = m / M - moles from mass and molar mass.',
          'n = cV - moles from concentration and volume.',
        ];
      }
      if (_containsAny(normalizedTopic, ['acid', 'base', 'ph'])) {
        return const [
          'pH = -log[H+] - acidity from hydrogen ion concentration.',
          'pH + pOH = 14 - relationship at 25 C.',
        ];
      }
      if (_containsAny(normalizedTopic, ['rate', 'reaction rate'])) {
        return const [
          'Rate = change in quantity / time.',
        ];
      }
      if (_containsAny(normalizedTopic, ['equilibrium'])) {
        return const [
          'Kc = [products]^coefficients / [reactants]^coefficients - equilibrium constant expression.',
        ];
      }
      if (_containsAny(normalizedTopic, ['electrochem', 'redox'])) {
        return const [
          'Q = It - total charge passed.',
        ];
      }
    }

    return const <String>[];
  }

  List<String> _quickQuizFor({
    required String topicTitle,
    required List<String> formulas,
  }) {
    final formulaPrompt = formulas.isNotEmpty
        ? 'Which formula, law, or rule is most important in $topicTitle, and what does each symbol mean?'
        : 'Which key process, cause, method, or definition is most important in $topicTitle?';

    return <String>[
      'In your own words, what is $topicTitle?',
      formulaPrompt,
      'Give one real-life or exam-style example that shows $topicTitle.',
      'What is one common mistake students make when answering questions on $topicTitle?',
    ];
  }

  List<String> _flashcardsFor({
    required String topicTitle,
    required String explanation,
    required List<String> keyConcepts,
    required List<String> formulas,
  }) {
    final cards = <String>[
      '$topicTitle - ${_oneLineKeyPoint(explanation)}',
      'Key idea in $topicTitle - ${keyConcepts.last}',
    ];

    if (formulas.isNotEmpty) {
      cards.add(formulas.first);
    } else {
      cards.add(
        'Exam focus for $topicTitle - Explain it clearly, stay on the exact topic, and connect it to one example.',
      );
    }

    return cards;
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
    final focusedTopic = _focusedTopicTitle(exam, topic);
    return _TaskTemplate(
      label,
      SubjectContentCatalog.studyDescriptionFor(
        subject: exam.subject,
        topic: focusedTopic,
        simpleLanguage: _usesSimpleLanguage(exam.studyLevel),
      ),
      'study',
      _usesSimpleLanguage(exam.studyLevel) ? 20 : 28,
    );
  }

  _TaskTemplate _practiceTemplateFor(Exam exam, StudyTopic topic) {
    final practiceLabel = exam.examType.toLowerCase().contains('ielts') ||
            exam.examType.toLowerCase().contains('toefl')
        ? 'Timed language practice'
        : 'Practice session';
    final focusedTopic = _focusedTopicTitle(exam, topic);
    return _TaskTemplate(
      practiceLabel,
      SubjectContentCatalog.practiceDescriptionFor(
        subject: exam.subject,
        topic: focusedTopic,
      ),
      'quiz',
      exam.difficulty.toLowerCase() == 'advanced' ? 35 : 30,
    );
  }

  _TaskTemplate _flashcardTemplateFor(Exam exam, StudyTopic topic) {
    final focusedTopic = _focusedTopicTitle(exam, topic);
    return _TaskTemplate(
      'Flashcard review',
      SubjectContentCatalog.flashcardDescriptionFor(
        subject: exam.subject,
        topic: focusedTopic,
      ),
      'flashcards',
      _usesSimpleLanguage(exam.studyLevel) ? 15 : 18,
    );
  }

  _TaskTemplate _weakAreaReviewTemplate(Exam exam, StudyTopic topic) {
    final focusedTopic = _focusedTopicTitle(exam, topic);
    return _TaskTemplate(
      'Weak area review',
      SubjectContentCatalog.reviewDescriptionFor(
        subject: exam.subject,
        topic: focusedTopic,
      ),
      'review',
      25,
    );
  }

  _TaskTemplate _mixedRevisionTemplate(
    Exam exam, {
    required String title,
    required List<String> focusTopics,
  }) {
    return _TaskTemplate(
      title,
      SubjectContentCatalog.mixedRevisionDescriptionFor(
        subject: exam.subject,
        focusTopics: focusTopics,
      ),
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

  String _focusedTopicTitle(Exam exam, StudyTopic topic) {
    final normalizedTopic = StudyMaterialParser.normalizeTopicTitle(
      subject: exam.subject,
      topic: topic.title,
    );
    return normalizedTopic.isEmpty ? topic.title.trim() : normalizedTopic;
  }

  String _oneLineKeyPoint(String explanation) {
    final firstSentence = explanation.split('.').first.trim();
    return firstSentence.isEmpty ? explanation : '$firstSentence.';
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
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
