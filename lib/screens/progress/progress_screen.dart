import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/study_plan_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/adaptive_button_row.dart';
import '../../widgets/app_card.dart';
import '../../widgets/coach_bottom_nav.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/section_header.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final studyProvider = context.watch<StudyPlanProvider>();
    final user = authProvider.user;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/sign-in');
        }
      });
      return const Scaffold(body: SizedBox.expand());
    }

    final progress = studyProvider.progressStats;
    final exam = studyProvider.activeExam;
    final topicRatios = studyProvider.topicCompletionRatios.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress dashboard',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  exam == null
                      ? 'Create an exam to start tracking progress.'
                      : 'Tracking ${exam.title} until ${DateFormat('MMM d').format(exam.examDate)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                if (exam == null)
                  EmptyStateView(
                    title: 'No active exam',
                    message:
                        'Generate a study plan first. Your completed tasks, quiz results, and streak will appear here.',
                    icon: Icons.insights_outlined,
                    actionLabel: 'Create exam',
                    onAction: () => context.go('/exam-setup?mode=create'),
                  )
                else ...[
                  AppCard(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryBlue,
                        AppTheme.deepBlue,
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exam readiness',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Your study plan, quiz performance, and consistency are combined into one view.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                        ),
                        const SizedBox(height: 18),
                        LinearProgressIndicator(
                          value: progress.progressPercent,
                          minHeight: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.aqua),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryMetric(
                                label: 'Plan done',
                                value: '${(progress.progressPercent * 100).round()}%',
                              ),
                            ),
                            Expanded(
                              child: _SummaryMetric(
                                label: 'Quiz average',
                                value: '${progress.averageQuizScore}%',
                              ),
                            ),
                            Expanded(
                              child: _SummaryMetric(
                                label: 'Streak',
                                value: '${progress.streakDays}d',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(
                    title: 'Core metrics',
                    subtitle: 'These numbers should make it obvious that progress is updating from real data.',
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final useSingleColumn = constraints.maxWidth < 390;
                      final cardAspectRatio = useSingleColumn
                          ? 2.2
                          : constraints.maxWidth < 460
                              ? 0.9
                              : 1.04;

                      return GridView.count(
                        crossAxisCount: useSingleColumn ? 1 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: cardAspectRatio,
                        children: [
                          MetricCard(
                            label: 'Completed tasks',
                            value: '${progress.completedTasks}/${progress.totalTasks}',
                            icon: Icons.checklist_rounded,
                            accentColor: AppTheme.mint,
                          ),
                          MetricCard(
                            label: 'Study hours',
                            value: (progress.totalStudyMinutes / 60).toStringAsFixed(1),
                            icon: Icons.timer_rounded,
                            accentColor: AppTheme.primaryBlue,
                          ),
                          MetricCard(
                            label: 'Completed topics',
                            value: '${progress.completedTopics}/${progress.totalTopics}',
                            icon: Icons.topic_outlined,
                            accentColor: AppTheme.deepBlue,
                          ),
                          MetricCard(
                            label: 'Quiz attempts',
                            value: '${progress.quizzesCompleted}',
                            icon: Icons.quiz_rounded,
                            accentColor: AppTheme.aqua,
                            subtitle: '${progress.averageQuizScore}% average',
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weak topics',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          progress.weakTopics.isEmpty
                              ? 'No weak topics detected yet. Finish more tasks or take a quiz.'
                              : 'Use weak topics for your next quiz or flashcard review.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        if (progress.weakTopics.isEmpty)
                          const Text('Everything looks balanced so far.')
                        else
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: progress.weakTopics
                                .map(
                                  (topic) => ActionChip(
                                    label: Text(topic),
                                    onPressed: () => _practiceTopics(context, [topic]),
                                  ),
                                )
                                .toList(),
                          ),
                        const SizedBox(height: 18),
                        AdaptiveButtonRow(
                          first: OutlinedButton.icon(
                            onPressed: () => _practiceTopics(
                              context,
                              progress.weakTopics.isEmpty
                                  ? exam.topics.map((topic) => topic.title).toList()
                                  : progress.weakTopics,
                            ),
                            icon: const Icon(Icons.quiz_rounded),
                            label: const Text('Practice'),
                          ),
                          second: FilledButton.icon(
                            onPressed: () => context.go('/flashcards'),
                            icon: const Icon(Icons.layers_rounded),
                            label: const Text('Flashcards'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Topic mastery',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Completion ratio is calculated from Firestore task data for each topic.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 18),
                        if (topicRatios.isEmpty)
                          const Text('Topic mastery will appear after tasks are generated.')
                        else
                          ...topicRatios.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _TopicProgressRow(
                                topic: entry.key,
                                ratio: entry.value,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last 7 days',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Completed study minutes by day.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 18),
                        _WeeklyBarChart(weeklyMinutes: progress.weeklyMinutes),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent quiz attempts',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        if (studyProvider.quizAttempts.isEmpty)
                          const Text('No quiz attempts saved yet.')
                        else
                          ...studyProvider.quizAttempts.take(4).map(
                                (attempt) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: AppTheme.blueSoft,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Icon(
                                          Icons.emoji_events_outlined,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('${attempt.scorePercent}% score'),
                                            const SizedBox(height: 4),
                                            Text(
                                              DateFormat('MMM d, yyyy').format(attempt.attemptedAt),
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${attempt.correctAnswers}/${attempt.totalQuestions}',
                                        style: Theme.of(context).textTheme.titleSmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CoachBottomNav(
        currentIndex: 1,
        onDestinationSelected: (index) => _onNavTap(context, index),
      ),
    );
  }

  Future<void> _practiceTopics(BuildContext context, List<String> topics) async {
    final studyProvider = context.read<StudyPlanProvider>();
    final activeExam = studyProvider.activeExam;
    final questions = studyProvider.buildQuizQuestions(focusTopics: topics);
    if (questions.isEmpty && activeExam == null) {
      context.go('/exam-setup?mode=create');
      return;
    }

    final quizProvider = context.read<QuizProvider>();
    if (questions.isEmpty) {
      await quizProvider.loadFallbackQuestions(
        subject: activeExam!.subject,
        topics: topics,
      );
    } else {
      quizProvider.setQuestions(questions);
    }

    if (!context.mounted) {
      return;
    }
    context.go('/quiz');
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        return;
      case 1:
        context.go('/progress');
        return;
      case 2:
        context.go('/profile');
        return;
    }
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
        ),
      ],
    );
  }
}

class _TopicProgressRow extends StatelessWidget {
  const _TopicProgressRow({
    required this.topic,
    required this.ratio,
  });

  final String topic;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                topic,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Text('${(ratio * 100).round()}%'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: ratio, minHeight: 8),
      ],
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({required this.weeklyMinutes});

  final List<int> weeklyMinutes;

  @override
  Widget build(BuildContext context) {
    final maxMinutes = weeklyMinutes.isEmpty
        ? 1
        : weeklyMinutes.reduce((current, next) => current > next ? current : next).clamp(1, 1000);

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List<Widget>.generate(weeklyMinutes.length, (index) {
          final value = weeklyMinutes[index];
          final normalized = value / maxMinutes;
          final date = DateTime.now().subtract(Duration(days: 6 - index));
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${value}m',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        height: 28 + (110 * normalized),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [AppTheme.primaryBlue, AppTheme.aqua],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('E').format(date).substring(0, 1),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
