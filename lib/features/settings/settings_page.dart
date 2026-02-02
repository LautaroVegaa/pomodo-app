import 'package:flutter/material.dart';

import '../../app/app_blocking_scope.dart';
import '../../app/app_theme.dart';
import '../../app/pomodoro_scope.dart';
import '../../app/settings_scope.dart';
import '../../services/app_blocking/app_blocking_controller.dart';
import '../app_blocking/app_blocking_page.dart';
import '../onboarding/widgets/onboarding_scaffold.dart';
import '../pomodoro/pomodoro_controller.dart';
import 'settings_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final PomodoroController controller = PomodoroScope.of(context);
    final SettingsController settings = SettingsScope.of(context);
    final AppBlockingController appBlocking = AppBlockingScope.of(context);
    final Listenable combined = Listenable.merge([controller, settings, appBlocking]);
    return AnimatedBuilder(
      animation: combined,
      builder: (context, _) {
        return OnboardingScaffold(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const _Header(),
              const SizedBox(height: 24),
              Expanded(
                child: _SettingsList(
                  controller: controller,
                  settings: settings,
                  appBlocking: appBlocking,
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

class _SettingsList extends StatelessWidget {
  const _SettingsList({
    required this.controller,
    required this.settings,
    required this.appBlocking,
  });

  final PomodoroController controller;
  final SettingsController settings;
  final AppBlockingController appBlocking;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          _SettingsCard(
            title: 'Focus & Break',
            rows: [
              _SettingsRowData(
                label: 'Focus duration',
                value: '${controller.focusMinutes} min',
                onTap: () => _editFocusDuration(context),
              ),
              _SettingsRowData(
                label: 'Break duration',
                value: '${controller.breakMinutes} min',
                onTap: () => _editBreakDuration(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsCard(
            title: 'Sessions',
            rows: [
              _SettingsRowData(
                label: 'Long break every',
                value: '${controller.longBreakEveryCycles} cycles',
                onTap: () => _editLongBreakEvery(context),
              ),
              _SettingsRowData(
                label: 'Long break duration',
                value: '${controller.longBreakMinutes} min',
                onTap: () => _editLongBreakDuration(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsCard(
            title: 'Experience',
            rows: [
              _SettingsRowData(
                label: 'Notifications',
                trailing: _SettingsSwitch(
                  value: settings.notificationsEnabled,
                  onChanged: settings.setNotificationsEnabled,
                ),
              ),
              _SettingsRowData(
                label: 'Sounds',
                trailing: _SettingsSwitch(
                  value: settings.soundsEnabled,
                  onChanged: settings.setSoundsEnabled,
                ),
              ),
              _SettingsRowData(
                label: 'Haptics',
                trailing: _SettingsSwitch(
                  value: settings.hapticsEnabled,
                  onChanged: settings.setHapticsEnabled,
                ),
              ),
              _SettingsRowData(
                label: 'App Blocking',
                value: appBlocking.mode.label,
                onTap: () => _openAppBlocking(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsCard(
            title: 'About',
            rows: [
              const _SettingsRowData(label: 'Version', value: '0.1.0'),
              _SettingsRowData(
                label: 'Privacy',
                value: 'View',
                onTap: () => _showComingSoonDialog(context, 'Privacy'),
              ),
              _SettingsRowData(
                label: 'Terms',
                value: 'View',
                onTap: () => _showComingSoonDialog(context, 'Terms'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editFocusDuration(BuildContext context) async {
    final int? value = await _showStepperDialog(
      context: context,
      title: 'Focus duration',
      initialValue: controller.focusMinutes,
      minValue: 5,
      maxValue: 90,
      step: 5,
      unitLabel: 'min',
    );
    if (value != null) {
      controller.setFocusMinutes(value);
    }
  }

  Future<void> _editBreakDuration(BuildContext context) async {
    final int? value = await _showStepperDialog(
      context: context,
      title: 'Break duration',
      initialValue: controller.breakMinutes,
      minValue: 1,
      maxValue: 30,
      step: 1,
      unitLabel: 'min',
    );
    if (value != null) {
      controller.setBreakMinutes(value);
    }
  }

  Future<void> _editLongBreakDuration(BuildContext context) async {
    final int? value = await _showStepperDialog(
      context: context,
      title: 'Long break duration',
      initialValue: controller.longBreakMinutes,
      minValue: 5,
      maxValue: 60,
      step: 5,
      unitLabel: 'min',
    );
    if (value != null) {
      controller.setLongBreakMinutes(value);
    }
  }

  Future<void> _editLongBreakEvery(BuildContext context) async {
    final int? value = await _showStepperDialog(
      context: context,
      title: 'Long break every',
      initialValue: controller.longBreakEveryCycles,
      minValue: 2,
      maxValue: 8,
      step: 1,
      unitLabel: 'cycles',
    );
    if (value != null) {
      controller.setLongBreakEveryCycles(value);
    }
  }

  Future<void> _showComingSoonDialog(BuildContext context, String title) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;
        return AlertDialog(
          backgroundColor: AppColors.surfaceMuted.withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Coming soon',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.85),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
              ),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _openAppBlocking(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AppBlockingPage()),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.rows});

  final String title;
  final List<_SettingsRowData> rows;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(rows.length, (index) {
            final data = rows[index];
            final bool isLast = index == rows.length - 1;
            return Column(
              children: [
                _SettingsRow(data: data),
                if (!isLast)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.data});

  final _SettingsRowData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final Widget? trailing = data.trailing;
    return GestureDetector(
      behavior: data.onTap == null ? HitTestBehavior.translucent : HitTestBehavior.opaque,
      onTap: data.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                data.label,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.7),
                ),
              ),
            ),
            trailing ??
                Text(
                  data.value ?? '',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary.withValues(alpha: 0.95),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRowData {
  const _SettingsRowData({
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
  });

  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final WidgetStateProperty<Color?> thumbColor =
        WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.white;
      }
      return Colors.white.withValues(alpha: 0.9);
    });
    final WidgetStateProperty<Color?> trackColor =
        WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.accentBlue.withValues(alpha: 0.6);
      }
      return Colors.white.withValues(alpha: 0.2);
    });
    return Switch(
      value: value,
      onChanged: onChanged,
      thumbColor: thumbColor,
      trackColor: trackColor,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

Future<int?> _showStepperDialog({
  required BuildContext context,
  required String title,
  required int initialValue,
  required int minValue,
  required int maxValue,
  required int step,
  required String unitLabel,
}) {
  int tempValue = initialValue.clamp(minValue, maxValue).toInt();
  return showDialog<int>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final bool canDecrease = tempValue > minValue;
          final bool canIncrease = tempValue < maxValue;
          return AlertDialog(
            backgroundColor: AppColors.surfaceMuted.withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _DialogStepperButton(
                      icon: Icons.remove_rounded,
                      enabled: canDecrease,
                      onPressed: canDecrease
                        ? () => setState(() {
                          tempValue = (tempValue - step)
                            .clamp(minValue, maxValue)
                            .toInt();
                          })
                        : null,
                    ),
                    const SizedBox(width: 18),
                    Text(
                      '$tempValue $unitLabel',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 18),
                    _DialogStepperButton(
                      icon: Icons.add_rounded,
                      enabled: canIncrease,
                      onPressed: canIncrease
                        ? () => setState(() {
                          tempValue = (tempValue + step)
                            .clamp(minValue, maxValue)
                            .toInt();
                          })
                        : null,
                    ),
                  ],
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(tempValue),
                child: Text(
                  'Save',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

class _DialogStepperButton extends StatelessWidget {
  const _DialogStepperButton({
    required this.icon,
    required this.enabled,
    this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: Colors.white.withValues(alpha: enabled ? 0.9 : 0.3)),
      ),
    );
  }
}
