import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

Future<bool?> showStopSessionDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const StopSessionDialog(),
  );
}

class StopSessionDialog extends StatelessWidget {
  const StopSessionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceMuted.withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Stop session?',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      content: Text(
        'This will reset the timer back to 25:00 focus.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary.withValues(alpha: 0.7),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Stop',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
