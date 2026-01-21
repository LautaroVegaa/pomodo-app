import 'package:flutter/material.dart';

import 'models/onboarding_data.dart';
import 'goal_page.dart';
import 'widgets/onboarding_scaffold.dart';
import 'widgets/primary_button.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  static const _bullets = [
    'Plan focused sessions',
    'Protect your energy',
    'Track gentle progress',
    'Build steady habits',
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome to Pomodo',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                ),
                const SizedBox(height: 24),
                ..._bullets.map(
                  (text) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _Bullet(text: text),
                  ),
                ),
              ],
            ),
          ),
          PrimaryButton(
            label: 'Continue',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GoalPage(data: const OnboardingData()),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6, right: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.4,
                ),
          ),
        ),
      ],
    );
  }
}
