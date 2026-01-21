class OnboardingData {
  const OnboardingData({this.goal, this.priority});

  final String? goal;
  final String? priority;

  OnboardingData copyWith({String? goal, String? priority}) {
    return OnboardingData(
      goal: goal ?? this.goal,
      priority: priority ?? this.priority,
    );
  }
}
