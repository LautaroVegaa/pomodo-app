import 'package:flutter/material.dart';

import 'models/onboarding_data.dart';
import 'priority_page.dart';
import 'widgets/onboarding_scaffold.dart';
import 'widgets/option_tile.dart';
import 'widgets/primary_button.dart';

class GoalPage extends StatefulWidget {
  const GoalPage({super.key, required this.data});

  final OnboardingData data;

  @override
  State<GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> {
  static const _options = [
    'Improve focus',
    'Manage stress',
    'Build consistency',
  ];

  String? _selected;

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What do you want to achieve with Pomodo?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                ),
                const SizedBox(height: 32),
                ..._options.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: OptionTile(
                      label: option,
                      selected: _selected == option,
                      onTap: () {
                        setState(() => _selected = option);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          PrimaryButton(
            label: 'Continue',
            enabled: _selected != null,
            onPressed: _selected == null
                ? null
                : () {
                    final updated = widget.data.copyWith(goal: _selected);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PriorityPage(data: updated),
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }
}
