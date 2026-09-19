import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/bubble_color.dart';

/// Highly optimized vector shader painter that renders realistic 3D glossy bubbles
class BubblePainter {
  /// Paints a single glossy 3D bubble at [center] with [radius]
  static void paintBubble(
    Canvas canvas,
    Offset center,
    double radius,
    BubbleType type, {
    double opacity = 1.0,
    double scale = 1.0,
    bool showHighlight = true,
  }) {
    if (opacity <= 0 || scale <= 0) return;

    final r = radius * scale;
    final primary = type.primaryColor.withValues(alpha: opacity);
    final dark = type.darkShade.withValues(alpha: opacity);
    final light = type.lightHighlight.withValues(alpha: opacity);

    // 1. Subtle drop shadow (Hardware accelerated, no blur filter lag)
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.16 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center.translate(0, r * 0.12), r * 0.95, shadowPaint);

    // 2. Base Sphere with Radial Gradient (Illuminated 3D sphere)
    final sphereRect = Rect.fromCircle(center: center, radius: r);
    final sphereGradient = RadialGradient(
      center: const Alignment(-0.35, -0.35),
      radius: 0.85,
      colors: [
        light,
        primary,
        dark,
      ],
      stops: const [0.0, 0.55, 1.0],
    );

    final basePaint = Paint()
      ..shader = sphereGradient.createShader(sphereRect)
      ..isAntiAlias = true;
    canvas.drawCircle(center, r, basePaint);

    // 3. Dark Outer Border / Rim
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, r * 0.06)
      ..color = dark.withValues(alpha: 0.4 * opacity)
      ..isAntiAlias = true;
    canvas.drawCircle(center, r - (r * 0.03), rimPaint);

    // 4. Inner Bottom-Right Bounce Light (Reflective Glass)
    final bounceGlow = RadialGradient(
      center: const Alignment(0.4, 0.4),
      radius: 0.5,
      colors: [
        Colors.white.withValues(alpha: 0.35 * opacity),
        Colors.transparent,
      ],
    );
    final bouncePaint = Paint()
      ..shader = bounceGlow.createShader(sphereRect)
      ..isAntiAlias = true;
    canvas.drawCircle(center, r * 0.9, bouncePaint);

    // 5. Specular Top-Left Highlight (Fast vector crescent/oval)
    if (showHighlight) {
      final highlightCenter = Offset(
        center.dx - (r * 0.3),
        center.dy - (r * 0.3),
      );

      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.85 * opacity)
        ..isAntiAlias = true;

      canvas.drawOval(
        Rect.fromCenter(
          center: highlightCenter,
          width: r * 0.5,
          height: r * 0.35,
        ),
        highlightPaint,
      );

      // Mini secondary specular dot
      final dotCenter = Offset(
        center.dx + (r * 0.3),
        center.dy + (r * 0.3),
      );
      final dotPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.45 * opacity)
        ..isAntiAlias = true;
      canvas.drawCircle(dotCenter, r * 0.09, dotPaint);
    }

    // Special icons for boosters
    if (type.isSpecial) {
      _paintSpecialIcon(canvas, center, r, type, opacity);
    }
  }

  static void _paintSpecialIcon(
    Canvas canvas,
    Offset center,
    double r,
    BubbleType type,
    double opacity,
  ) {
    final iconPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95 * opacity)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    if (type == BubbleType.bomb) {
      // Draw bomb symbol
      canvas.drawCircle(center, r * 0.38, iconPaint);
      final fusePaint = Paint()
        ..color = const Color(0xFFFECA57).withValues(alpha: opacity)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(center.dx, center.dy - r * 0.35),
        Offset(center.dx + r * 0.25, center.dy - r * 0.6),
        fusePaint,
      );
    } else if (type == BubbleType.rainbow) {
      // Star icon
      final starPath = Path();
      const points = 5;
      final outerR = r * 0.45;
      final innerR = r * 0.22;
      for (int i = 0; i < points * 2; i++) {
        final rad = (i * math.pi / points) - (math.pi / 2);
        final curR = i.isEven ? outerR : innerR;
        final x = center.dx + curR * math.cos(rad);
        final y = center.dy + curR * math.sin(rad);
        if (i == 0) {
          starPath.moveTo(x, y);
        } else {
          starPath.lineTo(x, y);
        }
      }
      starPath.close();
      canvas.drawPath(starPath, iconPaint);
    } else if (type == BubbleType.fireball) {
      // Fire flame icon
      final flamePath = Path();
      flamePath.moveTo(center.dx, center.dy - r * 0.5);
      flamePath.quadraticBezierTo(
        center.dx + r * 0.45,
        center.dy - r * 0.1,
        center.dx + r * 0.35,
        center.dy + r * 0.4,
      );
      flamePath.quadraticBezierTo(
        center.dx,
        center.dy + r * 0.55,
        center.dx - r * 0.35,
        center.dy + r * 0.4,
      );
      flamePath.quadraticBezierTo(
        center.dx - r * 0.45,
        center.dy - r * 0.1,
        center.dx,
        center.dy - r * 0.5,
      );
      flamePath.close();
      canvas.drawPath(flamePath, iconPaint);
    }
  }
}
