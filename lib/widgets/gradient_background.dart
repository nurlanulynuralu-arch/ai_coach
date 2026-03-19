import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF9FCFF),
            Color(0xFFF3F9FF),
            Color(0xFFF8FFFC),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -70,
            child: _GlowBubble(
              size: 260,
              colors: const [Color(0x5539A2FF), Color(0x0039A2FF)],
            ),
          ),
          Positioned(
            top: 120,
            right: -60,
            child: _GlowBubble(
              size: 230,
              colors: const [Color(0x4436D4AE), Color(0x0036D4AE)],
            ),
          ),
          Positioned(
            left: 40,
            bottom: -40,
            child: _GlowBubble(
              size: 200,
              colors: const [Color(0x22315EFB), Color(0x00315EFB)],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.52),
                      Colors.white.withValues(alpha: 0.16),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _GridPainter(),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowBubble extends StatelessWidget {
  const _GlowBubble({
    required this.size,
    required this.colors,
  });

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.line.withValues(alpha: 0.18)
      ..strokeWidth = 1;

    const gap = 36.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
