import 'pomodoro_controller.dart';

class SessionLabels {
  const SessionLabels({required this.status, required this.primary});

  final String status;
  final String primary;
}

SessionLabels deriveSessionLabels(PomodoroController controller) {
  final bool isPaused = controller.runState == RunState.paused;
  final bool isFocus = controller.sessionType == SessionType.focus;
  final bool isLongBreak = controller.isLongBreakSession;
  final String baseLabel = isFocus
      ? 'Focus'
      : isLongBreak
          ? 'Long Break'
          : 'Break';
  final String statusLabel = isPaused ? 'Paused' : baseLabel;
  return SessionLabels(status: statusLabel, primary: baseLabel);
}
