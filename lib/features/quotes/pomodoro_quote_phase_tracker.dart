import '../pomodoro/pomodoro_controller.dart';

enum PomodoroQuotePhase { focus, shortBreak, longBreak }

class PomodoroQuotePhaseTracker {
  PomodoroQuotePhase? _lastPhase;

  PomodoroQuotePhase get currentPhase => _lastPhase ?? PomodoroQuotePhase.focus;

  bool shouldRotate(SessionType sessionType, bool isLongBreakSession) {
    final PomodoroQuotePhase next = _phaseFor(sessionType, isLongBreakSession);
    final bool rotate = _lastPhase != null && next != _lastPhase;
    _lastPhase = next;
    return rotate;
  }

  PomodoroQuotePhase _phaseFor(
    SessionType sessionType,
    bool isLongBreakSession,
  ) {
    if (sessionType == SessionType.focus) {
      return PomodoroQuotePhase.focus;
    }
    return isLongBreakSession
        ? PomodoroQuotePhase.longBreak
        : PomodoroQuotePhase.shortBreak;
  }
}
