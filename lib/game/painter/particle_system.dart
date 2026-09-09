import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/bubble_color.dart';
import 'bubble_painter.dart';

/// Single burst particle from a popping bubble
class BubbleParticle {
  Offset position;
  Offset velocity;
  final Color color;
  final double initialRadius;
  double life; // 1.0 -> 0.0
  final double decayRate;

  BubbleParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.initialRadius,
    this.life = 1.0,
    required this.decayRate,
  });

  bool update(double dt) {
    position += velocity * dt;
    velocity = Offset(velocity.dx * 0.96, velocity.dy * 0.96 + 180 * dt); // slight gravity
    life -= decayRate * dt;
    return life > 0;
  }

  void paint(Canvas canvas) {
    if (life <= 0) return;
    final r = initialRadius * life;
    final paint = Paint()
      ..color = color.withValues(alpha: life.clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, r, paint);
  }
}

/// Floating score / combo popup label
class ScorePopup {
  Offset position;
  final String text;
  final Color color;
  double life; // 1.0 -> 0.0
  final double scale;

  ScorePopup({
    required this.position,
    required this.text,
    required this.color,
    this.life = 1.0,
    this.scale = 1.0,
  });

  bool update(double dt) {
    position = Offset(position.dx, position.dy - 55 * dt); // float upwards
    life -= 0.9 * dt;
    return life > 0;
  }

  void paint(Canvas canvas) {
    if (life <= 0) return;
    final opacity = life.clamp(0.0, 1.0);

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color.withValues(alpha: opacity),
        fontSize: (18 * scale).clamp(14.0, 28.0),
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.5 * opacity),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final drawOffset = Offset(
      position.dx - (textPainter.width / 2),
      position.dy - (textPainter.height / 2),
    );

    textPainter.paint(canvas, drawOffset);
  }
}

/// Disconnected floating bubble dropping down with physics
class FallingBubble {
  Offset position;
  Offset velocity;
  final double radius;
  final BubbleType type;
  double opacity = 1.0;

  FallingBubble({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.type,
  });

  bool update(double dt, double screenHeight) {
    position += velocity * dt;
    velocity = Offset(velocity.dx * 0.98, velocity.dy + (800 * dt)); // Gravity
    if (position.dy > screenHeight - 100) {
      opacity -= 2.0 * dt;
    }
    return position.dy < screenHeight + 50 && opacity > 0;
  }

  void paint(Canvas canvas) {
    BubblePainter.paintBubble(
      canvas,
      position,
      radius,
      type,
      opacity: opacity.clamp(0.0, 1.0),
    );
  }
}

/// Particle management container
class ParticleSystem {
  final List<BubbleParticle> particles = [];
  final List<ScorePopup> scorePopups = [];
  final List<FallingBubble> fallingBubbles = [];
  final math.Random _random = math.Random();

  void spawnPopBurst(Offset center, Color color, double radius) {
    final count = 10 + _random.nextInt(6);
    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 120 + _random.nextDouble() * 220;
      final vx = math.cos(angle) * speed;
      final vy = math.sin(angle) * speed;
      final pRadius = 3.0 + _random.nextDouble() * (radius * 0.28);

      particles.add(
        BubbleParticle(
          position: center,
          velocity: Offset(vx, vy),
          color: color,
          initialRadius: pRadius,
          decayRate: 1.6 + _random.nextDouble() * 0.8,
        ),
      );
    }
  }

  void spawnScore(Offset center, String text, Color color, {double scale = 1.0}) {
    scorePopups.add(
      ScorePopup(
        position: center,
        text: text,
        color: color,
        scale: scale,
      ),
    );
  }

  void spawnFallingBubble(Offset center, BubbleType type, double radius) {
    final vx = (_random.nextDouble() - 0.5) * 160;
    final vy = -80 - (_random.nextDouble() * 120); // initial upward pop before falling
    fallingBubbles.add(
      FallingBubble(
        position: center,
        velocity: Offset(vx, vy),
        radius: radius,
        type: type,
      ),
    );
  }

  void update(double dt, double screenHeight) {
    particles.removeWhere((p) => !p.update(dt));
    scorePopups.removeWhere((s) => !s.update(dt));
    fallingBubbles.removeWhere((f) => !f.update(dt, screenHeight));
  }

  void paint(Canvas canvas) {
    for (final fb in fallingBubbles) {
      fb.paint(canvas);
    }
    for (final p in particles) {
      p.paint(canvas);
    }
    for (final sp in scorePopups) {
      sp.paint(canvas);
    }
  }

  void clear() {
    particles.clear();
    scorePopups.clear();
    fallingBubbles.clear();
  }
}
