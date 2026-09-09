import 'package:flutter/material.dart';

/// Enum representing the bubble colors and special types
enum BubbleType {
  pink,
  blue,
  green,
  red,
  purple,
  orange,
  yellow,
  // Special booster types
  bomb,
  rainbow,
  fireball,
}

extension BubbleTypeExtension on BubbleType {
  bool get isSpecial =>
      this == BubbleType.bomb ||
      this == BubbleType.rainbow ||
      this == BubbleType.fireball;

  /// Main primary color
  Color get primaryColor {
    switch (this) {
      case BubbleType.pink:
        return const Color(0xFFFF52A2);
      case BubbleType.blue:
        return const Color(0xFF2E86DE);
      case BubbleType.green:
        return const Color(0xFF1DD1A1);
      case BubbleType.red:
        return const Color(0xFFEE5253);
      case BubbleType.purple:
        return const Color(0xFF5F27CD);
      case BubbleType.orange:
        return const Color(0xFFFF9F43);
      case BubbleType.yellow:
        return const Color(0xFFFECA57);
      case BubbleType.bomb:
        return const Color(0xFF2C3E50);
      case BubbleType.rainbow:
        return const Color(0xFFFF6B81);
      case BubbleType.fireball:
        return const Color(0xFFFF3838);
    }
  }

  /// Dark shadow / border accent color for realistic depth
  Color get darkShade {
    switch (this) {
      case BubbleType.pink:
        return const Color(0xFFC0176D);
      case BubbleType.blue:
        return const Color(0xFF104F8C);
      case BubbleType.green:
        return const Color(0xFF108E6C);
      case BubbleType.red:
        return const Color(0xFFB32324);
      case BubbleType.purple:
        return const Color(0xFF341775);
      case BubbleType.orange:
        return const Color(0xFFC76915);
      case BubbleType.yellow:
        return const Color(0xFFC49615);
      case BubbleType.bomb:
        return const Color(0xFF1A252F);
      case BubbleType.rainbow:
        return const Color(0xFF6C5CE7);
      case BubbleType.fireball:
        return const Color(0xFFB71540);
    }
  }

  /// Bright highlight color for specular reflection
  Color get lightHighlight {
    switch (this) {
      case BubbleType.pink:
        return const Color(0xFFFFD1E6);
      case BubbleType.blue:
        return const Color(0xFFD6EEFF);
      case BubbleType.green:
        return const Color(0xFFDDFBF4);
      case BubbleType.red:
        return const Color(0xFFFFD8D8);
      case BubbleType.purple:
        return const Color(0xFFEADBFF);
      case BubbleType.orange:
        return const Color(0xFFFFEEDD);
      case BubbleType.yellow:
        return const Color(0xFFFFF7D6);
      case BubbleType.bomb:
        return const Color(0xFFBDC3C7);
      case BubbleType.rainbow:
        return Colors.white;
      case BubbleType.fireball:
        return const Color(0xFFFFFA65);
    }
  }

  /// Display title for UI
  String get title {
    switch (this) {
      case BubbleType.pink:
        return 'Pink';
      case BubbleType.blue:
        return 'Blue';
      case BubbleType.green:
        return 'Green';
      case BubbleType.red:
        return 'Red';
      case BubbleType.purple:
        return 'Purple';
      case BubbleType.orange:
        return 'Orange';
      case BubbleType.yellow:
        return 'Yellow';
      case BubbleType.bomb:
        return 'Bomb';
      case BubbleType.rainbow:
        return 'Rainbow';
      case BubbleType.fireball:
        return 'Fireball';
    }
  }
}
