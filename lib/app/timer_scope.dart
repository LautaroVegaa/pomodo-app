import 'package:flutter/material.dart';

import '../features/timer/timer_controller.dart';
import '../services/completion_audio_service.dart';

class TimerScope extends StatefulWidget {
  const TimerScope({
    super.key,
    required this.child,
    required this.audioService,
  });

  final Widget child;
  final CompletionAudioService audioService;

  static TimerController of(BuildContext context) {
    final _TimerInherited? inherited = context
        .dependOnInheritedWidgetOfExactType<_TimerInherited>();
    assert(inherited != null, 'TimerScope.of() called with no TimerScope');
    return inherited!.controller;
  }

  @override
  State<TimerScope> createState() => _TimerScopeState();
}

class _TimerScopeState extends State<TimerScope> with WidgetsBindingObserver {
  late final TimerController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = TimerController(audioService: widget.audioService);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _controller.handleLifecycleChange(state);
  }

  @override
  Widget build(BuildContext context) {
    return _TimerInherited(controller: _controller, child: widget.child);
  }
}

class _TimerInherited extends InheritedNotifier<TimerController> {
  const _TimerInherited({required this.controller, required super.child})
    : super(notifier: controller);

  final TimerController controller;
}
