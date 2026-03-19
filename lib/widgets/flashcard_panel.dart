import 'package:flutter/material.dart';

import '../models/flashcard.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

class FlashcardPanel extends StatelessWidget {
  const FlashcardPanel({
    super.key,
    required this.card,
    required this.showBack,
    required this.onTap,
  });

  final Flashcard card;
  final bool showBack;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = showBack ? 'Answer' : 'Prompt';
    final content = showBack ? card.back : card.front;
    final mastery = switch (card.reviewStage) {
      >= 4 => 'Mastered',
      >= 2 => 'Growing',
      _ => 'Needs review',
    };

    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF7FBFF),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.blueSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.greenSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      mastery,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.mint,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                card.topicTitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedText,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              Text(
                content,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.touch_app_rounded, size: 18, color: AppTheme.mutedText),
                  const SizedBox(width: 8),
                  Text(
                    showBack ? 'Tap to return to the prompt' : 'Tap to flip and self-check',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
