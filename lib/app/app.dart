import 'package:flutter/material.dart';

import '../features/onboarding/editorial_onboarding_page.dart';
import 'app_theme.dart';
import 'pomodoro_scope.dart';

class PomodoApp extends StatelessWidget {
  const PomodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return PomodoroScope(
      child: MaterialApp(
        title: 'Pomodo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const EditorialOnboardingPage(),
      ),
    );
  }
}
