import '../core/constants/subject_content_catalog.dart';

class StudyMaterialParser {
  static const int maxMaterialLength = 12000;

  static String normalizeImportedText(
    String content, {
    int maxLength = maxMaterialLength,
  }) {
    final normalized = content
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\t', ' ')
        .replaceAll(RegExp(r'[ ]{2,}'), ' ')
        .trim();

    if (normalized.length <= maxLength) {
      return normalized;
    }

    return normalized.substring(0, maxLength).trimRight();
  }

  static List<String> extractTopics({
    required String subject,
    required String content,
    int maxTopics = 10,
  }) {
    final normalized = normalizeImportedText(content);
    if (normalized.isEmpty) {
      return const <String>[];
    }

    final results = <String>[];
    final seen = <String>{};

    void addCandidate(String value) {
      final cleaned = _cleanCandidate(value);
      if (cleaned == null) {
        return;
      }

      final normalizedTopic = normalizeTopicTitle(
        subject: subject,
        topic: cleaned,
      );
      if (normalizedTopic.isEmpty) {
        return;
      }

      final key = normalizedTopic.toLowerCase();
      if (seen.add(key)) {
        results.add(normalizedTopic);
      }
    }

    for (final prompt in SubjectContentCatalog.topicPromptsFor(subject)) {
      if (_matchesContent(normalized, prompt)) {
        addCandidate(prompt);
        if (results.length >= maxTopics) {
          return results.take(maxTopics).toList();
        }
      }
    }

    for (final rawLine in normalized.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }

      for (final segment in _splitSegments(line)) {
        addCandidate(segment);
        if (results.length >= maxTopics) {
          return results.take(maxTopics).toList();
        }
      }
    }

    return results.take(maxTopics).toList();
  }

  static String? excerptForTopic({
    required String topic,
    required String content,
  }) {
    final normalized = normalizeImportedText(content);
    if (normalized.isEmpty) {
      return null;
    }

    final topicTokens = _keywords(topic);
    if (topicTokens.isEmpty) {
      return null;
    }

    String? bestChunk;
    var bestScore = 0;

    for (final rawChunk in normalized.split(RegExp(r'[.!?]\s+|\n+'))) {
      final chunk = rawChunk.trim();
      if (chunk.length < 24) {
        continue;
      }

      final lowerChunk = chunk.toLowerCase();
      var score = 0;

      if (lowerChunk.contains(topic.toLowerCase())) {
        score += 4;
      }

      for (final token in topicTokens) {
        if (lowerChunk.contains(token)) {
          score += 1;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestChunk = chunk;
      }
    }

    if (bestChunk == null || bestScore == 0) {
      return null;
    }

    return _trimSnippet(bestChunk);
  }

  static String normalizeTopicTitle({
    required String subject,
    required String topic,
  }) {
    final compact = topic.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) {
      return '';
    }

    var cleaned = compact;
    for (final alias in _subjectAliases(subject)) {
      cleaned = cleaned.replaceFirst(
        RegExp(
          '^${RegExp.escape(alias)}\\s*(?::|\\||>|/)\\s*',
          caseSensitive: false,
        ),
        '',
      );
      cleaned = cleaned.replaceFirst(
        RegExp(
          '^${RegExp.escape(alias)}\\s+-\\s+',
          caseSensitive: false,
        ),
        '',
      );
      cleaned = cleaned.replaceFirst(
        RegExp(
          '^${RegExp.escape(alias)}\\s+topic\\s*(?::|-)?\\s*',
          caseSensitive: false,
        ),
        '',
      );
    }

    cleaned = cleaned.trim();
    if (cleaned.isEmpty) {
      cleaned = compact;
    }

    return _prettify(cleaned);
  }

  static bool _matchesContent(String content, String prompt) {
    final lowerContent = content.toLowerCase();
    final lowerPrompt = prompt.toLowerCase();

    if (lowerContent.contains(lowerPrompt)) {
      return true;
    }

    final keywords = _keywords(prompt);
    if (keywords.isEmpty) {
      return false;
    }

    final hits = keywords.where(lowerContent.contains).length;
    return hits >= (keywords.length == 1 ? 1 : 2);
  }

  static List<String> _splitSegments(String line) {
    final withoutPrefix = line
        .replaceFirst(
          RegExp(r'^\s*(?:[-*]|[0-9]+[.)]|[A-Za-z][.)])\s*'),
          '',
        )
        .replaceFirst(
          RegExp(
            r'^(?:chapter|unit|topic|lesson|week)\s+[0-9ivxlcdm]+\s*[:.\-]?\s*',
            caseSensitive: false,
          ),
          '',
        );

    if (withoutPrefix.isEmpty) {
      return const <String>[];
    }

    return <String>[
      withoutPrefix,
      if (withoutPrefix.contains(':')) withoutPrefix.split(':').last.trim(),
      ...withoutPrefix.split(RegExp(r'[;|/]')),
    ];
  }

  static String? _cleanCandidate(String candidate) {
    final compact = candidate
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[\s\-:,.]+|[\s\-:,.]+$'), '')
        .replaceAll(RegExp(r"""^["']|["']$"""), '')
        .trim();

    if (compact.isEmpty || compact.length < 4 || compact.length > 64) {
      return null;
    }

    if (!_hasLetter(compact) || RegExp(r'^[0-9 ]+$').hasMatch(compact)) {
      return null;
    }

    final words = compact.split(' ').where((word) => word.isNotEmpty).toList();
    if (words.isEmpty || words.length > 8) {
      return null;
    }

    final lower = compact.toLowerCase();
    if (_blockedCandidates.contains(lower)) {
      return null;
    }

    final firstWord = words.first.toLowerCase();
    if (_blockedStarts.contains(firstWord)) {
      return null;
    }

    if (compact.contains('http') || compact.contains('@')) {
      return null;
    }

    return _prettify(compact);
  }

  static List<String> _keywords(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.length > 2 && !_connectorWords.contains(token))
        .toList();
  }

  static bool _hasLetter(String value) => RegExp(r'[A-Za-z]').hasMatch(value);

  static String _prettify(String value) {
    if (RegExp(r'[A-Z]').hasMatch(value)) {
      return value;
    }

    return value
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  static String _trimSnippet(String value) {
    if (value.length <= 260) {
      return value;
    }

    return '${value.substring(0, 257).trimRight()}...';
  }

  static List<String> _subjectAliases(String subject) {
    return switch (subject.trim().toLowerCase()) {
      'mathematics' => const ['mathematics', 'math', 'maths'],
      'computer science' => const ['computer science', 'computing', 'cs'],
      'physics' => const ['physics'],
      'biology' => const ['biology'],
      'chemistry' => const ['chemistry'],
      'history' => const ['history'],
      'english' => const ['english'],
      _ => [subject.trim().toLowerCase()],
    };
  }

  static const Set<String> _connectorWords = <String>{
    'and',
    'the',
    'for',
    'with',
    'from',
    'into',
    'over',
    'under',
    'your',
  };

  static const Set<String> _blockedCandidates = <String>{
    'introduction',
    'conclusion',
    'summary',
    'notes',
    'study guide',
    'important',
    'revision',
    'practice questions',
  };

  static const Set<String> _blockedStarts = <String>{
    'this',
    'that',
    'these',
    'those',
    'because',
    'explain',
    'describe',
    'write',
    'solve',
    'answer',
    'students',
    'questions',
  };
}
