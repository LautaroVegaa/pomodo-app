import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../auth/login_entry_page.dart';
import 'widgets/onboarding_scaffold.dart';
import 'widgets/option_tile.dart';
import 'widgets/primary_button.dart';

class ExtendedOnboardingFlowPage extends StatefulWidget {
  const ExtendedOnboardingFlowPage({super.key});

  @override
  State<ExtendedOnboardingFlowPage> createState() => _ExtendedOnboardingFlowPageState();
}

class _ExtendedOnboardingFlowPageState extends State<ExtendedOnboardingFlowPage> {
  static const int _minAge = 16;
  static const int _maxAge = 70;
  static const int _defaultAge = 25;

  static const List<String> _goalOptions = [
    'Improve focus',
    'Reduce screen time',
    'Build better habits',
    'Be more productive',
    'Study or work better',
  ];

  static const List<String> _obstacleOptions = [
    'Social media',
    'Lack of focus',
    'Procrastination',
    'Low motivation',
    'Constant interruptions',
  ];

  static const List<String> _screenTimeOptions = [
    'Less than 2 hours',
    '2–4 hours',
    '4–6 hours',
    'More than 6 hours',
  ];

  final FixedExtentScrollController _ageController =
      FixedExtentScrollController(initialItem: _defaultAge - _minAge);
  int _selectedAge = _defaultAge;
  final Set<String> _selectedGoals = <String>{};
  final Set<String> _selectedObstacles = <String>{};
  String? _selectedScreenTime;
  int _stepIndex = 0;

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFinalStep = _stepIndex == 3;
    final String ctaLabel = isFinalStep ? 'Start Pomodo' : 'Next';

    return OnboardingScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey(_stepIndex),
                child: _buildStepContent(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: ctaLabel,
            enabled: _isNextEnabled,
            onPressed: _isNextEnabled ? _handleNext : null,
          ),
        ],
      ),
    );
  }

  bool get _isNextEnabled {
    switch (_stepIndex) {
      case 0:
        return true;
      case 1:
        return _selectedGoals.isNotEmpty;
      case 2:
        return _selectedObstacles.isNotEmpty;
      case 3:
        return _selectedScreenTime != null;
      default:
        return true;
    }
  }

  void _handleNext() {
    if (_stepIndex < 3) {
      setState(() => _stepIndex += 1);
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginEntryPage()),
    );
  }

  Widget _buildStepContent() {
    switch (_stepIndex) {
      case 0:
        return _AgeStep(
          controller: _ageController,
          selectedAge: _selectedAge,
          minAge: _minAge,
          maxAge: _maxAge,
          onAgeChanged: (value) => setState(() => _selectedAge = value),
        );
      case 1:
        return _MultiSelectStep(
          title: 'What is your main goal with Pomodo?',
          options: _goalOptions,
          selectedValues: _selectedGoals,
          onToggle: (option) {
            setState(() {
              if (_selectedGoals.contains(option)) {
                _selectedGoals.remove(option);
              } else {
                _selectedGoals.add(option);
              }
            });
          },
        );
      case 2:
        return _MultiSelectStep(
          title: 'What usually gets in your way?',
          options: _obstacleOptions,
          selectedValues: _selectedObstacles,
          onToggle: (option) {
            setState(() {
              if (_selectedObstacles.contains(option)) {
                _selectedObstacles.remove(option);
              } else {
                _selectedObstacles.add(option);
              }
            });
          },
        );
      case 3:
        return _SingleSelectStep(
          title: 'How much time do you spend on your phone daily?',
          options: _screenTimeOptions,
          selected: _selectedScreenTime,
          onSelect: (option) => setState(() => _selectedScreenTime = option),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _AgeStep extends StatelessWidget {
  const _AgeStep({
    required this.controller,
    required this.selectedAge,
    required this.minAge,
    required this.maxAge,
    required this.onAgeChanged,
  });

  final FixedExtentScrollController controller;
  final int selectedAge;
  final int minAge;
  final int maxAge;
  final ValueChanged<int> onAgeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How old are you?',
          style: _headingStyle(context),
        ),
        const SizedBox(height: 28),
        _PomodoAgePicker(
          controller: controller,
          minAge: minAge,
          maxAge: maxAge,
          selectedAge: selectedAge,
          onAgeSelected: onAgeChanged,
        ),
        const SizedBox(height: 24),
        Text(
          '$selectedAge years old',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }
}

class _MultiSelectStep extends StatelessWidget {
  const _MultiSelectStep({
    required this.title,
    required this.options,
    required this.selectedValues,
    required this.onToggle,
  });

  final String title;
  final List<String> options;
  final Set<String> selectedValues;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: _headingStyle(context),
        ),
        const SizedBox(height: 28),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final String option = options[index];
              return OptionTile(
                label: option,
                selected: selectedValues.contains(option),
                onTap: () => onToggle(option),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SingleSelectStep extends StatelessWidget {
  const _SingleSelectStep({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final String title;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: _headingStyle(context),
        ),
        const SizedBox(height: 28),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final String option = options[index];
              return OptionTile(
                label: option,
                selected: selected == option,
                onTap: () => onSelect(option),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PomodoAgePicker extends StatelessWidget {
  const _PomodoAgePicker({
    required this.controller,
    required this.minAge,
    required this.maxAge,
    required this.selectedAge,
    required this.onAgeSelected,
  });

  final FixedExtentScrollController controller;
  final int minAge;
  final int maxAge;
  final int selectedAge;
  final ValueChanged<int> onAgeSelected;

  List<int> get _ages => List<int>.generate(maxAge - minAge + 1, (index) => minAge + index);

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ) ??
        const TextStyle(fontSize: 22, fontWeight: FontWeight.w600);

    final TextStyle inactiveStyle = baseStyle.copyWith(
      fontWeight: FontWeight.w400,
      color: Colors.white.withValues(alpha: 0.38),
    );
    final TextStyle activeStyle = baseStyle.copyWith(
      color: Colors.white,
      fontSize: (baseStyle.fontSize ?? 22) + 2,
    );

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 45,
              offset: const Offset(0, 30),
            ),
          ],
        ),
        child: SizedBox(
          height: 220,
          child: CupertinoPicker(
            scrollController: controller,
            itemExtent: 48,
            magnification: 1.05,
            squeeze: 1.2,
            useMagnifier: true,
            backgroundColor: Colors.transparent,
            selectionOverlay: const _AgeSelectionOverlay(),
            onSelectedItemChanged: (index) => onAgeSelected(_ages[index]),
            children: _ages
                .map(
                  (age) => Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: age == selectedAge ? activeStyle : inactiveStyle,
                      child: Text('$age years'),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _AgeSelectionOverlay extends StatelessWidget {
  const _AgeSelectionOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.center,
        child: Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.black.withValues(alpha: 0.35),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
        ),
      ),
    );
  }
}
TextStyle _headingStyle(BuildContext context) {
  return Theme.of(context).textTheme.displaySmall?.copyWith(
        fontSize: 34,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ) ??
      const TextStyle(fontSize: 34, height: 1.25, fontWeight: FontWeight.w700);
}
