import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../services/completion_banner_controller.dart';

class CompletionBannerOverlay extends StatelessWidget {
  const CompletionBannerOverlay({super.key, required this.controller, required this.child});

  final CompletionBannerController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        final bool visible = controller.isVisible;
        final CompletionBannerData? data = controller.data;
        final Widget baseChild = child ?? const SizedBox.shrink();
        return Stack(
          children: [
            baseChild,
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: AnimatedSlide(
                  duration: CompletionBannerController.animationDuration,
                  curve: Curves.easeOutCubic,
                  offset: visible ? Offset.zero : const Offset(0, -0.15),
                  child: AnimatedOpacity(
                    duration: CompletionBannerController.animationDuration,
                    curve: Curves.easeOutCubic,
                    opacity: visible ? 1 : 0,
                    child: SafeArea(
                      minimum: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: data == null
                            ? const SizedBox.shrink()
                            : _CompletionBannerCard(data: data),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CompletionBannerCard extends StatelessWidget {
  const _CompletionBannerCard({required this.data});

  final CompletionBannerData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66050B18),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
