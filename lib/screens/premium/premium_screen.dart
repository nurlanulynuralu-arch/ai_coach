import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/feature_row.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/primary_button.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isPremium = authProvider.user?.isPremium ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
      ),
      body: GradientBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F172A),
                      Color(0xFF2558F5),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Premium growth plan',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Upgrade to Premium',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Unlock deeper revision tools, richer AI content generation, and expanded analytics for advanced exam prep.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$7.99',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '/ month',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.82),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Free vs Premium',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ink,
                        ),
                      ),
                      SizedBox(height: 18),
                      FeatureRow(
                        feature: 'AI study plans',
                        freeLabel: '1 active',
                        premiumLabel: 'Unlimited',
                      ),
                      Divider(),
                      FeatureRow(
                        feature: 'Quiz depth',
                        freeLabel: 'Starter',
                        premiumLabel: 'Advanced',
                      ),
                      Divider(),
                      FeatureRow(
                        feature: 'Smart revision',
                        freeLabel: '-',
                        premiumLabel: 'Included',
                      ),
                      Divider(),
                      FeatureRow(
                        feature: 'Analytics',
                        freeLabel: 'Basic',
                        premiumLabel: 'Detailed',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why it matters for the startup',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'This screen demonstrates a clear monetization model, investor-friendly upsell path, and expansion room for richer AI features later.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: const [
                          _PitchChip(label: 'Recurring revenue'),
                          _PitchChip(label: 'Retention mechanics'),
                          _PitchChip(label: 'Scalable feature ladder'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: isPremium ? 'Premium active' : 'Start 7-day trial',
                  icon: Icons.workspace_premium_rounded,
                  onPressed: () => _handlePremiumAction(context, isPremium: isPremium),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handlePremiumAction(BuildContext context, {required bool isPremium}) {
    if (isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Premium is already active on this account.')),
      );
      context.go('/profile');
      return;
    }

    context.read<AuthProvider>().setPremium(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Premium access has been activated for this account.')),
    );
    context.go('/profile');
  }
}

class _PitchChip extends StatelessWidget {
  const _PitchChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
