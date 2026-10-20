import 'package:flutter/material.dart';

/// NetMod Dark Cyberpunk Theme.
class AppTheme {
  static const Color darkBackground = Color(0xFF0F141C);
  static const Color cardBackground = Color(0xFF181F2C);
  static const Color cardBorder = Color(0xFF263345);

  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color connectedGreen = Color(0xFF00E676);
  static const Color disconnectedGrey = Color(0xFF78909C);
  static const Color errorRed = Color(0xFFFF5252);
  static const Color warningAmber = Color(0xFFFFD600);
  static const Color accentPurple = Color(0xFF7C4DFF);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryCyan,
        secondary: connectedGreen,
        surface: cardBackground,
        error: errorRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF131922),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryCyan, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
