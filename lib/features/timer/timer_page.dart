import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../app/quote_scope.dart';
import '../../app/settings_scope.dart';
import '../../app/timer_scope.dart';
import '../onboarding/widgets/onboarding_scaffold.dart';
import '../settings/settings_page.dart';
import '../shared/widgets/animated_progress_bar.dart';
import '../shared/widgets/card_blur.dart';
import '../shared/widgets/flow_focus_shell.dart';
import '../shared/widgets/quote_block.dart';
import 'timer_controller.dart';
import '../quotes/quote_rotation_controller.dart';

class TimerPage extends StatelessWidget {
  const TimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TimerController controller = TimerScope.of(context);
    final settings = SettingsScope.of(context);
    final quoteController = QuoteScope.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        Widget buildTimerCard() {
          return _TimerCardShell(
            timeText: controller.formattedRemaining,
            progress: controller.progress,
            runState: controller.runState,
            sessionSeed: controller.selectedMinutes,
            onPrimaryTap: () => _handlePrimaryAction(controller, quoteController),
            onStopTap: controller.stop,
          );
        }
        return OnboardingScaffold(
          child: FlowFocusShell(
            enabled: settings.flowFocusLandscapeEnabled,
            isRunning: controller.runState == TimerRunState.running,
            childPortraitBuilder: (_) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const _Header(),
                const SizedBox(height: 24),
                buildTimerCard(),
                const SizedBox(height: 32),
                _DurationSelector(
                  value: controller.selectedMinutes.toDouble(),
                  enabled: controller.canAdjustDuration,
                  onChanged: (value) =>
                      controller.setDurationMinutes(value.round()),
                ),
                const SizedBox(height: 32),
                const QuoteBlock(),
              ],
            ),
            childFlowFocusBuilder: (_) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: buildTimerCard(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handlePrimaryAction(
    TimerController controller,
    QuoteRotationController quoteController,
  ) {
    switch (controller.runState) {
      case TimerRunState.running:
        controller.pause();
        break;
      case TimerRunState.paused:
        controller.resume();
        break;
      case TimerRunState.idle:
      case TimerRunState.completed:
        quoteController.rotate(reason: 'timer_start');
        controller.start();
        break;
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
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          ),
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

class _TimerCardShell extends StatelessWidget {
  const _TimerCardShell({
    required this.timeText,
    required this.progress,
    required this.runState,
    required this.sessionSeed,
    required this.onPrimaryTap,
    required this.onStopTap,
  });

  final String timeText;
  final double progress;
  final TimerRunState runState;
  final int sessionSeed;
  final VoidCallback onPrimaryTap;
  final VoidCallback onStopTap;

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
              'Timer',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    letterSpacing: 0.4,
                  ),
            ),
          ),
          const SizedBox(height: 24),
          TweenAnimationBuilder<double>(
            key: ValueKey<String>(timeText),
            tween: Tween<double>(begin: 0.98, end: 1.0),
            duration: const Duration(milliseconds: 250),
            builder: (context, scale, child) {
              final bool isPaused = runState == TimerRunState.paused;
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
              timeText,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 68,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -2,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedProgressBar(
            progress: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            fillColor: AppColors.accentBlue,
            glowColor: AppColors.accentBlue.withValues(alpha: 0.35),
            height: 4,
            sessionTrigger: sessionSeed,
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CircleButton(
                icon: runState == TimerRunState.running
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                onTap: onPrimaryTap,
              ),
              const SizedBox(width: 24),
              _CircleButton(
                icon: Icons.stop_rounded,
                onTap: onStopTap,
              ),
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
        child: Icon(
          icon,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

class _DurationSelector extends StatelessWidget {
  const _DurationSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color trackColor = Colors.white.withValues(alpha: 0.15);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Duration',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: AppColors.accentBlue,
              inactiveTrackColor: trackColor,
              disabledActiveTrackColor: AppColors.accentBlue,
              disabledInactiveTrackColor: trackColor,
              disabledThumbColor: Colors.white,
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: value,
              min: TimerController.minMinutes.toDouble(),
              max: TimerController.maxMinutes.toDouble(),
              onChanged: enabled ? onChanged : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${value.toInt()} min session',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
