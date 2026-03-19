import '../models/exam.dart';
import '../models/quiz_attempt.dart';
import '../models/study_topic.dart';
import 'study_material_parser.dart';

class StudyPersonalizationService {
  const StudyPersonalizationService();

  static const int repeatedMistakeThreshold = 2;
  static const int maxWeakAreas = 8;

  String normalizedTopicKey({
    required String subject,
    required String topicTitle,
  }) {
    final normalizedTitle = StudyMaterialParser.normalizeTopicTitle(
      subject: subject,
      topic: topicTitle,
    );
    return normalizedTitle.toLowerCase();
  }

  String displayTopicTitle({
    required String subject,
    required String topicTitle,
  }) {
    final normalizedTitle = StudyMaterialParser.normalizeTopicTitle(
      subject: subject,
      topic: topicTitle,
    );
    return normalizedTitle.isEmpty ? topicTitle.trim() : normalizedTitle;
  }

  int mistakeCountForTopic({
    required String subject,
    required String topicTitle,
    required Iterable<QuizAttempt> attempts,
    Iterable<String> latestWeakTopics = const <String>[],
  }) {
    final targetKey = normalizedTopicKey(
      subject: subject,
      topicTitle: topicTitle,
    );
    if (targetKey.isEmpty) {
      return 0;
    }

    return mistakeCounts(
          subject: subject,
          attempts: attempts,
          latestWeakTopics: latestWeakTopics,
        )[targetKey] ??
        0;
  }

  Map<String, int> mistakeCounts({
    required String subject,
    required Iterable<QuizAttempt> attempts,
    Iterable<String> latestWeakTopics = const <String>[],
  }) {
    final counts = <String, int>{};

    void addTopic(String topicTitle) {
      final key = normalizedTopicKey(
        subject: subject,
        topicTitle: topicTitle,
      );
      if (key.isEmpty) {
        return;
      }
      counts.update(key, (value) => value + 1, ifAbsent: () => 1);
    }

    for (final attempt in attempts) {
      final seenInAttempt = <String>{};
      for (final weakTopic in attempt.weakTopics) {
        final key = normalizedTopicKey(
          subject: subject,
          topicTitle: weakTopic,
        );
        if (key.isNotEmpty && seenInAttempt.add(key)) {
          counts.update(key, (value) => value + 1, ifAbsent: () => 1);
        }
      }
    }

    for (final weakTopic in latestWeakTopics) {
      addTopic(weakTopic);
    }

    return counts;
  }

  List<String> effectiveWeakAreas({
    required Exam exam,
    required Iterable<QuizAttempt> attempts,
    Iterable<String> latestWeakTopics = const <String>[],
  }) {
    final counts = mistakeCounts(
      subject: exam.subject,
      attempts: attempts,
      latestWeakTopics: latestWeakTopics,
    );
    final displayByKey = <String, String>{};
    final existingOrder = <String, int>{};

    void rememberTopic(String topicTitle) {
      final key = normalizedTopicKey(
        subject: exam.subject,
        topicTitle: topicTitle,
      );
      if (key.isEmpty) {
        return;
      }
      displayByKey.putIfAbsent(
        key,
        () => displayTopicTitle(
          subject: exam.subject,
          topicTitle: topicTitle,
        ),
      );
    }

    for (final weakArea in exam.weakAreas) {
      final key = normalizedTopicKey(
        subject: exam.subject,
        topicTitle: weakArea,
      );
      if (key.isEmpty) {
        continue;
      }
      rememberTopic(weakArea);
      existingOrder.putIfAbsent(key, () => existingOrder.length);
    }

    for (final topic in exam.topics) {
      final key = normalizedTopicKey(
        subject: exam.subject,
        topicTitle: topic.title,
      );
      if (key.isNotEmpty && counts.containsKey(key)) {
        rememberTopic(topic.title);
      }
    }

    for (final attempt in attempts) {
      for (final weakTopic in attempt.weakTopics) {
        rememberTopic(weakTopic);
      }
    }

    for (final weakTopic in latestWeakTopics) {
      rememberTopic(weakTopic);
    }

    final orderedKeys = displayByKey.keys.toList()
      ..sort((first, second) {
        final countCompare = (counts[second] ?? 0).compareTo(counts[first] ?? 0);
        if (countCompare != 0) {
          return countCompare;
        }

        final existingCompare =
            (existingOrder[first] ?? 1 << 20).compareTo(existingOrder[second] ?? 1 << 20);
        if (existingCompare != 0) {
          return existingCompare;
        }

        return displayByKey[first]!.compareTo(displayByKey[second]!);
      });

    return orderedKeys.map((key) => displayByKey[key]!).take(maxWeakAreas).toList();
  }

