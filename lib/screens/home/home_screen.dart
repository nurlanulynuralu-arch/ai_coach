import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/exam.dart';
import '../../models/study_task.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/study_plan_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/adaptive_button_row.dart';
import '../../widgets/app_card.dart';
import '../../widgets/coach_bottom_nav.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/loading_state_view.dart';
import '../../widgets/quick_action_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/study_task_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final studyProvider = context.watch<StudyPlanProvider>();
    final user = authProvider.user;

    if (user == null && !authProvider.isInitialized) {
      return const Scaffold(body: LoadingStateView());
    }

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/sign-in');
        }
      });
      return const Scaffold(body: LoadingStateView());
    }

    final exam = studyProvider.activeExam;
    final progress = studyProvider.progressStats;
    final todayTasks = studyProvider.todayTasks;
    final nextTask = studyProvider.nextPendingTask;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: studyProvider.isLoading && studyProvider.exams.isEmpty
              ? const LoadingStateView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppTheme.primaryBlue,
                            child: Text(
                              user.initials,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back, ${user.name.split(' ').first}',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  studyProvider.motivationalMessage,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => context.go('/settings'),
                            icon: const Icon(Icons.settings_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (studyProvider.errorMessage != null) ...[
                        InfoBanner(
                          title: 'Sync issue',
                          message: studyProvider.errorMessage!,
                          icon: Icons.cloud_off_rounded,
                          backgroundColor: AppTheme.danger.withValues(alpha: 0.08),
                          foregroundColor: AppTheme.danger,
                          actionLabel: 'Dismiss',
                          onAction: studyProvider.clearError,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (authProvider.needsEmailVerification) ...[
                        InfoBanner(
                          title: 'Verify your email',
                          message:
                              'Firebase verification has been sent. Confirm your email, then refresh from Settings.',
                          icon: Icons.mark_email_unread_outlined,
                          actionLabel: 'Resend email',
                          onAction: () async {
                            await authProvider.resendVerificationEmail();
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Verification email sent.')),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      _HeroExamCard(
                        hasExam: exam != null,
                        examTitle: exam == null ? 'Create your first exam workspace' : _displayExamTitle(exam),
                        subtitle: exam == null
                            ? 'Build a personalized study plan from your exam date, target score, and topics.'
                            : '${exam.subject} | ${exam.examType} | ${exam.studyLevel} | ${DateFormat('MMM d, yyyy').format(exam.examDate)}',
                        progressPercent: progress.progressPercent,
                        readinessPercent: exam?.readinessScore ?? 0,
                        streakDays: progress.streakDays,
                        onPrimaryTap: () => exam == null
                            ? context.go('/exam-setup?mode=create')
                            : context.go('/study-plan'),
                        onSecondaryTap: () => exam == null
                            ? context.go('/sign-up')
                            : _startQuiz(context, studyProvider),
                      ),
                      if (exam != null && nextTask != null) ...[
                        const SizedBox(height: 16),
                        _ResumeStudyCard(
                          task: nextTask,
                          onContinue: () => context.go('/study-plan'),
                          onOpenQuiz: () => _startQuiz(context, studyProvider),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SectionHeader(
                        title: 'Your exams',
                        subtitle: studyProvider.exams.isEmpty
                            ? 'Create an exam to unlock study plans, quizzes, and progress.'
                            : 'Switch between exam workspaces and continue where you left off.',
                        actionLabel: 'New exam',
                        onAction: () => context.go('/exam-setup?mode=create'),
                      ),
                      const SizedBox(height: 16),
                      if (studyProvider.exams.isEmpty)
                        const EmptyStateView(
                          title: 'No exams yet',
                          message:
                              'Start by creating an exam with topics and a target date. The app will build the plan for you.',
                          icon: Icons.school_outlined,
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.35);
                            final extraHeight = (textScale - 1.0) * 56;
                            final examCardHeight = constraints.maxWidth < 380
                                ? 254.0 + extraHeight
                                : constraints.maxWidth < 460
                                    ? 228.0 + extraHeight
                                    : 204.0 + extraHeight;
                            final examCardWidth =
                                constraints.maxWidth < 390 ? constraints.maxWidth * 0.84 : 250.0;
                            return SizedBox(
                              height: examCardHeight,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: studyProvider.exams.length,
                                separatorBuilder: (_, itemIndex) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final item = studyProvider.exams[index];
                                  final isActive = item.id == studyProvider.activeExam?.id;
                                  final examTasks = studyProvider.tasksForExam(item.id);
                                  final completedTasks =
                                      examTasks.where((task) => task.isCompleted).length;
                                  return SizedBox(
                                    width: examCardWidth,
                                    child: _ExamWorkspaceCard(
                                      exam: item,
                                      isActive: isActive,
                                      completedTasks: completedTasks,
                                      totalTasks: examTasks.length,
                                      onTap: () => studyProvider.setActiveExam(item.id),
                                      onEdit: () {
                                        studyProvider.setActiveExam(item.id);
                                        context.go('/exam-setup');
                                      },
                                      onDelete: () => _confirmDeleteExam(context, studyProvider, item.id),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                      const SectionHeader(
                        title: 'Quick actions',
                        subtitle: 'Jump directly into the core workflow without dead ends.',
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 14.0;
                          final useSingleColumn = constraints.maxWidth < 340;
                          final itemWidth = useSingleColumn
                              ? constraints.maxWidth
                              : (constraints.maxWidth - spacing) / 2;
                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              SizedBox(
                                width: itemWidth,
                                child: QuickActionCard(
                                  icon: Icons.add_task_rounded,
                                  title: 'Create Exam',
                                  subtitle: 'Set your date, topics, and target score',
                                  accentColor: AppTheme.primaryBlue,
                                  onTap: () => context.go('/exam-setup?mode=create'),
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: QuickActionCard(
                                  icon: Icons.calendar_month_rounded,
                                  title: 'Study Plan',
                                  subtitle: 'Open the daily task flow',
                                  accentColor: AppTheme.mint,
                                  onTap: () => exam == null
                                      ? context.go('/exam-setup?mode=create')
                                      : context.go('/study-plan'),
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: QuickActionCard(
                                  icon: Icons.quiz_rounded,
                                  title: 'Quizzes',
                                  subtitle: 'Practice active recall under pressure',
                                  accentColor: AppTheme.deepBlue,
                                  onTap: () => _startQuiz(context, studyProvider),
                                ),
                              ),
                              SizedBox(
                                width: itemWidth,
                                child: QuickActionCard(
                                  icon: Icons.layers_rounded,
                                  title: 'Flashcards',
                                  subtitle: 'Review topic memory prompts',
                                  accentColor: AppTheme.aqua,
                                  onTap: () => exam == null
                                      ? context.go('/exam-setup?mode=create')
                                      : context.go('/flashcards'),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      SectionHeader(
                        title: 'Today''s study flow',
                        subtitle: todayTasks.isEmpty
                            ? 'No tasks planned for today yet.'
                            : 'Mark tasks complete to keep your streak and progress moving.',
                        actionLabel: exam == null ? null : 'Open plan',
                        onAction: exam == null ? null : () => context.go('/study-plan'),
                      ),
                      const SizedBox(height: 16),
                      if (todayTasks.isEmpty)
                        const EmptyStateView(
                          title: 'Nothing scheduled for today',
                          message:
                              'Generate a study plan and daily tasks will appear here automatically.',
                          icon: Icons.event_note_rounded,
                        )
                      else
                        ...todayTasks.take(3).map(
                              (task) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: StudyTaskTile(
                                  task: task,
                                  onToggle: () => studyProvider.toggleTask(task.id),
                                ),
                              ),
                            ),
                      const SizedBox(height: 12),
                      AppCard(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFEAFBF5),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Progress snapshot',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _MetricPill(
                                    label: 'Completed',
                                    value: '${progress.completedTasks}/${progress.totalTasks}',
                                  ),
                                ),
                                Expanded(
                                  child: _MetricPill(
                                    label: 'Quiz avg',
                                    value: '${progress.averageQuizScore}%',
                                  ),
                                ),
                                Expanded(
                                  child: _MetricPill(
                                    label: 'Streak',
                                    value: '${progress.streakDays}d',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => context.go('/progress'),
                                icon: const Icon(Icons.insights_rounded),
                                label: const Text('Open progress dashboard'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
      bottomNavigationBar: CoachBottomNav(
        currentIndex: 0,
        onDestinationSelected: (index) => _onNavTap(context, index),
      ),
    );
  }

  Future<void> _startQuiz(BuildContext context, StudyPlanProvider studyProvider) async {
    if (studyProvider.exams.isEmpty) {
      context.go('/exam-setup?mode=create');
      return;
    }

    Exam? selectedExam = studyProvider.activeExam;
    if (studyProvider.exams.length > 1) {
      selectedExam = await _pickExamForQuiz(context, studyProvider);
      if (!context.mounted) {
        return;
      }
      if (selectedExam == null) {
        return;
      }
    }

    if (selectedExam == null) {
      context.go('/exam-setup?mode=create');
      return;
    }

    studyProvider.setActiveExam(selectedExam.id);

    final quizProvider = context.read<QuizProvider>();
    final questions = studyProvider.buildQuizQuestionsForExam(selectedExam.id);

    if (questions.isEmpty) {
      await quizProvider.loadFallbackQuestions(
        subject: selectedExam.subject,
        topics: selectedExam.topics.map((topic) => topic.title).toList(),
      );
      if (!context.mounted) {
        return;
      }
    } else {
      quizProvider.setQuestions(questions);
    }

    if (!context.mounted) {
      return;
    }
    context.go('/quiz');
  }

  Future<Exam?> _pickExamForQuiz(
    BuildContext context,
    StudyPlanProvider studyProvider,
  ) async {
    return showModalBottomSheet<Exam>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose a subject for the quiz',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Each quiz will now use the selected exam subject and its topics.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  ...studyProvider.exams.map(
                    (exam) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.pop(sheetContext, exam),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.blueSoft,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.line),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.quiz_rounded,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exam.subject,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      exam.title,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteExam(
    BuildContext context,
    StudyPlanProvider provider,
    String examId,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Delete exam?'),
              content: const Text(
                'This removes the exam, study tasks, flashcards, and quiz attempts from Firestore.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await provider.deleteExam(examId);
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

class _HeroExamCard extends StatelessWidget {
  const _HeroExamCard({
    required this.hasExam,
    required this.examTitle,
    required this.subtitle,
    required this.progressPercent,
    required this.readinessPercent,
    required this.streakDays,
    required this.onPrimaryTap,
    required this.onSecondaryTap,
  });

  final bool hasExam;
  final String examTitle;
  final String subtitle;
  final double progressPercent;
  final int readinessPercent;
  final int streakDays;
  final VoidCallback onPrimaryTap;
  final VoidCallback onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    final quizButton = FilledButton.icon(
      onPressed: hasExam ? onSecondaryTap : onPrimaryTap,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.deepBlue,
      ),
      icon: Icon(hasExam ? Icons.quiz_rounded : Icons.add_task_rounded),
      label: Text(hasExam ? 'Open quiz' : 'Create exam'),
    );
    final secondaryButton = OutlinedButton.icon(
      onPressed: hasExam ? onPrimaryTap : onSecondaryTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
        backgroundColor: Colors.white.withValues(alpha: 0.08),
      ),
      icon: Icon(hasExam ? Icons.menu_book_rounded : Icons.login_rounded),
      label: Text(hasExam ? 'Open study plan' : 'Open sign in'),
    );

    return AppCard(
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              hasExam ? 'Active exam workspace' : 'Get started',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            examTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressPercent,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.aqua),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _HeroMetric(label: 'Plan', value: '${(progressPercent * 100).round()}%')),
              Expanded(child: _HeroMetric(label: 'Ready', value: '$readinessPercent%')),
              Expanded(child: _HeroMetric(label: 'Streak', value: '${streakDays}d')),
            ],
          ),
          const SizedBox(height: 18),
          AdaptiveButtonRow(
            first: quizButton,
            second: secondaryButton,
          ),
        ],
      ),
    );
  }
}

class _ResumeStudyCard extends StatelessWidget {
  const _ResumeStudyCard({
    required this.task,
    required this.onContinue,
    required this.onOpenQuiz,
  });

  final StudyTask task;
  final VoidCallback onContinue;
  final VoidCallback onOpenQuiz;

  @override
  Widget build(BuildContext context) {
    final dueLabel = _dueLabelForTask(task);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.greenSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Resume study',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mint,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const Spacer(),
              Text(
                dueLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            task.title,
            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            task.description,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ResumeMetaChip(
                icon: Icons.menu_book_rounded,
                label: task.topicTitle,
                color: AppTheme.primaryBlue,
                backgroundColor: AppTheme.blueSoft,
              ),
              _ResumeMetaChip(
                icon: Icons.schedule_rounded,
                label: '${task.estimatedMinutes} min',
                color: AppTheme.mint,
                backgroundColor: AppTheme.greenSoft,
              ),
              _ResumeMetaChip(
                icon: Icons.auto_awesome_rounded,
                label: _displayTaskType(task.taskType),
                color: AppTheme.deepBlue,
                backgroundColor: AppTheme.softSurface,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AdaptiveButtonRow(
            first: FilledButton.icon(
              onPressed: onContinue,
              icon: const Icon(Icons.play_circle_fill_rounded),
              label: const Text('Continue task'),
            ),
            second: OutlinedButton.icon(
              onPressed: onOpenQuiz,
              icon: const Icon(Icons.quiz_rounded),
              label: const Text('Open quiz'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
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

class _ExamWorkspaceCard extends StatelessWidget {
  const _ExamWorkspaceCard({
    required this.exam,
    required this.isActive,
    required this.completedTasks,
    required this.totalTasks,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Exam exam;
  final bool isActive;
  final int completedTasks;
  final int totalTasks;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final compact = _isCompactCardLayout(context);
    final displayTitle = _displayExamTitle(exam);
    final subtitle = _displayExamMeta(exam);

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 20,
        compact ? 14 : 20,
        compact ? 14 : 20,
        compact ? 12 : 20,
      ),
      gradient: isActive
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFE9F2FF)],
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.blueSoft : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    exam.subject,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w800,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  }
                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Edit exam'),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete exam'),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 16),
          Text(
            displayTitle,
            style: (compact ? Theme.of(context).textTheme.titleSmall : Theme.of(context).textTheme.titleLarge)
                ?.copyWith(color: AppTheme.ink),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: compact ? 4 : 8),
          Text(
            subtitle,
            style: compact ? Theme.of(context).textTheme.bodySmall : Theme.of(context).textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: compact ? 12 : 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: totalTasks == 0 ? 0 : completedTasks / totalTasks,
              minHeight: compact ? 6 : 8,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '$completedTasks/$totalTasks complete',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.ink,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isActive)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 5 : 6),
                  decoration: BoxDecoration(
                    color: AppTheme.greenSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Active',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mint,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isCompactCardLayout(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 390;
  }
}

String _displayExamTitle(Exam exam) {
  final trimmedTitle = exam.title.trim();
  final normalizedTitle = trimmedTitle.toLowerCase();
  const genericTitles = <String>{
    'quiz',
    'exam',
    'test',
    'study plan',
    'plan',
  };

  if (trimmedTitle.isEmpty || genericTitles.contains(normalizedTitle)) {
    return '${exam.subject} focus plan';
  }

  return trimmedTitle;
}

String _displayExamMeta(Exam exam) {
  final formattedDate = DateFormat('MMM d, yyyy').format(exam.examDate);
  return '${exam.examType} | $formattedDate';
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.ink,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ResumeMetaChip extends StatelessWidget {
  const _ResumeMetaChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

String _dueLabelForTask(StudyTask task) {
  final today = DateTime.now();
  final normalizedToday = DateTime(today.year, today.month, today.day);
  final normalizedTaskDate = DateTime(task.scheduledFor.year, task.scheduledFor.month, task.scheduledFor.day);

  if (normalizedTaskDate == normalizedToday) {
    return 'Due today';
  }
  if (normalizedTaskDate.isBefore(normalizedToday)) {
    return 'Overdue';
  }
  return 'Up next';
}

String _displayTaskType(String taskType) {
  switch (taskType.toLowerCase()) {
    case 'study':
      return 'Study';
    case 'recall':
      return 'Recall';
    case 'quiz':
      return 'Quiz';
    case 'flashcards':
      return 'Flashcards';
    case 'review':
      return 'Review';
    default:
      return taskType;
  }
}
