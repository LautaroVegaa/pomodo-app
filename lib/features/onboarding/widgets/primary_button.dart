import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? Colors.white.withValues(alpha: 0.22)
            : Colors.white,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? AppColors.buttonTextDark.withValues(alpha: 0.5)
            : AppColors.buttonTextDark,
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        style: style,
        child: Text(label),
      ),
    );
  }
}
