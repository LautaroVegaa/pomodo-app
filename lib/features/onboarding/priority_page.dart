import 'package:flutter/material.dart';

import '../../app/tab_shell.dart';
import 'models/onboarding_data.dart';
import 'widgets/onboarding_scaffold.dart';
import 'widgets/option_tile.dart';
import 'widgets/primary_button.dart';

class PriorityPage extends StatefulWidget {
  const PriorityPage({super.key, required this.data});

  final OnboardingData data;

  @override
  State<PriorityPage> createState() => _PriorityPageState();
}

class _PriorityPageState extends State<PriorityPage> {
  static const _options = [
    'Energy',
    'Calmness',
    'Balance',
    'Discipline',
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
                  "What's most important to you right now?",
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
            label: 'Start Pomodo',
            enabled: _selected != null,
            onPressed: _selected == null ? null : _goToHome,
          ),
        ],
      ),
    );
  }

  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const TabShell()),
      (route) => false,
    );
  }
}
