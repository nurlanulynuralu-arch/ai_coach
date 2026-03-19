import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/primary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.line),
                    ),
                    child: Text(
                      'Firebase MVP',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
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
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryBlue, AppTheme.aqua],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.psychology_alt_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        AppConstants.appName,
                        style: textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppConstants.tagline,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppTheme.ink,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Students move from exam setup to a structured daily plan, active recall, quizzes, flashcards, and progress tracking in one mobile flow.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppTheme.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _FeatureCard(
                        icon: Icons.calendar_month_rounded,
                        title: 'Plan smarter',
                        message: 'Generate daily study tasks from exam date, difficulty, and topics.',
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FeatureCard(
                        icon: Icons.layers_rounded,
                        title: 'Remember more',
                        message: 'Use flashcards and quizzes to reinforce weak areas before exams.',
                        color: AppTheme.mint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What the app solves',
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: 14),
                      ...AppConstants.startupPainPoints.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: entry.key.isEven ? AppTheme.primaryBlue : AppTheme.mint,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Create Account',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => context.go('/sign-up'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go('/sign-in'),
                    child: const Text('Sign In'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
