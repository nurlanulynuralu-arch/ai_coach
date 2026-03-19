import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CoachBottomNav extends StatelessWidget {
  const CoachBottomNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    const items = <({IconData icon, String label})>[
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.analytics_rounded, label: 'Progress'),
      (icon: Icons.person_rounded, label: 'Profile'),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.deepSlate.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26233146),
                blurRadius: 30,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Row(
            children: List<Widget>.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => onDestinationSelected(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.74),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              item.label,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.74),
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
