import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../onboarding/widgets/onboarding_scaffold.dart';
import '../settings/settings_page.dart';
import '../shared/widgets/app_bottom_nav.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  static const List<String> _ranges = ['Daily', 'Weekly', 'Monthly'];
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const _Header(),
          const SizedBox(height: 24),
          _RangeTabs(
            labels: _ranges,
            selectedIndex: _selectedIndex,
            onSelected: (index) => setState(() => _selectedIndex = index),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  _PrimaryStatsCard(rangeIndex: _selectedIndex),
                  const SizedBox(height: 24),
                  const _SecondaryStatsCard(),
                  const SizedBox(height: 32),
                  Text(
                    'Consistency is built quietly.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary.withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          AppBottomNav(
            selected: AppNavSection.stats,
            onFocusTap: () => Navigator.of(context).maybePop(),
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

class _RangeTabs extends StatelessWidget {
  const _RangeTabs({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (index) {
        final bool selected = index == selectedIndex;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelected(index),
            child: Container(
              margin: EdgeInsets.only(right: index == labels.length - 1 ? 0 : 12),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accentBlue.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  labels[index],
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

class _PrimaryStatsCard extends StatelessWidget {
  const _PrimaryStatsCard({required this.rangeIndex});

  final int rangeIndex;

  String get _title {
    switch (rangeIndex) {
      case 1:
        return 'This week';
      case 2:
        return 'This month';
      default:
        return 'Today';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 24),
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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

class _SecondaryStatsCard extends StatelessWidget {
  const _SecondaryStatsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: const [
          _SecondaryRow(label: 'Average focus session', value: '25 min'),
          SizedBox(height: 16),
          _SecondaryRow(label: 'Total focus time', value: '0h 0m'),
        ],
      ),
    );
  }
}

class _SecondaryRow extends StatelessWidget {
  const _SecondaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.75),
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
