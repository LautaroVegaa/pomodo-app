import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_theme.dart';

class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Container(
        color: AppColors.onboardingBase,
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppGradients.haze),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppGradients.primaryStain),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppGradients.secondaryBloom),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppGradients.lowerSpread),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppGradients.edgeVignette),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppGradients.topVignette),
              ),
            ),
            Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
