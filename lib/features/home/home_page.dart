import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../app/app_theme.dart';
import '../../app/pomodoro_scope.dart';
import '../../app/settings_scope.dart';
import '../../app/stats_scope.dart';
import 'active_session_page.dart';
import '../onboarding/widgets/onboarding_scaffold.dart';
import '../pomodoro/pomodoro_controller.dart';
import '../pomodoro/session_labels.dart';
import '../settings/settings_page.dart';
import '../shared/widgets/animated_progress_bar.dart';
import '../shared/widgets/card_blur.dart';
import '../shared/widgets/stop_session_dialog.dart';
import '../stats/stats_format.dart';
import '../timer/timer_page.dart';
import '../stopwatch/stopwatch_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const _tabLabels = ['Pomodoro', 'Timer', 'Stopwatch'];

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double _bodyTopSpacing = 16;

  double _headerHeight = 0;

  void _handleHeaderSizeChanged(Size size) {
    if (!mounted) {
      return;
    }
    final double nextHeight = size.height;
    if (nextHeight == 0) {
      return;
    }
    if ((nextHeight - _headerHeight).abs() < 0.5) {
      return;
    }
    setState(() {
      _headerHeight = nextHeight;
    });
  }

  @override
  Widget build(BuildContext context) {
    final PomodoroController controller = PomodoroScope.of(context);
    return OnboardingScaffold(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ListView(
              padding: EdgeInsets.only(
                top: _headerHeight + _bodyTopSpacing,
                bottom: 24,
              ),
              physics: const ClampingScrollPhysics(),
              clipBehavior: Clip.none,
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _MeasureSize(
              onChange: _handleHeaderSizeChanged,
              child: _HeaderBlock(
                onTimerTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const TimerPage())),
                onStopwatchTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const StopwatchPage())),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock({
    required this.onTimerTap,
    required this.onStopwatchTap,
  });

  final VoidCallback? onTimerTap;
  final VoidCallback? onStopwatchTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const _Header(),
        const SizedBox(height: 24),
        _ModeTabs(
          onTimerTap: onTimerTap,
          onStopwatchTap: onStopwatchTap,
        ),
        const SizedBox(height: 24),
      ],
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

class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderObject(onChange);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _MeasureSizeRenderObject renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  _MeasureSizeRenderObject(this.onChange);

  ValueChanged<Size> onChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    final Size newSize = child?.size ?? Size.zero;
    if (_oldSize == newSize) {
      return;
    }
    _oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onChange(newSize);
    });
  }
}

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({this.onTimerTap, this.onStopwatchTap});

  final VoidCallback? onTimerTap;
  final VoidCallback? onStopwatchTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(HomePage._tabLabels.length, (index) {
        final bool selected = index == 0;
        VoidCallback? handler;
        if (index == 1) {
          handler = onTimerTap;
        } else if (index == 2) {
          handler = onStopwatchTap;
        }
        return Expanded(
          child: GestureDetector(
            onTap: handler,
            behavior: handler != null
                ? HitTestBehavior.opaque
                : HitTestBehavior.deferToChild,
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
    final settings = SettingsScope.of(context);
    final SessionType sessionType = controller.sessionType;
    final RunState runState = controller.runState;
    final bool isFocus = sessionType == SessionType.focus;
    final bool isRunning = runState == RunState.running;
    final bool isPaused = runState == RunState.paused;
    final SessionLabels sessionLabels = deriveSessionLabels(controller);
    final String statusText = sessionLabels.status;
    final Color baseTimerColor =
        Theme.of(context).textTheme.displayLarge?.color ??
        AppColors.textPrimary;
    final double timerOpacity = isRunning ? 1.0 : 0.65;
    final Color timerColor = baseTimerColor;
    final double progress = controller.progress.clamp(0.0, 1.0);
    final int remainingSeconds = controller.remainingSeconds;
    final int transitionSeed = sessionType == SessionType.focus
        ? controller.cycleCount * 2
        : controller.cycleCount * 2 + 1;

    final Color statusColor = isPaused
        ? Colors.white.withValues(alpha: 0.05)
        : isFocus
        ? Colors.white.withValues(alpha: 0.1)
        : AppColors.accentBlue.withValues(alpha: 0.12);
    final Color progressFill = isFocus
        ? AppColors.accentBlue
        : AppColors.accentBlue.withValues(alpha: 0.75);
    final Color progressGlow = isFocus
        ? AppColors.accentBlue.withValues(alpha: 0.4)
        : AppColors.accentBlue.withValues(alpha: 0.25);
    final Color progressBackground = Colors.white.withValues(
      alpha: isFocus ? 0.08 : 0.06,
    );

    final IconData primaryIcon = runState == RunState.running
        ? Icons.pause_rounded
        : Icons.play_arrow_rounded;

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

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor,
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
            TweenAnimationBuilder<double>(
              key: ValueKey<int>(remainingSeconds),
              tween: Tween<double>(begin: 0.98, end: 1.0),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: timerOpacity,
                    child: child,
                  ),
                );
              },
              child: Text(
                controller.formattedRemaining,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 68,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -2,
                  color: timerColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnimatedProgressBar(
              progress: progress,
              backgroundColor: progressBackground,
              fillColor: progressFill,
              glowColor: progressGlow,
              height: 4,
              sessionTrigger: transitionSeed,
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CircleIconButton(icon: primaryIcon, onTap: handlePrimaryTap),
                const SizedBox(width: 24),
                _CircleIconButton(
                  icon: Icons.stop_rounded,
                  onTap: () async {
                    final bool? confirmed = await showStopSessionDialog(
                      context,
                    );
                    if (confirmed == true) {
                      controller.stopConfirmed();
                      if (settings.hapticsEnabled) {
                        HapticFeedback.heavyImpact();
                      }
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
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
            key: ValueKey<int>(icon.codePoint ^ icon.hashCode),
            color: Colors.white,
            size: 30,
          ),
        ),
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
    final stats = StatsScope.of(context);
    final String studied = formatFocusDuration(stats.todayFocusMinutes);
    final String cycles = stats.todaySessions.toString();
    final String streak = stats.streakDays.toString();

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
            children: [
              _StatColumn(value: cycles, label: 'Ciclos'),
              _StatColumn(value: studied, label: 'Estudiado'),
              _StatColumn(value: streak, label: 'Racha'),
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
