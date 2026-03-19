import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/study_task.dart';
import '../theme/app_theme.dart';
import 'adaptive_button_row.dart';
import 'app_card.dart';

class TopicPracticeSheet extends StatelessWidget {
  const TopicPracticeSheet({
    super.key,
    required this.topicTitle,
    required this.summary,
    required this.masteryLabel,
    required this.relatedCardCount,
    required this.tasks,
    required this.prompts,
    required this.onToggleTask,
    required this.onStartQuiz,
    required this.onOpenStudyPlan,
  });

  final String topicTitle;
  final String summary;
  final String masteryLabel;
  final int relatedCardCount;
  final List<StudyTask> tasks;
  final List<TopicPracticePrompt> prompts;
  final ValueChanged<StudyTask> onToggleTask;
  final VoidCallback onStartQuiz;
  final VoidCallback onOpenStudyPlan;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.92,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppTheme.canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _SheetBadge(
                            label: masteryLabel,
                            color: AppTheme.mint,
                            backgroundColor: AppTheme.greenSoft,
                          ),
                          _SheetBadge(
                            label: '$relatedCardCount cards',
                            color: AppTheme.primaryBlue,
                            backgroundColor: AppTheme.blueSoft,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        topicTitle,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Open the topic, review the main idea, finish the linked tasks, and launch a mini quiz from here.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      AppCard(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFEAF6FF),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Topic summary',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              summary,
                              style: Theme.of(context).textTheme.bodyLarge,
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
                              'Assignments by topic',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tasks.isEmpty
                                  ? 'No tasks are linked to this topic yet. Open the study plan to add one.'
                                  : 'Tap a task to mark it complete and keep your progress synced.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            if (tasks.isEmpty)
                              _EmptyTopicState(onOpenStudyPlan: onOpenStudyPlan)
                            else
                              ...tasks.map(
                                (task) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _TopicTaskRow(
                                    task: task,
                                    onTap: () => onToggleTask(task),
                                  ),
                                ),
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
                              'Practice now',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Use these short exercises to turn the card into real exam preparation.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            ...prompts.map(
                              (prompt) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _PromptTile(prompt: prompt),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: AdaptiveButtonRow(
                  first: OutlinedButton.icon(
                    onPressed: onOpenStudyPlan,
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: const Text('Study plan'),
                  ),
                  second: FilledButton.icon(
                    onPressed: onStartQuiz,
                    icon: const Icon(Icons.quiz_rounded),
                    label: const Text('Topic quiz'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TopicPracticePrompt {
  const TopicPracticePrompt({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
}

class _SheetBadge extends StatelessWidget {
  const _SheetBadge({
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

class _TopicTaskRow extends StatelessWidget {
  const _TopicTaskRow({
    required this.task,
    required this.onTap,
  });

  final StudyTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = task.isCompleted ? AppTheme.mint : AppTheme.primaryBlue;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                task.isCompleted ? Icons.check_rounded : Icons.play_arrow_rounded,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          decoration:
                              task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    task.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MiniMeta(
                        icon: Icons.schedule_rounded,
                        label: '${task.estimatedMinutes} min',
                        color: accentColor,
                      ),
                      _MiniMeta(
                        icon: Icons.event_rounded,
                        label: DateFormat('MMM d').format(task.scheduledFor),
                        color: AppTheme.deepBlue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniMeta extends StatelessWidget {
  const _MiniMeta({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _PromptTile extends StatelessWidget {
  const _PromptTile({required this.prompt});

  final TopicPracticePrompt prompt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: prompt.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: prompt.color.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: prompt.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(prompt.icon, color: prompt.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prompt.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  prompt.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTopicState extends StatelessWidget {
  const _EmptyTopicState({required this.onOpenStudyPlan});

  final VoidCallback onOpenStudyPlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.blueSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No assignments yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Open the study plan and add a custom task for this topic so the flashcard can connect directly to your revision workflow.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onOpenStudyPlan,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Open study plan'),
          ),
        ],
      ),
    );
  }
}
