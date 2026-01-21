import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

enum AppNavSection { focus, stats }

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selected,
    this.onFocusTap,
    this.onStatsTap,
  });

  final AppNavSection selected;
  final VoidCallback? onFocusTap;
  final VoidCallback? onStatsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
            label: 'Focus',
            selected: selected == AppNavSection.focus,
            onTap: onFocusTap,
          ),
          _NavItem(
            label: 'Stats',
            selected: selected == AppNavSection.stats,
            onTap: onStatsTap,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected
        ? Colors.white
        : AppColors.textPrimary.withValues(alpha: 0.5);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 4,
            width: 32,
            decoration: BoxDecoration(
              color: selected ? AppColors.accentBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
