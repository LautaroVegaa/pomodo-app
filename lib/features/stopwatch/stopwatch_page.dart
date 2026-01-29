import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_theme.dart';
import '../../app/settings_scope.dart';
import '../../app/stopwatch_scope.dart';
import '../onboarding/widgets/onboarding_scaffold.dart';
import '../settings/settings_page.dart';
import '../shared/widgets/animated_progress_bar.dart';
import '../shared/widgets/card_blur.dart';
import 'stopwatch_controller.dart';

class StopwatchPage extends StatelessWidget {
  const StopwatchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final StopwatchController controller = StopwatchScope.of(context);
    final settings = SettingsScope.of(context);
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
              _StopwatchCard(
                elapsedText: controller.formattedElapsed,
                runState: controller.runState,
                onPrimaryTap: () =>
                    _handlePrimary(controller, settings.hapticsEnabled),
                onResetTap: () =>
                    _handleReset(controller, settings.hapticsEnabled),
              ),
              const SizedBox(height: 32),
              const _MotivationalText(),
            ],
          ),
        );
      },
    );
  }

  void _handlePrimary(StopwatchController controller, bool hapticsEnabled) {
    switch (controller.runState) {
      case StopwatchRunState.idle:
        controller.start();
        if (hapticsEnabled) {
          HapticFeedback.lightImpact();
        }
        break;
      case StopwatchRunState.running:
        controller.pause();
        if (hapticsEnabled) {
          HapticFeedback.selectionClick();
        }
        break;
      case StopwatchRunState.paused:
        controller.resume();
        if (hapticsEnabled) {
          HapticFeedback.selectionClick();
        }
        break;
    }
  }

  void _handleReset(StopwatchController controller, bool hapticsEnabled) {
    controller.reset();
    if (hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Pomodō.',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          icon: Icon(
            Icons.settings_rounded,
            color: AppColors.textPrimary.withValues(alpha: 0.65),
            size: 24,
          ),
        ),
      ],
    );
  }
}

class _StopwatchCard extends StatefulWidget {
  const _StopwatchCard({
    required this.elapsedText,
    required this.runState,
    required this.onPrimaryTap,
    required this.onResetTap,
  });

  final String elapsedText;
  final StopwatchRunState runState;
  final VoidCallback onPrimaryTap;
  final VoidCallback onResetTap;

  @override
  State<_StopwatchCard> createState() => _StopwatchCardState();
}

class _StopwatchCardState extends State<_StopwatchCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.runState == StopwatchRunState.running) {
      _progressController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _StopwatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.runState == StopwatchRunState.running) {
      if (!_progressController.isAnimating) {
        _progressController.repeat(reverse: true);
      }
    } else if (oldWidget.runState == StopwatchRunState.running) {
      _progressController.stop();
      _progressController.reset();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = Colors.white.withValues(alpha: 0.08);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: buildPrimaryCardBlur(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Stopwatch',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(letterSpacing: 0.4),
            ),
          ),
          const SizedBox(height: 24),
          TweenAnimationBuilder<double>(
            key: ValueKey<String>(widget.elapsedText),
            tween: Tween<double>(begin: 0.98, end: 1.0),
            duration: const Duration(milliseconds: 250),
            builder: (context, scale, child) {
              final bool isPaused = widget.runState == StopwatchRunState.paused;
              return Transform.scale(
                scale: scale,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: isPaused ? 0.65 : 1.0,
                  child: child,
                ),
              );
            },
            child: Text(
              widget.elapsedText,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 68,
                fontWeight: FontWeight.w600,
                letterSpacing: -2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 4,
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, _) {
                final bool isRunning =
                    widget.runState == StopwatchRunState.running;
                final double progress = isRunning
                    ? 0.15 + 0.7 * _progressController.value
                    : 0.0;
                return AnimatedProgressBar(
                  progress: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  fillColor: AppColors.accentBlue,
                  glowColor: AppColors.accentBlue.withValues(alpha: 0.35),
                  height: 4,
                  sessionTrigger: widget.runState.index,
                );
              },
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CircleButton(
                icon: widget.runState == StopwatchRunState.running
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                onTap: widget.onPrimaryTap,
              ),
              const SizedBox(width: 24),
              _CircleButton(icon: Icons.stop_rounded, onTap: widget.onResetTap),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }
}

class _MotivationalText extends StatelessWidget {
  const _MotivationalText();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Stay with one thing.',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary.withValues(alpha: 0.65),
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
