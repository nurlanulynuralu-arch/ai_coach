enum QuizQuestionType {
  multipleChoice,
  fillBlank,
  trueFalse,
}

extension QuizQuestionTypeX on QuizQuestionType {
  String get label {
    switch (this) {
      case QuizQuestionType.multipleChoice:
        return 'Multiple choice';
      case QuizQuestionType.fillBlank:
        return 'Fill in the blank';
      case QuizQuestionType.trueFalse:
        return 'True / False';
    }
  }
}

class QuizQuestion {
  QuizQuestion({
    required this.id,
    required this.examId,
    required this.topicId,
    required this.topicTitle,
    required this.subject,
    required this.type,
    required this.question,
    required List<String> options,
    required this.correctAnswer,
    required List<String> acceptedAnswers,
    required this.explanation,
    this.example,
    this.hint,
    this.difficultyLabel = 'Medium',
  })  : options = List<String>.from(options),
        acceptedAnswers = List<String>.from(acceptedAnswers);

  final String id;
  final String examId;
  final String topicId;
  final String topicTitle;
  final String subject;
  final QuizQuestionType type;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final List<String> acceptedAnswers;
  final String explanation;
  final String? example;
  final String? hint;
  final String difficultyLabel;

  bool matchesAnswer(String? answer) {
    if (answer == null) {
      return false;
    }

    final normalizedAnswer = _normalize(answer);
    final validAnswers = acceptedAnswers.isEmpty ? <String>[correctAnswer] : acceptedAnswers;
    return validAnswers.any((item) => _normalize(item) == normalizedAnswer);
  }

  QuizQuestion copyWith({
    String? id,
    String? examId,
    String? topicId,
    String? topicTitle,
    String? subject,
    QuizQuestionType? type,
    String? question,
    List<String>? options,
    String? correctAnswer,
    List<String>? acceptedAnswers,
    String? explanation,
    String? example,
    String? hint,
    String? difficultyLabel,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      topicId: topicId ?? this.topicId,
      topicTitle: topicTitle ?? this.topicTitle,
      subject: subject ?? this.subject,
      type: type ?? this.type,
      question: question ?? this.question,
      options: List<String>.from(options ?? this.options),
      correctAnswer: correctAnswer ?? this.correctAnswer,
      acceptedAnswers: List<String>.from(acceptedAnswers ?? this.acceptedAnswers),
      explanation: explanation ?? this.explanation,
      example: example ?? this.example,
      hint: hint ?? this.hint,
      difficultyLabel: difficultyLabel ?? this.difficultyLabel,
    );
  }
}

String _normalize(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
