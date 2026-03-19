import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const Spacer(),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              color: AppTheme.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: textTheme.titleSmall?.copyWith(
              color: AppTheme.ink,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
