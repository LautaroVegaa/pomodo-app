import 'package:flutter/material.dart';

class AppColors {
  static const Color backgroundTop = Color(0xFF050B18);
  static const Color backgroundBottom = Color(0xFF02040A);
  static const Color surface = Color(0xFF0B1324);
  static const Color surfaceMuted = Color(0xFF11182A);
  static const Color onboardingBase = Color(0xFF0B0F17);
  static const Color textPrimary = Color(0xFFE7ECF5);
  static const Color textMuted = Color(0xFF9AA3B9);
  static const Color buttonTextDark = Color(0xFF050B18);
  static const Color accentBlue = Color(0xFF4D78FF);
}

class AppGradients {
  static const LinearGradient haze = LinearGradient(
    begin: Alignment(-0.9, -0.9),
    end: Alignment(0.9, 0.9),
    colors: [
      Color(0x2E121A28),
      Colors.transparent,
      Color(0x190A1220),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  static const RadialGradient primaryStain = RadialGradient(
    center: Alignment(0.95, 0.85),
    radius: 1.2,
    colors: [
      Color(0x732E6BFF),
      Color(0x381C3F9E),
      Colors.transparent,
    ],
    stops: [0.0, 0.55, 1.0],
  );

  static const RadialGradient secondaryBloom = RadialGradient(
    center: Alignment(0.55, 0.45),
    radius: 1.1,
    colors: [
      Color(0x2E1E4FFF),
      Colors.transparent,
    ],
  );

  static const RadialGradient lowerSpread = RadialGradient(
    center: Alignment(0.6, 1.15),
    radius: 1.35,
    colors: [
      Color(0x2E163A86),
      Colors.transparent,
    ],
  );

  static const RadialGradient edgeVignette = RadialGradient(
    center: Alignment.center,
    radius: 1.25,
    colors: [
      Colors.transparent,
      Color(0x8C05070C),
    ],
  );

  static const LinearGradient topVignette = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x8C05070C),
      Colors.transparent,
    ],
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    const textTheme = TextTheme(
      displayLarge: TextStyle(color: AppColors.textPrimary),
      displayMedium: TextStyle(color: AppColors.textPrimary),
      displaySmall: TextStyle(color: AppColors.textPrimary),
      headlineLarge: TextStyle(color: AppColors.textPrimary),
      headlineMedium: TextStyle(color: AppColors.textPrimary),
      headlineSmall: TextStyle(color: AppColors.textPrimary),
      titleLarge: TextStyle(color: AppColors.textPrimary),
      titleMedium: TextStyle(color: AppColors.textPrimary),
      titleSmall: TextStyle(color: AppColors.textPrimary),
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textPrimary),
      bodySmall: TextStyle(color: AppColors.textMuted),
      labelLarge: TextStyle(color: AppColors.textPrimary),
      labelMedium: TextStyle(color: AppColors.textPrimary),
      labelSmall: TextStyle(color: AppColors.textPrimary),
    );

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundBottom,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        surface: AppColors.surface,
        onPrimary: AppColors.buttonTextDark,
        onSurface: AppColors.textPrimary,
      ),
    );
  }
}
