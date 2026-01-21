import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../auth/login_entry_page.dart';
import 'widgets/onboarding_scaffold.dart';

class EditorialOnboardingPage extends StatefulWidget {
  const EditorialOnboardingPage({super.key});

  @override
  State<EditorialOnboardingPage> createState() => _EditorialOnboardingPageState();
}

class _EditorialOnboardingPageState extends State<EditorialOnboardingPage> {
  static const List<_EditorialSlideData> _slides = [
    _EditorialSlideData(
      lines: ['Your attention', 'drifts between', 'too many tabs.'],
      accentWord: 'attention',
      ctaStyle: _EditorialCtaStyle.arrow,
    ),
    _EditorialSlideData(
      lines: ['Pomodo brings you', 'back to one', 'focused session.'],
      accentWord: 'focused',
      ctaStyle: _EditorialCtaStyle.arrow,
    ),
    _EditorialSlideData(
      lines: ['Calm work.', 'Quiet progress.', 'Start Pomodo.'],
      accentWord: 'Calm',
      ctaStyle: _EditorialCtaStyle.button,
      buttonLabel: 'Start Pomodo',
    ),
  ];

  int _currentIndex = 0;

  void _handleNext() {
    if (_currentIndex < _slides.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginEntryPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentIndex];

    return OnboardingScaffold(
      child: Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _EditorialSlide(
                  key: ValueKey(_currentIndex),
                  data: slide,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _EditorialCta(
            style: slide.ctaStyle,
            label: slide.buttonLabel,
            onTap: slide.ctaStyle == _EditorialCtaStyle.button ? _finishOnboarding : _handleNext,
          ),
        ],
      ),
    );
  }
}

class _EditorialSlide extends StatelessWidget {
  const _EditorialSlide({super.key, required this.data});

  final _EditorialSlideData data;

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle = Theme.of(context).textTheme.displaySmall?.copyWith(
          fontSize: 36,
          height: 1.25,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
        ) ??
        const TextStyle(fontSize: 36, height: 1.25, fontWeight: FontWeight.w600);

    final TextStyle accentStyle = baseStyle.copyWith(color: AppColors.accentBlue);

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: data.lines
          .map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: RichText(
                text: _buildLineSpan(line, data.accentWord, baseStyle, accentStyle),
              ),
            ),
          )
          .toList(),
    );
  }

  TextSpan _buildLineSpan(
    String text,
    String accent,
    TextStyle baseStyle,
    TextStyle accentStyle,
  ) {
    final lowerText = text.toLowerCase();
    final lowerAccent = accent.toLowerCase();
    final index = lowerText.indexOf(lowerAccent);

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
}

class _EditorialCta extends StatelessWidget {
  const _EditorialCta({
    required this.style,
    this.label,
    required this.onTap,
  });

  final _EditorialCtaStyle style;
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case _EditorialCtaStyle.arrow:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _ArrowButton(onTap: onTap),
          ],
        );
      case _EditorialCtaStyle.button:
        return Center(
          child: _FinalButton(label: label ?? '' , onTap: onTap),
        );
    }
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
      ),
    );
  }
}

class _FinalButton extends StatelessWidget {
  const _FinalButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
    );
  }
}

class _EditorialSlideData {
  const _EditorialSlideData({
    required this.lines,
    required this.accentWord,
    required this.ctaStyle,
    this.buttonLabel,
  });

  final List<String> lines;
  final String accentWord;
  final _EditorialCtaStyle ctaStyle;
  final String? buttonLabel;
}

enum _EditorialCtaStyle { arrow, button }
