import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../app/pomodoro_scope.dart';
import '../onboarding/widgets/onboarding_scaffold.dart';
import '../pomodoro/pomodoro_controller.dart';
import '../settings/settings_page.dart';
import '../shared/widgets/app_bottom_nav.dart';
import '../shared/widgets/stop_session_dialog.dart';
import '../stats/stats_page.dart';

class ActiveSessionPage extends StatelessWidget {
  const ActiveSessionPage({super.key});

  Future<void> _handleStop(
    BuildContext context,
    PomodoroController controller,
  ) async {
    final bool? confirmed = await showStopSessionDialog(context);
    if (confirmed == true) {
      controller.stopConfirmed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final PomodoroController controller = PomodoroScope.of(context);
    final SessionType sessionType = controller.sessionType;
    final RunState runState = controller.runState;
    final bool isFocus = sessionType == SessionType.focus;
    final bool isRunning = runState == RunState.running;
    final bool isPaused = runState == RunState.paused;

    final Color timerColor = AppColors.textPrimary.withValues(
      alpha: isRunning ? 1.0 : 0.7,
    );
    final Color progressColor = isFocus
        ? AppColors.accentBlue
        : AppColors.accentBlue.withValues(alpha: 0.65);
    final String statusText = isPaused
        ? 'Paused'
        : isFocus
        ? 'Focus'
        : 'Break';
    final String labelText = isFocus ? 'Focus' : 'Break';
    final String motivational = isFocus
        ? 'Stay with one thing.'
        : 'Breathe. Then begin again.';

    return OnboardingScaffold(
      child: Stack(
        children: [
          const Positioned.fill(child: _LowerAura()),
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
                    _StatusPill(label: statusText),
                    const Spacer(flex: 2),
                    _TimerReadout(
                      timeText: controller.formattedRemaining,
                      timerColor: timerColor,
                    ),
                    const SizedBox(height: 12),
                    _SessionLabel(text: labelText),
                    const SizedBox(height: 20),
                    _SessionProgressBar(
                      progress: controller.progress,
                      color: progressColor,
                    ),
                    const SizedBox(height: 40),
                    _SessionControls(
                      runState: runState,
                      onPrimaryTap: controller.togglePause,
                      onStopTap: () => _handleStop(context, controller),
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
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
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
  const _TimerReadout({required this.timeText, required this.timerColor});

  final String timeText;
  final Color timerColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeText,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: 92,
            fontWeight: FontWeight.w600,
            letterSpacing: -3,
            color: timerColor,
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

class _SessionProgressBar extends StatelessWidget {
  const _SessionProgressBar({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
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
        child: Icon(icon, color: iconColor, size: 30),
      ),
    );
  }
}

class _LowerAura extends StatelessWidget {
  const _LowerAura();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          height: 260,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, 0.95),
              radius: 0.95,
              colors: [
                Color(0x332A52FF),
                Color(0x11132C5C),
                Colors.transparent,
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
