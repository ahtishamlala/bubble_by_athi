import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game_controller.dart';
import '../models/grid_position.dart';
import 'bubble_painter.dart';

/// Full game canvas painter rendering grid, projectile, aim trajectory, particles, and shooter
class GameBoardPainter extends CustomPainter {
  final GameController controller;
  final double animationValue;

  GameBoardPainter({
    required this.controller,
    required this.animationValue,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    controller.updateLayout(size);

    // 1. Draw Background Gradient
    _paintBackground(canvas, size);

    // 2. Draw Hexagonal Grid of Bubbles
    _paintGrid(canvas);

    // 3. Draw Aim Trajectory & Arrow
    if (controller.isAiming && controller.state == GameState.playing) {
      _paintTrajectory(canvas);
    }

    // 4. Draw In-Flight Projectile
    if (controller.projectilePos != null && controller.projectileType != null) {
      BubblePainter.paintBubble(
        canvas,
        controller.projectilePos!,
        controller.bubbleRadius,
        controller.projectileType!,
      );
    }

    // 5. Draw Shooter Station & Chamber
    _paintShooter(canvas);

    // 6. Draw Falling Bubbles, Popping Particles, and Score Labels
    controller.particleSystem.paint(canvas);
  }

  void _paintBackground(Canvas canvas, Size size) {
    final bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF8CA6DB),
        const Color(0xFFB993D6).withValues(alpha: 0.9),
      ],
    );

    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(bgRect, Paint()..shader = bgGradient.createShader(bgRect));

    // Subtle danger line at bottom (where bubbles shouldn't cross)
    final dangerY = controller.boardHeight - (controller.bubbleRadius * 6.5);
    final dangerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(16, dangerY), Offset(size.width - 16, dangerY), dangerPaint);
  }

  void _paintGrid(Canvas canvas) {
    for (int r = 0; r < controller.maxRows; r++) {
      final maxCols = GridPosition.maxColsFor(r, baseCols: controller.baseCols);
      for (int c = 0; c < maxCols; c++) {
        final bType = controller.grid[r][c];
        if (bType != null) {
          final center = GridPosition.getCenterOffset(
            r,
            c,
            controller.bubbleRadius,
            controller.gridStartX,
          );
          BubblePainter.paintBubble(
            canvas,
            center,
            controller.bubbleRadius,
            bType,
          );
        }
      }
    }
  }

  void _paintTrajectory(Canvas canvas) {
    if (controller.trajectoryPoints.length < 2) return;

    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = const Color(0xFF6C5CE7).withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(controller.trajectoryPoints[0].dx, controller.trajectoryPoints[0].dy);

    for (int i = 1; i < controller.trajectoryPoints.length; i++) {
      final pt = controller.trajectoryPoints[i];
      path.lineTo(pt.dx, pt.dy);

      if (i % 2 == 0) {
        final dotRadius = 3.5 + (math.sin(animationValue * math.pi * 2 + i) * 0.8);
        canvas.drawCircle(pt, dotRadius, dotPaint);
      }
    }
    canvas.drawPath(path, linePaint);

    // Draw Aim Arrow at the end
    final endPoint = controller.trajectoryPoints.last;
    final prevPoint = controller.trajectoryPoints[controller.trajectoryPoints.length - 2];
    final dirAngle = math.atan2(endPoint.dy - prevPoint.dy, endPoint.dx - prevPoint.dx);

    _paintArrowHead(canvas, endPoint, dirAngle);
  }

  void _paintArrowHead(Canvas canvas, Offset tip, double angle) {
    const arrowLength = 18.0;

    final p1 = Offset(
      tip.dx - arrowLength * math.cos(angle - 0.5),
      tip.dy - arrowLength * math.sin(angle - 0.5),
    );
    final p2 = Offset(
      tip.dx - arrowLength * math.cos(angle + 0.5),
      tip.dy - arrowLength * math.sin(angle + 0.5),
    );

    final arrowPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(tip.dx - (arrowLength * 0.6 * math.cos(angle)), tip.dy - (arrowLength * 0.6 * math.sin(angle)))
      ..lineTo(p2.dx, p2.dy)
      ..close();

    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(arrowPath, arrowPaint);
  }

  void _paintShooter(Canvas canvas) {
    final sPos = controller.shooterPos;
    final r = controller.bubbleRadius;

    // Shooter pedestal / glow ring
    final pedestalPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(sPos, r * 1.35, pedestalPaint);

    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(sPos, r * 1.35, ringPaint);

    // Next preview bubble behind / below shooter
    final nextPos = Offset(sPos.dx - (r * 2.5), sPos.dy + (r * 0.4));
    BubblePainter.paintBubble(
      canvas,
      nextPos,
      r * 0.75,
      controller.nextBubble,
    );

    // Current bubble in chamber (only if not currently launched in flight)
    if (controller.state != GameState.shooting) {
      final activeType = controller.activeBooster ?? controller.currentBubble;
      BubblePainter.paintBubble(
        canvas,
        sPos,
        r,
        activeType,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GameBoardPainter oldDelegate) => true;
}
