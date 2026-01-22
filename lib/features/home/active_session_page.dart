import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_theme.dart';
import '../../app/pomodoro_scope.dart';
import '../../app/settings_scope.dart';
import '../onboarding/widgets/onboarding_scaffold.dart';
import '../pomodoro/pomodoro_controller.dart';
import '../settings/settings_page.dart';
import '../shared/widgets/app_bottom_nav.dart';
import '../shared/widgets/animated_progress_bar.dart';
import '../shared/widgets/stop_session_dialog.dart';
import '../stats/stats_page.dart';

class ActiveSessionPage extends StatelessWidget {
  const ActiveSessionPage({super.key});

  Future<void> _handleStop(
    BuildContext context,
    PomodoroController controller,
    bool hapticsEnabled,
  ) async {
    final bool? confirmed = await showStopSessionDialog(context);
    if (confirmed == true) {
      controller.stopConfirmed();
      if (hapticsEnabled) {
        HapticFeedback.heavyImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final PomodoroController controller = PomodoroScope.of(context);
    final settings = SettingsScope.of(context);
    final SessionType sessionType = controller.sessionType;
    final RunState runState = controller.runState;
    final bool isFocus = sessionType == SessionType.focus;
    final bool isRunning = runState == RunState.running;

    final Color timerColor = AppColors.textPrimary;
    final double timerOpacity = isRunning ? 1.0 : 0.65;
    final Color progressFill = isFocus
        ? AppColors.accentBlue
        : AppColors.accentBlue.withValues(alpha: 0.72);
    final Color progressGlow = isFocus
        ? AppColors.accentBlue.withValues(alpha: 0.42)
        : AppColors.accentBlue.withValues(alpha: 0.28);
    final Color progressBackground = Colors.white.withValues(
      alpha: isFocus ? 0.08 : 0.06,
    );
    final int remainingSeconds = controller.remainingSeconds;
    final int transitionSeed = sessionType == SessionType.focus
        ? controller.cycleCount * 2
        : controller.cycleCount * 2 + 1;
    final String labelText = isFocus ? 'Focus' : 'Break';
    final String motivational = isFocus
        ? 'Stay with one thing.'
        : 'Breathe. Then begin again.';

    void handlePrimaryTap() {
      switch (runState) {
        case RunState.running:
          controller.pause();
          if (settings.hapticsEnabled) {
            HapticFeedback.selectionClick();
          }
          break;
        case RunState.paused:
          controller.resume();
          if (settings.hapticsEnabled) {
            HapticFeedback.selectionClick();
          }
          break;
        case RunState.idle:
          controller.start();
          if (settings.hapticsEnabled) {
            HapticFeedback.lightImpact();
          }
          break;
      }
    }

    return OnboardingScaffold(
      child: Stack(
        children: [
          Positioned.fill(
            child: _LowerAura(sessionType: sessionType),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const _SessionHeader(),
              const SizedBox(height: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _StatusPill(sessionType: sessionType, runState: runState),
                    const Spacer(flex: 2),
                    _TimerReadout(
                      timeText: controller.formattedRemaining,
                      timerColor: timerColor,
                      opacity: timerOpacity,
                      remainingSeconds: remainingSeconds,
                    ),
                    const SizedBox(height: 12),
                    _SessionLabel(text: labelText),
                    const SizedBox(height: 20),
                    AnimatedProgressBar(
                      progress: controller.progress,
                      backgroundColor: progressBackground,
                      fillColor: progressFill,
                      glowColor: progressGlow,
                      height: 6,
                      sessionTrigger: transitionSeed,
                    ),
                    const SizedBox(height: 40),
                    _SessionControls(
                      runState: runState,
                      onPrimaryTap: handlePrimaryTap,
                      onStopTap: () => _handleStop(
                        context,
                        controller,
                        settings.hapticsEnabled,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      controller.durationSummary,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withValues(alpha: 0.6),
                            letterSpacing: 0.2,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(flex: 3),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        motivational,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary.withValues(alpha: 0.6),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppBottomNav(
                selected: AppNavSection.focus,
                onStatsTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const StatsPage())),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader();

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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.sessionType, required this.runState});

  final SessionType sessionType;
  final RunState runState;

  @override
  Widget build(BuildContext context) {
    final bool isFocus = sessionType == SessionType.focus;
    final bool isPaused = runState == RunState.paused;
    final String label = isPaused
        ? 'Paused'
        : isFocus
            ? 'Focus'
            : 'Break';
    final Color color = isPaused
        ? Colors.white.withValues(alpha: 0.05)
        : isFocus
            ? Colors.white.withValues(alpha: 0.1)
            : AppColors.accentBlue.withValues(alpha: 0.12);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(letterSpacing: 0.4),
      ),
    );
  }
}

class _TimerReadout extends StatelessWidget {
  const _TimerReadout({
    required this.timeText,
    required this.timerColor,
    required this.opacity,
    required this.remainingSeconds,
  });

  final String timeText;
  final Color timerColor;
  final double opacity;
  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          key: ValueKey<int>(remainingSeconds),
          tween: Tween<double>(begin: 0.97, end: 1.0),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: opacity,
                child: child,
              ),
            );
          },
          child: Text(
            timeText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 92,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -3,
                  color: timerColor,
                ),
          ),
        ),
      ],
    );
  }
}

class _SessionLabel extends StatelessWidget {
  const _SessionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.textPrimary.withValues(alpha: 0.6),
        letterSpacing: 0.6,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _SessionControls extends StatelessWidget {
  const _SessionControls({
    required this.runState,
    required this.onPrimaryTap,
    required this.onStopTap,
  });

  final RunState runState;
  final VoidCallback onPrimaryTap;
  final VoidCallback onStopTap;

  @override
  Widget build(BuildContext context) {
    final IconData primaryIcon = runState == RunState.running
        ? Icons.pause_rounded
        : Icons.play_arrow_rounded;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleButton(
          icon: primaryIcon,
          backgroundColor: AppColors.accentBlue.withValues(alpha: 0.85),
          iconColor: Colors.white,
          onTap: onPrimaryTap,
        ),
        const SizedBox(width: 24),
        _CircleButton(
          icon: Icons.stop_rounded,
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          iconColor: Colors.white.withValues(alpha: 0.9),
          onTap: onStopTap,
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              ),
            );
          },
          child: Icon(
            icon,
            key: ValueKey<int>(icon.codePoint ^ backgroundColor.hashCode),
            color: iconColor,
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _LowerAura extends StatelessWidget {
  const _LowerAura({required this.sessionType});

  final SessionType sessionType;

  @override
  Widget build(BuildContext context) {
    final bool isFocus = sessionType == SessionType.focus;
    final List<Color> colors = isFocus
        ? const [
            Color(0x442A52FF),
            Color(0x22132C5C),
            Colors.transparent,
          ]
        : const [
            Color(0x332A52FF),
            Color(0x11132C5C),
            Colors.transparent,
          ];
    return IgnorePointer(
      ignoring: true,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          width: double.infinity,
          height: 260,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, 0.95),
              radius: 0.95,
              colors: colors,
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
