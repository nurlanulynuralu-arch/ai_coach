import 'package:flutter/material.dart';

class AdaptiveButtonRow extends StatelessWidget {
  const AdaptiveButtonRow({
    super.key,
    required this.first,
    required this.second,
    this.breakpoint = 390,
    this.spacing = 12,
  });

  final Widget first;
  final Widget second;
  final double breakpoint;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldStack = constraints.maxWidth < breakpoint;

        if (shouldStack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              first,
              SizedBox(height: spacing),
              second,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: first),
            SizedBox(width: spacing),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}
