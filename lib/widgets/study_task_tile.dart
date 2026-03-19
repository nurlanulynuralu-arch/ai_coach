import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/study_task.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

class StudyTaskTile extends StatelessWidget {
  const StudyTaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final StudyTask task;
  final VoidCallback onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final accentColor = task.isCompleted ? AppTheme.mint : AppTheme.primaryBlue;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 7,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(30),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    color: AppTheme.ink,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _StatusChip(
                            label: task.isCompleted ? 'Done' : 'Planned',
                            color: accentColor,
                          ),
                          if (onEdit != null || onDelete != null)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_horiz_rounded),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  onEdit?.call();
                                }
                                if (value == 'delete') {
                                  onDelete?.call();
                                }
                              },
                              itemBuilder: (context) => [
                                if (onEdit != null)
                                  const PopupMenuItem<String>(
                                    value: 'edit',
                                    child: Text('Edit task'),
                                  ),
                                if (onDelete != null)
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Text('Delete task'),
                                  ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.ink,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        task.topic,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _MetaChip(
                            icon: Icons.schedule_rounded,
                            label: '${task.estimatedMinutes} min',
                            color: accentColor,
                          ),
                          _MetaChip(
                            icon: Icons.calendar_today_rounded,
                            label: DateFormat('EEE, MMM d').format(task.scheduledFor),
                            color: AppTheme.deepBlue,
                          ),
                          _MetaChip(
                            icon: Icons.auto_awesome_rounded,
                            label: task.taskType,
                            color: AppTheme.mint,
                          ),
                        ],
                      ),
                      if (onTap != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                              color: AppTheme.primaryBlue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Open task details',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: task.isCompleted
                          ? accentColor
                          : accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      task.isCompleted ? Icons.check_rounded : Icons.play_arrow_rounded,
                      color: task.isCompleted ? Colors.white : accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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
