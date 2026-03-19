import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/study_plan_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/section_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: GradientBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user != null && !user.emailVerified)
                  InfoBanner(
                    title: 'Verify your email',
                    message:
                        'Verification helps secure account recovery and confirms your sign-up flow for grading.',
                    icon: Icons.mark_email_unread_outlined,
                    actionLabel: 'Resend verification',
                    onAction: () async {
                      await context.read<AuthProvider>().resendVerificationEmail();
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verification email sent.')),
                      );
                    },
                  ),
                if (user != null && !user.emailVerified) const SizedBox(height: 18),
                const SectionHeader(
                  title: 'Account and app',
                  subtitle: 'Review your Firebase account status, app information, and support details.',
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SettingsTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Profile',
                        subtitle: 'Name, subjects, and study goals',
                        onTap: () => context.go('/profile'),
                      ),
                      const Divider(height: 28),
                      _SettingsTile(
                        icon: Icons.verified_user_outlined,
                        title: 'Refresh verification status',
                        subtitle: 'Reload your Firebase account and Firestore profile',
                        onTap: () async {
                          await context.read<AuthProvider>().reloadUser();
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Account status refreshed.')),
                          );
                        },
                      ),
                      const Divider(height: 28),
                      const _SettingsTile(
                        icon: Icons.rule_rounded,
                        title: 'Study system',
                        subtitle: 'Study plans, flashcards, quizzes, and progress are stored in Firestore',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader(
                  title: 'About the MVP',
                  subtitle: 'Useful information for demoing, grading, and GitHub submission.',
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppConstants.aboutBlurb,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.ink,
                            ),
                      ),
                      const SizedBox(height: 18),
                      const _InfoRow(label: 'Support', value: AppConstants.supportEmail),
                      const _InfoRow(label: 'Theme', value: 'Material 3 with custom startup branding'),
                      const _InfoRow(label: 'Backend', value: 'Firebase Auth and Cloud Firestore'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Firebase Auth keeps the user signed in after restart until they explicitly sign out.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _signOut(context),
                          icon: const Icon(Icons.logout_rounded),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.deepSlate,
                          ),
                          label: const Text('Sign out'),
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

  void _signOut(BuildContext context) {
    context.read<AuthProvider>().logout();
    context.read<StudyPlanProvider>().reset();
    context.read<QuizProvider>().resetQuiz();
    context.go('/sign-in');
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.blueSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.primaryBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (onTap != null) const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedText,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.ink,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
