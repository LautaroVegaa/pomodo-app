import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../app/auth_scope.dart';
import '../../services/auth/auth_controller.dart';
import '../onboarding/widgets/onboarding_scaffold.dart';

class LoginEntryPage extends StatefulWidget {
  const LoginEntryPage({super.key});

  @override
  State<LoginEntryPage> createState() => _LoginEntryPageState();
}

class _LoginEntryPageState extends State<LoginEntryPage> {
  AuthController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextController = AuthScope.of(context);
    if (_controller == nextController) {
      return;
    }
    _controller?.removeListener(_handleAuthUpdates);
    _controller = nextController..addListener(_handleAuthUpdates);
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleAuthUpdates);
    super.dispose();
  }

  void _handleAuthUpdates() {
    if (!mounted) {
      return;
    }
    final controller = _controller;
    if (controller == null) {
      return;
    }
    final String? message = controller.errorMessage;
    if (message == null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
    controller.clearError();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final bool appleBusy = controller.isProviderBusy(AuthProvider.apple);
        final bool googleBusy = controller.isProviderBusy(AuthProvider.google);
        final bool isBusy = controller.isBusy;
        final bool guestAccessDisabled = !controller.canUseGuestAccess;
        final String guestAccessLabel = guestAccessDisabled
            ? 'Guest access unavailable after signing in'
            : 'Continue without account';
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
                loading: appleBusy,
                enabled: !isBusy,
                onTap: () => controller.signInWithApple(),
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
                loading: googleBusy,
                enabled: !isBusy,
                onTap: () => controller.signInWithGoogle(),
              ),
              const SizedBox(height: 16),
              _EntryButton(
                label: guestAccessLabel,
                muted: true,
                enabled: !isBusy,
                onTap: () => controller.continueWithoutAccount(),
              ),
            ],
          ),
        );
      },
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
    this.loading = false,
    this.enabled = true,
    required this.onTap,
  });

  final String label;
  final Widget? prefix;
  final bool muted;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = muted
        ? AppColors.surfaceMuted.withValues(alpha: 0.65)
        : AppColors.surfaceMuted.withValues(alpha: 0.9);
    final Color border = (muted ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.08));
    final Color textColor =
        muted ? AppColors.textPrimary.withValues(alpha: 0.85) : AppColors.textPrimary;

    final bool canTap = enabled && !loading;
    return GestureDetector(
      onTap: canTap ? onTap : null,
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
            if (prefix != null || loading)
              SizedBox(
                width: 24,
                child: Center(
                  child: loading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(textColor),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
