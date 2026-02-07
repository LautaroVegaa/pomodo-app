import 'package:flutter/material.dart';

class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color baseColor = Colors.white.withValues(alpha: selected ? 0.08 : 0.02);
    final Color borderColor = Colors.white.withValues(alpha: selected ? 0.35 : 0.08);
    final TextStyle textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: selected ? 0.95 : 0.78),
          letterSpacing: 0.15,
        ) ??
        TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: selected ? 0.95 : 0.78),
          letterSpacing: 0.15,
        );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: baseColor,
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 40,
                    offset: const Offset(0, 26),
                  ),
                ]
              : null,
        ),
        child: Text(label, style: textStyle),
      ),
    );
  }
}
