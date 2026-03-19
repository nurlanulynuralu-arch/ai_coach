class AppConstants {
  static const String appName = 'AI Study Coach';
  static const String tagline =
      'Turn exam stress into a guided study system with planning, practice, and progress tracking.';
  static const String supportEmail = 'support@aistudycoach.app';
  static const String aboutBlurb =
      'AI Study Coach is a Firebase-powered mobile MVP for structured exam preparation. Students create exams, generate guided plans, revise with flashcards, test themselves with quizzes, and track progress in one flow.';

  static const List<String> subjects = [
    'Biology',
    'Mathematics',
    'Physics',
    'Chemistry',
    'History',
    'Computer Science',
    'English',
  ];

  static const List<String> difficulties = [
    'Foundation',
    'Balanced',
    'Advanced',
  ];

  static const List<String> studyLevels = [
    'A1',
    'A2',
    'B1',
    'B2',
    'C1',
    'Exam Ready',
  ];

  static const List<String> examTypes = [
    'School exam',
    'University exam',
    'Midterm',
    'Final exam',
    'Quiz',
    'IELTS',
    'TOEFL',
  ];

  static const List<int> dailyGoalOptions = [
    45,
    60,
    90,
    120,
    150,
  ];

  static const List<int> targetScoreOptions = [
    70,
    75,
    80,
    85,
    90,
    95,
  ];

  static const List<String> startupPainPoints = [
    'Students study without structure and waste time on the wrong topics.',
    'Revision is inconsistent, so information is forgotten quickly.',
    'Motivation drops when progress feels invisible before the exam.',
  ];

  static const List<String> startupSolutions = [
    'Personalized exam setup turns a syllabus into a day-by-day plan.',
    'Task-based study blocks create structure and reduce last-minute cramming.',
    'Quizzes and flashcards reinforce recall before exam day.',
    'Progress stats, streaks, and encouraging feedback keep motivation visible.',
  ];

  static const List<String> premiumFeatures = [
    'Unlimited exam workspaces',
    'Expanded quiz banks per topic',
    'Smarter revision recommendations',
    'Advanced analytics and mastery tracking',
  ];

  static const List<String> motivationMessages = [
    'Small study wins add up fast.',
    'Progress beats cramming every time.',
    'Stay consistent and exam confidence will follow.',
    'One focused block now saves stress later.',
    'You do not need perfect study sessions, just repeatable ones.',
  ];

  static const List<String> emptyTopicPrompts = [
    'Photosynthesis',
    'Cell division',
    'Acids and bases',
    'Derivatives',
    'World War I causes',
  ];

  static const List<String> weakAreaPrompts = [
    'Definitions',
    'Problem solving',
    'Formulas',
    'Vocabulary',
    'Grammar',
    'Writing structure',
    'Time management',
  ];
}
