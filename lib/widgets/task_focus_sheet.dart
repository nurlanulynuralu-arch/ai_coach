import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'adaptive_button_row.dart';
import 'app_card.dart';

class TaskFocusSheet extends StatelessWidget {
  const TaskFocusSheet({
    super.key,
    required this.title,
    required this.topicTitle,
    required this.taskTypeLabel,
    required this.summary,
    required this.minutesLabel,
    required this.relatedFlashcardsLabel,
    required this.steps,
    required this.isCompleted,
    required this.onToggleComplete,
    required this.onOpenFlashcards,
    required this.onStartQuiz,
  });

  final String title;
  final String topicTitle;
  final String taskTypeLabel;
  final String summary;
  final String minutesLabel;
  final String relatedFlashcardsLabel;
  final List<String> steps;
  final bool isCompleted;
  final VoidCallback onToggleComplete;
  final VoidCallback onOpenFlashcards;
  final VoidCallback onStartQuiz;

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
                          _TaskBadge(
                            label: taskTypeLabel,
                            color: AppTheme.primaryBlue,
                            backgroundColor: AppTheme.blueSoft,
                          ),
                          _TaskBadge(
                            label: minutesLabel,
                            color: AppTheme.mint,
                            backgroundColor: AppTheme.greenSoft,
                          ),
                          _TaskBadge(
                            label: relatedFlashcardsLabel,
                            color: AppTheme.deepBlue,
                            backgroundColor: AppTheme.blueSoft,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        topicTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.primaryBlue,
                            ),
                      ),
                      const SizedBox(height: 18),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What this topic means',
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
                              'What to do now',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Follow these steps and then mark the task complete.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            ...steps.asMap().entries.map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _TaskStep(
                                      index: entry.key + 1,
                                      text: entry.value,
                                    ),
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
                child: Column(
                  children: [
                    AdaptiveButtonRow(
                      first: OutlinedButton.icon(
                        onPressed: onOpenFlashcards,
                        icon: const Icon(Icons.layers_rounded),
                        label: const Text('Flashcards'),
                      ),
                      second: FilledButton.icon(
                        onPressed: onStartQuiz,
                        icon: const Icon(Icons.quiz_rounded),
                        label: const Text('Topic quiz'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onToggleComplete,
                        icon: Icon(
                          isCompleted ? Icons.refresh_rounded : Icons.check_circle_rounded,
                        ),
                        label: Text(isCompleted ? 'Mark as planned' : 'Mark complete'),
                        style: FilledButton.styleFrom(
                          backgroundColor: isCompleted ? AppTheme.deepBlue : AppTheme.mint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskBadge extends StatelessWidget {
  const _TaskBadge({
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

class _TaskStep extends StatelessWidget {
  const _TaskStep({
    required this.index,
    required this.text,
  });

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '$index',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.ink,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
