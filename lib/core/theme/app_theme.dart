import 'package:flutter/material.dart';

class AppTheme {
  // Palette
  static const Color backgroundDark = Color(0xFF0A0E17);
  static const Color surfaceDark = Color(0xFF131B2A);
  static const Color cardDark = Color(0xFF1A233A);
  static const Color borderGlow = Color(0xFF2E3D60);

  // Neon Accents
  static const Color neonCyan = Color(0xFF00F2FE);
  static const Color neonPurple = Color(0xFF9B51E0);
  static const Color neonGreen = Color(0xFF00E676);
  static const Color neonGold = Color(0xFFFFD700);
  static const Color neonPink = Color(0xFFFF2A85);
  static const Color neonOrange = Color(0xFFFF7A00);

  // Gradients
  static const LinearGradient cyberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)],
  );

  static const LinearGradient purplePinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFDF00), Color(0xFFDAA520)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A233A), Color(0xFF131B2A)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D1322), Color(0xFF060910)],
  );

  // ThemeData
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonPurple,
        surface: surfaceDark,
        surfaceContainerHighest: cardDark,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderGlow, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonCyan,
          foregroundColor: Colors.black,
          elevation: 6,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // Box Decorations
  static BoxDecoration neonBoxDecoration({
    Color borderColor = neonCyan,
    double borderRadius = 16,
    Color backgroundColor = cardDark,
    bool glow = true,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor.withValues(alpha: 0.6), width: 1.5),
      boxShadow: glow
          ? [
              BoxShadow(
                color: borderColor.withValues(alpha: 0.25),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }
}
