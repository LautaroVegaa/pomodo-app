import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../app/pomodoro_scope.dart';
import 'active_session_page.dart';
import '../onboarding/widgets/onboarding_scaffold.dart';
import '../pomodoro/pomodoro_controller.dart';
import '../settings/settings_page.dart';
import '../shared/widgets/app_bottom_nav.dart';
import '../shared/widgets/stop_session_dialog.dart';
import '../stats/stats_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _tabLabels = ['Pomodoro', 'Timer', 'Stopwatch'];

  @override
  Widget build(BuildContext context) {
    final PomodoroController controller = PomodoroScope.of(context);
    return OnboardingScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _Header(),
          const SizedBox(height: 24),
          _ModeTabs(),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  _TimerCard(
                    controller: controller,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ActiveSessionPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _QuoteCard(),
                  const SizedBox(height: 24),
                  const _StatsCard(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          AppBottomNav(
            selected: AppNavSection.focus,
            onStatsTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const StatsPage())),
          ),
        ],
      ),
    );
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

class _ModeTabs extends StatelessWidget {
  const _ModeTabs();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(HomePage._tabLabels.length, (index) {
        final bool selected = index == 0;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: index == HomePage._tabLabels.length - 1 ? 0 : 12,
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accentBlue.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                HomePage._tabLabels[index],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : AppColors.textPrimary.withValues(alpha: 0.65),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _TimerCard extends StatelessWidget {
  const _TimerCard({required this.controller, this.onTap});

  final PomodoroController controller;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final SessionType sessionType = controller.sessionType;
    final RunState runState = controller.runState;
    final bool isFocus = sessionType == SessionType.focus;
    final bool isRunning = runState == RunState.running;
    final bool isPaused = runState == RunState.paused;

    final String statusText = isPaused
        ? 'Paused'
        : isFocus
        ? 'Focus'
        : 'Break';
    final Color baseTimerColor =
        Theme.of(context).textTheme.displayLarge?.color ??
        AppColors.textPrimary;
    final Color timerColor = baseTimerColor.withValues(
      alpha: isRunning ? 1.0 : 0.7,
    );
    final double progress = controller.progress.clamp(0.0, 1.0);

    final IconData primaryIcon = runState == RunState.running
        ? Icons.pause_rounded
        : Icons.play_arrow_rounded;
    final VoidCallback primaryAction;
    switch (runState) {
      case RunState.running:
        primaryAction = controller.pause;
        break;
      case RunState.paused:
        primaryAction = controller.resume;
        break;
      case RunState.idle:
        primaryAction = controller.start;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusText,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(letterSpacing: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              controller.formattedRemaining,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 68,
                fontWeight: FontWeight.w600,
                letterSpacing: -2,
                color: timerColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(2),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CircleIconButton(icon: primaryIcon, onTap: primaryAction),
                const SizedBox(width: 24),
                _CircleIconButton(
                  icon: Icons.stop_rounded,
                  onTap: () async {
                    final bool? confirmed = await showStopSessionDialog(
                      context,
                    );
                    if (confirmed == true) {
                      controller.stopConfirmed();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

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

class _QuoteCard extends StatelessWidget {
  const _QuoteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white70,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'El foco es un músculo: si no lo usás, se atrofia.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas de hoy',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              _StatColumn(value: '0', label: 'Ciclos'),
              _StatColumn(value: '0h 0m', label: 'Estudiado'),
              _StatColumn(value: '0', label: 'Racha'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}
