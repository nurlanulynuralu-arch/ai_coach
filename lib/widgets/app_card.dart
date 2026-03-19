import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.gradient,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final decoratedChild = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: color ?? (gradient == null ? Colors.white.withValues(alpha: 0.78) : null),
        gradient: gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.96),
                AppTheme.softSurface.withValues(alpha: 0.9),
              ],
            ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: gradient == null
              ? Colors.white.withValues(alpha: 0.94)
              : Colors.white.withValues(alpha: 0.18),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12233146),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
          BoxShadow(
            color: Color(0x0D246BFD),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap == null) {
      return decoratedChild;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: decoratedChild,
      ),
    );
  }
}
