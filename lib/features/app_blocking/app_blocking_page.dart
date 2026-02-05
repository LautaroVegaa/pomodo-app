import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_blocking_scope.dart';
import '../../app/app_theme.dart';
import '../onboarding/widgets/onboarding_scaffold.dart';
import '../../services/app_blocking/app_blocking_controller.dart';

class AppBlockingPage extends StatelessWidget {
  const AppBlockingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppBlockingController controller = AppBlockingScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return OnboardingScaffold(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const _Header(),
              const SizedBox(height: 24),
              Text(
                'App Blocking',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Block distractions while you focus.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.65),
                    ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!controller.isSupported)
                        const _InfoCard(
                          message: 'Available on iPhone (iOS 16+) only.',
                        )
                      else if (controller.requiresAuthorization)
                        _PermissionCard(onEnable: controller.requestAuthorization),
                      if (controller.isSupported)
                        _ModeCard(controller: controller),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          color: AppColors.textPrimary,
        ),
        const SizedBox(width: 8),
        Text(
          'Settings',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.controller});

  final AppBlockingController controller;

  @override
  Widget build(BuildContext context) {
    final bool isBusy = controller.isBusy;
    final bool requiresAuthorization = controller.requiresAuthorization;
    final bool canInteract = !isBusy && !requiresAuthorization;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 22),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose apps',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 18),
          Text(
            'Pick the exact apps or sites to block during focus sessions.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.65),
                ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canInteract ? () => _handleChooseApps(context) : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentBlue.withValues(alpha: 0.9),
                foregroundColor: AppColors.buttonTextDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: controller.isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Choose apps'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can change this anytime.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleChooseApps(BuildContext context) async {
    await controller.ensureGuidanceStateLoaded();
    if (!context.mounted) {
      return;
    }
    if (!controller.hasSeenGuidance) {
      final bool acknowledged = await _showGuidanceDialog(context);
      if (!acknowledged) {
        return;
      }
      await controller.markGuidanceSeen();
    }
    unawaited(controller.presentPicker());
  }

  Future<bool> _showGuidanceDialog(BuildContext context) async {
    final ThemeData theme = Theme.of(context);
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceMuted.withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Quick tip',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Recommended approach: either block all apps (easiest) or block only social media.',
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.buttonTextDark,
                backgroundColor: AppColors.accentBlue.withValues(alpha: 0.9),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.onEnable});

  final Future<void> Function() onEnable;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 22),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Screen Time permission required.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => onEnable(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Enable'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 22),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.75),
            ),
      ),
    );
  }
}
