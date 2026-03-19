import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FeatureRow extends StatelessWidget {
  const FeatureRow({
    super.key,
    required this.feature,
    required this.freeLabel,
    required this.premiumLabel,
  });

  final String feature;
  final String freeLabel;
  final String premiumLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              feature,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              freeLabel,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              premiumLabel,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
