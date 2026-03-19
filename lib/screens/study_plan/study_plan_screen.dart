import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/study_task.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/study_plan_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/adaptive_button_row.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/loading_state_view.dart';
import '../../widgets/section_header.dart';
import '../../widgets/study_task_tile.dart';
import '../../widgets/task_focus_sheet.dart';

class StudyPlanScreen extends StatelessWidget {
  const StudyPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudyPlanProvider>();
    final exam = provider.activeExam;
    final progress = provider.progressStats;

    return Scaffold(
      floatingActionButton: exam == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openTaskEditor(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add task'),
            ),
      body: GradientBackground(
        child: SafeArea(
          child: provider.isLoading && provider.exams.isEmpty
              ? const LoadingStateView()
              : exam == null
                  ? EmptyStateView(
                      title: 'No study plan yet',
                      message:
                          'Create an exam to generate a day-by-day study plan, flashcards, and progress tracking.',
                      icon: Icons.auto_awesome_rounded,
                      actionLabel: 'Create exam',
                      onAction: () => context.go('/exam-setup?mode=create'),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Study plan',
                                      style: Theme.of(context).textTheme.headlineMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${exam.subject} | ${DateFormat('MMM d, yyyy').format(exam.examDate)}',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => context.go('/exam-setup'),
                                icon: const Icon(Icons.edit_calendar_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (provider.errorMessage != null) ...[
                            InfoBanner(
                              title: 'Action failed',
                              message: provider.errorMessage!,
                              icon: Icons.error_outline_rounded,
                              backgroundColor: AppTheme.danger.withValues(alpha: 0.08),
                              foregroundColor: AppTheme.danger,
                              actionLabel: 'Dismiss',
                              onAction: provider.clearError,
                            ),
                            const SizedBox(height: 16),
                          ],
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
                                  exam.title,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: Colors.white,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  exam.notes?.isNotEmpty == true
                                      ? exam.notes!
                                      : 'A structured plan generated from your level, exam type, weak areas, and study topics.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.84),
                                      ),
                                ),
                                const SizedBox(height: 18),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: progress.progressPercent,
                                    minHeight: 10,
                                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.aqua),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _PlanMetric(
                                        label: 'Completed',
                                        value: '${progress.completedTasks}/${progress.totalTasks}',
                                      ),
                                    ),
                                    Expanded(
                                      child: _PlanMetric(
                                        label: 'Readiness',
                                        value: '${exam.readinessScore}%',
                                      ),
                                    ),
                                    Expanded(
                                      child: _PlanMetric(
                                        label: 'Days left',
                                        value: '${exam.daysLeft}',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Study profile',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'This plan adapts the pace and revision flow using the learning profile you entered.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _ProfileChip(
                                      label: 'Level ${exam.studyLevel}',
                                      color: AppTheme.primaryBlue,
                                      backgroundColor: AppTheme.blueSoft,
                                    ),
                                    _ProfileChip(
                                      label: exam.examType,
                                      color: AppTheme.mint,
                                      backgroundColor: AppTheme.greenSoft,
                                    ),
                                    _ProfileChip(
                                      label: exam.difficulty,
                                      color: AppTheme.deepBlue,
                                      backgroundColor: AppTheme.blueSoft,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  exam.weakAreas.isEmpty
                                      ? 'No weak areas were added, so the plan is balanced across all topics.'
                                      : 'Weak areas: ${exam.weakAreas.join(', ')}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (provider.exams.length > 1)
                            AppCard(
                              child: DropdownButtonFormField<String>(
                                initialValue: exam.id,
                                decoration: const InputDecoration(
                                  labelText: 'Active exam',
                                  prefixIcon: Icon(Icons.swap_horiz_rounded),
                                ),
                                items: provider.exams
                                    .map(
                                      (item) => DropdownMenuItem(
                                        value: item.id,
                                        child: Text('${item.subject} - ${item.title}'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    provider.setActiveExam(value);
                                  }
                                },
                              ),
                            ),
                          if (provider.exams.length > 1) const SizedBox(height: 20),
                          const SectionHeader(
                            title: 'Daily study tasks',
                            subtitle: 'Each task is editable and synced to Firestore for real progress tracking.',
                          ),
                          const SizedBox(height: 16),
                          if (provider.tasks.isEmpty)
                            const EmptyStateView(
                              title: 'No tasks in this plan',
                              message: 'Regenerate the plan or add your first custom task.',
                              icon: Icons.playlist_add_check_circle_outlined,
                            )
                          else
                            ...provider.tasksByDate.entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: AppCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: DateUtils.isSameDay(entry.key, DateTime.now())
                                                  ? AppTheme.greenSoft
                                                  : AppTheme.blueSoft,
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              DateUtils.isSameDay(entry.key, DateTime.now())
                                                  ? 'Today'
                                                  : DateFormat('EEE').format(entry.key),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: DateUtils.isSameDay(entry.key, DateTime.now())
                                                        ? AppTheme.mint
                                                        : AppTheme.primaryBlue,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            DateFormat('MMMM d').format(entry.key),
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      ...entry.value.map(
                                        (task) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: StudyTaskTile(
                                            task: task,
                                            onTap: () => _openTaskFocus(context, task),
                                            onToggle: () => provider.toggleTask(task.id),
                                            onEdit: () => _openTaskEditor(context, task: task),
                                            onDelete: () => _deleteTask(context, task.id),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Plan actions',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Update the exam, add custom tasks, or review progress from here.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 18),
                                AdaptiveButtonRow(
                                  first: OutlinedButton.icon(
                                    onPressed: () => context.go('/exam-setup'),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Edit exam'),
                                  ),
                                  second: FilledButton.icon(
                                    onPressed: () => context.go('/progress'),
                                    icon: const Icon(Icons.insights_rounded),
                                    label: const Text('View progress'),
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
    );
  }

  Future<void> _deleteTask(BuildContext context, String taskId) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Delete task?'),
              content: const Text('This study task will be removed from Firestore.'),
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

    if (!confirmed || !context.mounted) {
      return;
    }

    await context.read<StudyPlanProvider>().deleteTask(taskId);
  }

  Future<void> _openTaskFocus(BuildContext context, StudyTask task) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer<StudyPlanProvider>(
          builder: (sheetContext, provider, _) {
            final summary = provider.topicSummaryFor(task.topicTitle) ??
                'Review the main idea of ${task.topicTitle}, connect it to one example, and explain why it matters for the exam.';
            final relatedFlashcards = provider.flashcardsForTopic(task.topicTitle).length;

            return TaskFocusSheet(
              title: task.title,
              topicTitle: task.topicTitle,
              taskTypeLabel: _labelForTaskType(task.taskType),
              summary: summary,
              minutesLabel: '${task.estimatedMinutes} min block',
              relatedFlashcardsLabel: '$relatedFlashcards flashcards',
              steps: _buildTaskSteps(task: task, summary: summary),
              isCompleted: task.isCompleted,
              onToggleComplete: () async {
                await provider.toggleTask(task.id);
                if (!sheetContext.mounted) {
                  return;
                }
                Navigator.pop(sheetContext);
              },
              onOpenFlashcards: () {
                Navigator.pop(sheetContext);
                context.go('/flashcards');
              },
              onStartQuiz: () async {
                Navigator.pop(sheetContext);
                await _startTopicQuiz(context, task.topicTitle);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _startTopicQuiz(BuildContext context, String topicTitle) async {
    final studyProvider = context.read<StudyPlanProvider>();
    final exam = studyProvider.activeExam;
    final questions = studyProvider.buildQuizQuestions(
      focusTopics: [topicTitle],
    );

    if (questions.isEmpty && exam == null) {
      context.go('/exam-setup?mode=create');
      return;
    }

    final quizProvider = context.read<QuizProvider>();
    if (questions.isEmpty) {
      await quizProvider.loadFallbackQuestions(
        subject: exam!.subject,
        topics: [topicTitle],
      );
    } else {
      quizProvider.setQuestions(questions);
    }

    if (!context.mounted) {
      return;
    }
    context.go('/quiz');
  }

  String _labelForTaskType(String taskType) {
    switch (taskType.toLowerCase()) {
      case 'study':
        return 'Concept study';
      case 'recall':
        return 'Active recall';
      case 'quiz':
        return 'Timed practice';
      case 'flashcards':
        return 'Flashcard review';
      case 'review':
        return 'Full review';
      default:
        return taskType;
    }
  }

  List<String> _buildTaskSteps({
    required StudyTask task,
    required String summary,
  }) {
    final compactSummary = summary.length > 130 ? '${summary.substring(0, 127)}...' : summary;

    switch (task.taskType.toLowerCase()) {
      case 'study':
        return [
          'Read or watch one focused explanation about ${task.topicTitle}.',
          'Use this summary as your anchor: $compactSummary',
          'Write a 3-line note in your own words and add one example you can remember later.',
        ];
      case 'recall':
        return [
          'Hide your notes and write everything you remember about ${task.topicTitle}.',
          'Check your answer against this topic summary: $compactSummary',
          'Circle the weak parts and turn them into new flashcard prompts.',
        ];
      case 'quiz':
        return [
          'Answer 2-3 exam-style questions on ${task.topicTitle} without checking notes first.',
          'Review mistakes using this concept summary: $compactSummary',
          'Repeat the hardest question until you can explain the answer confidently.',
        ];
      case 'flashcards':
        return [
          'Open the flashcards for ${task.topicTitle}.',
          'Say the answer aloud before flipping each card.',
          'Mark weak cards for another round and keep only the strong ones as mastered.',
        ];
      default:
        return [
          'Review the key idea of ${task.topicTitle}: $compactSummary',
          'Connect the topic to one example and one exam-style question.',
          'Finish by checking your flashcards or taking a short quiz for this topic.',
        ];
    }
  }

  Future<void> _openTaskEditor(BuildContext context, {StudyTask? task}) async {
    final titleController = TextEditingController(text: task?.title ?? '');
    final descriptionController = TextEditingController(text: task?.description ?? '');
    final topicController = TextEditingController(text: task?.topicTitle ?? '');
    final minutesController = TextEditingController(
      text: task == null ? '30' : '${task.estimatedMinutes}',
    );
    var taskType = task?.taskType ?? 'study';
    var scheduledDate = task?.scheduledFor ?? DateTime.now();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(task == null ? 'Add custom task' : 'Edit task'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppTextField(
                        controller: titleController,
                        label: 'Task title',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a task title.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: topicController,
                        label: 'Topic',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a topic.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: descriptionController,
                        label: 'Description',
                        maxLines: 3,
                        minLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a short description.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: taskType,
                        decoration: const InputDecoration(
                          labelText: 'Task type',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'study', child: Text('study')),
                          DropdownMenuItem(value: 'recall', child: Text('recall')),
                          DropdownMenuItem(value: 'quiz', child: Text('quiz')),
                          DropdownMenuItem(value: 'flashcards', child: Text('flashcards')),
                          DropdownMenuItem(value: 'review', child: Text('review')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => taskType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: minutesController,
                        label: 'Estimated minutes',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final minutes = int.tryParse(value ?? '');
                          if (minutes == null || minutes <= 0) {
                            return 'Enter a valid number of minutes.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 730)),
                            initialDate: scheduledDate,
                          );
                          if (picked != null) {
                            setDialogState(() => scheduledDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Schedule date',
                            prefixIcon: Icon(Icons.event_outlined),
                          ),
                          child: Text(DateFormat('MMM d, yyyy').format(scheduledDate)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    final success = await context.read<StudyPlanProvider>().saveTaskDraft(
                          taskId: task?.id,
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim(),
                          topicTitle: topicController.text.trim(),
                          taskType: taskType,
                          scheduledFor: scheduledDate,
                          estimatedMinutes: int.parse(minutesController.text.trim()),
                        );
                    if (!dialogContext.mounted) {
                      return;
                    }
                    if (success) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
    topicController.dispose();
    minutesController.dispose();
  }
}

class _PlanMetric extends StatelessWidget {
  const _PlanMetric({
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

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