  bool shouldSimplifyTopic({
    required Exam exam,
    required String topicTitle,
    required Iterable<QuizAttempt> attempts,
    Iterable<String> latestWeakTopics = const <String>[],
  }) {
    return mistakeCountForTopic(
          subject: exam.subject,
          topicTitle: topicTitle,
          attempts: attempts,
          latestWeakTopics: latestWeakTopics,
        ) >=
        repeatedMistakeThreshold;
  }

  Exam personalizeExam({
    required Exam exam,
    required Iterable<QuizAttempt> attempts,
    Iterable<String> latestWeakTopics = const <String>[],
    String? highlightedTopic,
  }) {
    final counts = mistakeCounts(
      subject: exam.subject,
      attempts: attempts,
      latestWeakTopics: latestWeakTopics,
    );
    final effectiveWeakTopics = effectiveWeakAreas(
      exam: exam,
      attempts: attempts,
      latestWeakTopics: latestWeakTopics,
    );
    final weakTopicKeys = effectiveWeakTopics
        .map(
          (topic) => normalizedTopicKey(
            subject: exam.subject,
            topicTitle: topic,
          ),
        )
        .where((key) => key.isNotEmpty)
        .toSet();

    final personalizedTopics = exam.topics
        .map((topic) => _personalizedTopic(
              exam: exam,
              topic: topic,
              mistakeCounts: counts,
              weakTopicKeys: weakTopicKeys,
            ))
        .toList();

    final shouldSimplify = highlightedTopic != null &&
        shouldSimplifyTopic(
          exam: exam,
          topicTitle: highlightedTopic,
          attempts: attempts,
          latestWeakTopics: latestWeakTopics,
        );

    return exam.copyWith(
      topics: personalizedTopics,
      weakAreas: effectiveWeakTopics,
      studyLevel: shouldSimplify ? _simplifiedLevel(exam.studyLevel, counts) : exam.studyLevel,
    );
  }

  String simplificationIntro({
    required String topicTitle,
    required int mistakeCount,
  }) {
    if (mistakeCount >= 3) {
      return 'You have missed $topicTitle several times in quizzes, so this version starts simpler and rebuilds the topic step by step.';
    }
    if (mistakeCount >= repeatedMistakeThreshold) {
      return 'You have repeated mistakes on $topicTitle, so this explanation is simpler and focuses on the weak part first.';
    }
    if (mistakeCount == 1) {
      return 'You missed $topicTitle in a recent quiz, so keep extra focus on the key idea and the common mistake.';
    }
    return '';
  }

  StudyTopic _personalizedTopic({
    required Exam exam,
    required StudyTopic topic,
    required Map<String, int> mistakeCounts,
    required Set<String> weakTopicKeys,
  }) {
    final key = normalizedTopicKey(
      subject: exam.subject,
      topicTitle: topic.title,
    );
    final mistakeCount = mistakeCounts[key] ?? 0;
    final isWeakTopic = weakTopicKeys.contains(key);
    final boost = mistakeCount >= repeatedMistakeThreshold
        ? 2
        : isWeakTopic
            ? 1
            : 0;

    return topic.copyWith(
      importance: (topic.importance + boost).clamp(1, 3),
    );
  }

  String _simplifiedLevel(String currentLevel, Map<String, int> counts) {
    final normalizedLevel = currentLevel.trim().toUpperCase();
    if (normalizedLevel == 'A1' || normalizedLevel == 'A2') {
      return normalizedLevel;
    }

    final highestMistakeCount = counts.values.fold<int>(0, (highest, item) {
      return item > highest ? item : highest;
    });
    return highestMistakeCount >= 3 ? 'A1' : 'A2';
  }
}
