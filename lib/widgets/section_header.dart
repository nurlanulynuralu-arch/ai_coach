import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final actionButton = actionLabel != null && onAction != null
        ? TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.78),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppTheme.line),
              ),
            ),
            child: Text(
              actionLabel!,
              style: textTheme.bodySmall?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          )
        : null;
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title, style: textTheme.titleLarge),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: textTheme.bodyMedium),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldStackAction = actionButton != null && constraints.maxWidth < 390;

        if (shouldStackAction) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 12),
              actionButton!,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            if (actionButton != null)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: actionButton!,
              ),
          ],
        );
      },
    );
  }
}
