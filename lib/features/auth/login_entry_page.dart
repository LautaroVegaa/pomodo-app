import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../home/home_page.dart';
import '../onboarding/widgets/onboarding_scaffold.dart';

class LoginEntryPage extends StatelessWidget {
  const LoginEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: _Headline(),
            ),
          ),
          const SizedBox(height: 48),
          _EntryButton(
            label: 'Continue with Apple',
            prefix: const Icon(Icons.apple),
            onTap: () => _goHome(context),
          ),
          const SizedBox(height: 16),
          _EntryButton(
            label: 'Continue with Google',
            prefix: Text(
              'G',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            onTap: () => _goHome(context),
          ),
          const SizedBox(height: 16),
          _EntryButton(
            label: 'Continue without account',
            muted: true,
            onTap: () => _goHome(context),
          ),
        ],
      ),
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }
}

class _Headline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle = Theme.of(context).textTheme.displaySmall?.copyWith(
          fontSize: 36,
          height: 1.25,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
        ) ??
        const TextStyle(fontSize: 36, height: 1.25, fontWeight: FontWeight.w600);

    final accentStyle = baseStyle.copyWith(color: AppColors.accentBlue);

    TextSpan span(String text) {
      final lower = text.toLowerCase();
      const accent = 'calm';
      final index = lower.indexOf(accent);
      if (index == -1) {
        return TextSpan(text: text, style: baseStyle);
      }
      return TextSpan(
        children: [
          if (index > 0)
            TextSpan(
              text: text.substring(0, index),
              style: baseStyle,
            ),
          TextSpan(
            text: text.substring(index, index + accent.length),
            style: accentStyle,
          ),
          if (index + accent.length < text.length)
            TextSpan(
              text: text.substring(index + accent.length),
              style: baseStyle,
            ),
        ],
      );
    }

    const lines = [
      'One calm space',
      'to focus',
      'and move forward.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: lines
          .map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: RichText(text: span(line)),
            ),
          )
          .toList(),
    );
  }
}

class _EntryButton extends StatelessWidget {
  const _EntryButton({
    required this.label,
    this.prefix,
    this.muted = false,
    required this.onTap,
  });

  final String label;
  final Widget? prefix;
  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = muted
        ? AppColors.surfaceMuted.withValues(alpha: 0.65)
        : AppColors.surfaceMuted.withValues(alpha: 0.9);
    final Color border = (muted ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.08));
    final Color textColor =
        muted ? AppColors.textPrimary.withValues(alpha: 0.85) : AppColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            if (prefix != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 24,
                  child: Center(
                    child: DefaultTextStyle.merge(
                      style: TextStyle(color: textColor),
                      child: IconTheme(
                        data: IconThemeData(color: textColor, size: 20),
                        child: prefix!,
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
              ),
            ),
            if (prefix != null)
              const SizedBox(
                width: 24,
              ),
          ],
        ),
      ),
    );
  }
}
