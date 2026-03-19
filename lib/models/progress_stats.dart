class ProgressStats {
  ProgressStats({
    required this.progressPercent,
    required this.completedTasks,
    required this.totalTasks,
    required this.completedTopics,
    required this.totalTopics,
    required List<String> weakTopics,
    required this.streakDays,
    required this.totalStudyMinutes,
    required this.quizzesCompleted,
    required this.averageQuizScore,
    required List<int> weeklyMinutes,
  })  : weakTopics = List<String>.from(weakTopics),
        weeklyMinutes = List<int>.from(weeklyMinutes);

  final double progressPercent;
  final int completedTasks;
  final int totalTasks;
  final int completedTopics;
  final int totalTopics;
  final List<String> weakTopics;
  final int streakDays;
  final int totalStudyMinutes;
  final int quizzesCompleted;
  final int averageQuizScore;
  final List<int> weeklyMinutes;
}
