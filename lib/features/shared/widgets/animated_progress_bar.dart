import 'package:flutter/material.dart';

class AnimatedProgressBar extends StatefulWidget {
  const AnimatedProgressBar({
    super.key,
    required this.progress,
    required this.backgroundColor,
    required this.fillColor,
    required this.glowColor,
    required this.height,
    required this.sessionTrigger,
  });

  final double progress;
  final Color backgroundColor;
  final Color fillColor;
  final Color glowColor;
  final double height;
  final int sessionTrigger;

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowOpacity;
  late final Animation<double> _glowScale;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    final CurvedAnimation curve =
        CurvedAnimation(parent: _glowController, curve: Curves.easeOut);
    _glowOpacity = Tween<double>(begin: 0.35, end: 0).animate(curve);
    _glowScale = Tween<double>(begin: 1.12, end: 1.0).animate(curve);
  }

  @override
  void didUpdateWidget(covariant AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sessionTrigger != oldWidget.sessionTrigger) {
      _glowController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(widget.height / 2);
    return SizedBox(
      height: widget.height,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: radius,
            ),
          ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: widget.progress.clamp(0.0, 1.0),
              ),
              duration: const Duration(milliseconds: 900),
              curve: Curves.linear,
              builder: (context, widthFactor, _) {
                return FractionallySizedBox(
                  widthFactor: widthFactor,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    decoration: BoxDecoration(
                      color: widget.fillColor,
                      borderRadius: radius,
                      boxShadow: [
                        BoxShadow(
                          color: widget.fillColor.withValues(alpha: 0.25),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, _) {
                  if (_glowController.isDismissed) {
                    return const SizedBox.shrink();
                  }
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Transform.scale(
                      scaleY: _glowScale.value,
                      child: Opacity(
                        opacity: _glowOpacity.value,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: radius,
                            boxShadow: [
                              BoxShadow(
                                color: widget.glowColor,
                                blurRadius: 26,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
