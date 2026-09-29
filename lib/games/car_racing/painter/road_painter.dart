import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/car_model.dart';

class TrafficCar {
  double lane; // -1.5, -0.5, 0.5, 1.5
  double targetLane;
  double distance; // 0 (horizon) to 1.0 (player location)
  double speed; // relative speed
  Color color;
  String type; // 'sedan', 'taxi', 'truck', 'coupe'
  bool isChangingLane;
  double laneChangeProgress;

  TrafficCar({
    required this.lane,
    required this.distance,
    required this.speed,
    required this.color,
    required this.type,
    this.targetLane = 0,
    this.isChangingLane = false,
    this.laneChangeProgress = 0.0,
  });
}

class RoadProp {
  double lane; // -1.5 to 1.5
  double distance; // 0 to 1.0
  String type; // 'coin', 'nitro', 'oil', 'ramp', 'cone'
  bool collected;

  RoadProp({
    required this.lane,
    required this.distance,
    required this.type,
    this.collected = false,
  });
}

class SkidMark {
  double lane;
  double distance;
  double alpha;

  SkidMark({required this.lane, required this.distance, this.alpha = 0.6});
}

class ParticleFX {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double life; // 1.0 to 0.0
  Color color;

  ParticleFX({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.life,
    required this.color,
  });
}

class RoadPainter extends CustomPainter {
  final double playerLane; // -1.5 (far left) to 1.5 (far right)
  final double playerSpeed; // in km/h
  final double roadScrollOffset;
  final double roadCurve; // -1.0 (left) to 1.0 (right)
  final CarModel playerCar;
  final TrackType trackType;
  final WeatherType weather;
  final CameraView cameraView;
  final bool isBraking;
  final bool isDrifting;
  final bool isNitroActive;
  final double playerHealth; // 0 to 100
  final double jumpHeight; // 0 to 1.0 (airborne from ramp)
  final List<TrafficCar> traffic;
  final List<RoadProp> props;
  final List<SkidMark> skidMarks;
  final List<ParticleFX> particles;
  final double animationTick;

  RoadPainter({
    required this.playerLane,
    required this.playerSpeed,
    required this.roadScrollOffset,
    required this.roadCurve,
    required this.playerCar,
    required this.trackType,
    required this.weather,
    required this.cameraView,
    required this.isBraking,
    required this.isDrifting,
    required this.isNitroActive,
    required this.playerHealth,
    required this.jumpHeight,
    required this.traffic,
    required this.props,
    required this.skidMarks,
    required this.particles,
    required this.animationTick,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final horizonY = size.height * 0.44;
    final centerX = size.width * 0.5 + (roadCurve * size.width * 0.15);

    // 1. Draw Sky & Horizon Environment
    _drawSkyAndHorizon(canvas, size, horizonY, centerX);

    // 2. Draw 4-Lane Highway with Perspective & Curves
    _drawHighway(canvas, size, horizonY, centerX);

    // 3. Draw Skid Marks on Road
    _drawSkidMarks(canvas, size, horizonY, centerX);

    // 4. Draw Road Props (Coins, Nitro, Oil, Ramps)
    _drawProps(canvas, size, horizonY, centerX);

    // 5. Draw Traffic Cars in Perspective
    _drawTraffic(canvas, size, horizonY, centerX);

    // 6. Draw Player Vehicle / Camera Perspective
    _drawPlayerVehicle(canvas, size, horizonY);

    // 7. Draw Visual FX (Particles, Speed Streaks, Weather overlay)
    _drawVisualEffects(canvas, size, horizonY);
  }

  void _drawSkyAndHorizon(Canvas canvas, Size size, double horizonY, double centerX) {
    // Sky gradient
    late LinearGradient skyGrad;
    if (weather == WeatherType.night) {
      skyGrad = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF030712), Color(0xFF0F172A), Color(0xFF1E1B4B)],
      );
    } else if (weather == WeatherType.rainy) {
      skyGrad = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1F2937), Color(0xFF374151), Color(0xFF4B5563)],
      );
    } else {
      // Sunny
      if (trackType == TrackType.desertDunes) {
        skyGrad = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0284C7), Color(0xFF38BDF8), Color(0xFFFDE68A)],
        );
      } else {
        skyGrad = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF0284C7)],
        );
      }
    }

    final skyPaint = Paint()..shader = skyGrad.createShader(Rect.fromLTWH(0, 0, size.width, horizonY));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, horizonY), skyPaint);

    // Celestial Body (Sun / Cyber Moon)
    final sunCenter = Offset(size.width * 0.75 - (roadCurve * 30), horizonY * 0.45);
    final sunColor = weather == WeatherType.night
        ? const Color(0xFF38BDF8)
        : (weather == WeatherType.rainy ? Colors.white30 : const Color(0xFFFDE047));
    canvas.drawCircle(
      sunCenter,
      weather == WeatherType.night ? 20 : 32,
      Paint()
        ..color = sunColor.withValues(alpha: 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Mountain / City Horizon Silhouettes
    final horizonPath = Path()..moveTo(0, horizonY);
    if (trackType == TrackType.cityHighway) {
      // Futuristic City Skyline
      double x = 0;
      final step = size.width / 16;
      for (int i = 0; i <= 16; i++) {
        final bldgH = (math.sin(i * 1.5 + roadScrollOffset * 0.0005) * 35).abs() + 25;
        horizonPath.lineTo(x, horizonY - bldgH);
        horizonPath.lineTo(x + step, horizonY - bldgH);
        x += step;
      }
    } else if (trackType == TrackType.mountainRidge) {
      // Sharp Mountains
      double x = 0;
      final step = size.width / 8;
      for (int i = 0; i <= 8; i++) {
        final h = (math.sin(i * 2.1) * 55).abs() + 30;
        horizonPath.lineTo(x + step * 0.5, horizonY - h);
        horizonPath.lineTo(x + step, horizonY);
        x += step;
      }
    } else {
      // Rolling Desert Dunes
      double x = 0;
      final step = size.width / 6;
      for (int i = 0; i <= 6; i++) {
        final h = (math.sin(i * 1.2) * 25).abs() + 15;
        horizonPath.quadraticBezierTo(x + step * 0.5, horizonY - h, x + step, horizonY);
        x += step;
      }
    }
    horizonPath.lineTo(size.width, horizonY);
    horizonPath.close();

    final horizonPaint = Paint()
      ..color = (weather == WeatherType.night
              ? const Color(0xFF0F172A)
              : (trackType == TrackType.desertDunes ? const Color(0xFF78350F) : const Color(0xFF1E293B)))
          .withValues(alpha: 0.7);
    canvas.drawPath(horizonPath, horizonPaint);

    // Off-road terrain ground
    final groundPaint = Paint()
      ..color = trackType == TrackType.desertDunes
          ? const Color(0xFF92400E)
          : (weather == WeatherType.night ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFF064E3B));
    canvas.drawRect(Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY), groundPaint);
  }

  void _drawHighway(Canvas canvas, Size size, double horizonY, double centerX) {
    const horizonWidth = 50.0;
    final bottomWidth = size.width * 0.92;

    final roadPath = Path()
      ..moveTo(centerX - horizonWidth * 0.5, horizonY)
      ..lineTo(centerX + horizonWidth * 0.5, horizonY)
      ..lineTo(size.width * 0.5 + bottomWidth * 0.5, size.height)
      ..lineTo(size.width * 0.5 - bottomWidth * 0.5, size.height)
      ..close();

    // Road asphalt
    final asphaltPaint = Paint()
      ..color = weather == WeatherType.rainy ? const Color(0xFF111827) : const Color(0xFF1F2937);
    canvas.drawPath(roadPath, asphaltPaint);

    // Curbs / Rumble strips (Left & Right)
    const curbSegments = 20;
    for (int i = 0; i < curbSegments; i++) {
      final t1 = i / curbSegments;
      final t2 = (i + 1) / curbSegments;

      final y1 = horizonY + math.pow(t1, 2.2) * (size.height - horizonY);
      final y2 = horizonY + math.pow(t2, 2.2) * (size.height - horizonY);

      final w1 = horizonWidth + (bottomWidth - horizonWidth) * math.pow(t1, 2.2);
      final w2 = horizonWidth + (bottomWidth - horizonWidth) * math.pow(t2, 2.2);

      final cx1 = centerX + (size.width * 0.5 - centerX) * t1;
      final cx2 = centerX + (size.width * 0.5 - centerX) * t2;

      final isEven = ((i + (roadScrollOffset * 0.05).toInt()) % 2) == 0;
      final curbColor = isEven ? const Color(0xFFEF4444) : Colors.white;

      // Left curb
      final leftCurb = Path()
        ..moveTo(cx1 - w1 * 0.5 - 6 * t1, y1)
        ..lineTo(cx1 - w1 * 0.5, y1)
        ..lineTo(cx2 - w2 * 0.5, y2)
        ..lineTo(cx2 - w2 * 0.5 - 6 * t2, y2)
        ..close();
      canvas.drawPath(leftCurb, Paint()..color = curbColor);

      // Right curb
      final rightCurb = Path()
        ..moveTo(cx1 + w1 * 0.5, y1)
        ..lineTo(cx1 + w1 * 0.5 + 6 * t1, y1)
        ..lineTo(cx2 + w2 * 0.5 + 6 * t2, y2)
        ..lineTo(cx2 + w2 * 0.5, y2)
        ..close();
      canvas.drawPath(rightCurb, Paint()..color = curbColor);
    }

    // 3 Dashed Lane Lines (separating 4 lanes: -1.5, -0.5, 0.5, 1.5)
    final laneOffsets = [-0.5, 0.0, 0.5]; // Normalized line positions
    for (final lo in laneOffsets) {
      for (int i = 0; i < 16; i++) {
        final t = ((i * 0.0625) + (roadScrollOffset * 0.001)) % 1.0;
        if (t < 0.05) continue;

        final y = horizonY + math.pow(t, 2.2) * (size.height - horizonY);
        final w = horizonWidth + (bottomWidth - horizonWidth) * math.pow(t, 2.2);
        final cx = centerX + (size.width * 0.5 - centerX) * t;

        final lineX = cx + (lo * w * 0.48);
        final lineLen = math.max(3.0, 35.0 * math.pow(t, 2.0));
        final lineWidth = math.max(1.0, 4.0 * t);

        canvas.drawLine(
          Offset(lineX, y),
          Offset(lineX, math.min(size.height, y + lineLen)),
          Paint()
            ..color = lo == 0.0 ? const Color(0xFFFBBF24).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.7)
            ..strokeWidth = lineWidth,
        );
      }
    }
  }

  void _drawSkidMarks(Canvas canvas, Size size, double horizonY, double centerX) {
    const horizonWidth = 50.0;
    final bottomWidth = size.width * 0.92;

    for (final sm in skidMarks) {
      final t = sm.distance;
      if (t <= 0 || t >= 1.0) continue;

      final y = horizonY + math.pow(t, 2.2) * (size.height - horizonY);
      final w = horizonWidth + (bottomWidth - horizonWidth) * math.pow(t, 2.2);
      final cx = centerX + (size.width * 0.5 - centerX) * t;

      final markX = cx + (sm.lane * (w / 4.0));
      final markWidth = 8.0 * t;

      canvas.drawCircle(
        Offset(markX - 6 * t, y),
        markWidth * 0.5,
        Paint()..color = Colors.black.withValues(alpha: sm.alpha * 0.6),
      );
      canvas.drawCircle(
        Offset(markX + 6 * t, y),
        markWidth * 0.5,
        Paint()..color = Colors.black.withValues(alpha: sm.alpha * 0.6),
      );
    }
  }

  void _drawProps(Canvas canvas, Size size, double horizonY, double centerX) {
    const horizonWidth = 50.0;
    final bottomWidth = size.width * 0.92;

    for (final prop in props) {
      if (prop.collected || prop.distance < 0.05 || prop.distance > 0.98) continue;
      final t = prop.distance;

      final y = horizonY + math.pow(t, 2.2) * (size.height - horizonY);
      final w = horizonWidth + (bottomWidth - horizonWidth) * math.pow(t, 2.2);
      final cx = centerX + (size.width * 0.5 - centerX) * t;
      final propX = cx + (prop.lane * (w / 4.0));
      final scale = math.max(0.2, math.pow(t, 1.8).toDouble());

      if (prop.type == 'coin') {
        // Glowing Gold Coin with 3D spin
        final spin = math.sin(animationTick * 4.0 + prop.distance * 10);
        final coinW = (18.0 * scale * spin.abs()).clamp(3.0, 24.0);
        final coinH = 18.0 * scale;

        // Shadow
        canvas.drawOval(
          Rect.fromCenter(center: Offset(propX, y + coinH * 0.8), width: coinW * 1.2, height: 6 * scale),
          Paint()..color = Colors.black45,
        );

        // Coin Outer
        canvas.drawOval(
          Rect.fromCenter(center: Offset(propX, y), width: coinW, height: coinH),
          Paint()..color = const Color(0xFFFFD700),
        );
        // Coin Inner Glow
        canvas.drawOval(
          Rect.fromCenter(center: Offset(propX, y), width: coinW * 0.7, height: coinH * 0.7),
          Paint()..color = const Color(0xFFFFF078),
        );
      } else if (prop.type == 'nitro') {
        // Glowing Blue NOS Fuel Tank
        final tankW = 16.0 * scale;
        final tankH = 24.0 * scale;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(propX, y), width: tankW, height: tankH),
            Radius.circular(6 * scale),
          ),
          Paint()
            ..color = const Color(0xFF00E5FF)
            ..maskFilter = MaskFilter.blur(BlurStyle.solid, 4 * scale),
        );
        // Cap
        canvas.drawRect(
          Rect.fromCenter(center: Offset(propX, y - tankH * 0.55), width: tankW * 0.5, height: 4 * scale),
          Paint()..color = Colors.white,
        );
      } else if (prop.type == 'oil') {
        // Oil Slick Puddle
        final puddleW = 38.0 * scale;
        final puddleH = 18.0 * scale;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(propX, y), width: puddleW, height: puddleH),
          Paint()..color = const Color(0xFF1E1B4B).withValues(alpha: 0.85),
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(propX, y), width: puddleW * 0.6, height: puddleH * 0.5),
          Paint()..color = const Color(0xFF818CF8).withValues(alpha: 0.4),
        );
      } else if (prop.type == 'ramp') {
        // Wooden / Metal Jump Ramp
        final rampW = 32.0 * scale;
        final rampH = 14.0 * scale;
        final rampPath = Path()
          ..moveTo(propX - rampW * 0.5, y)
          ..lineTo(propX + rampW * 0.5, y)
          ..lineTo(propX + rampW * 0.4, y - rampH)
          ..lineTo(propX - rampW * 0.4, y - rampH)
          ..close();
        canvas.drawPath(rampPath, Paint()..color = const Color(0xFFF97316));
        canvas.drawPath(
          rampPath,
          Paint()
            ..color = Colors.yellow
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 * scale,
        );
      } else if (prop.type == 'cone') {
        // Traffic Cone
        final coneH = 22.0 * scale;
        final coneW = 16.0 * scale;
        final conePath = Path()
          ..moveTo(propX, y - coneH)
          ..lineTo(propX - coneW * 0.5, y)
          ..lineTo(propX + coneW * 0.5, y)
          ..close();
        canvas.drawPath(conePath, Paint()..color = const Color(0xFFEA580C));
        // White reflective strip
        canvas.drawRect(
          Rect.fromCenter(center: Offset(propX, y - coneH * 0.4), width: coneW * 0.45, height: 4 * scale),
          Paint()..color = Colors.white,
        );
      }
    }
  }

  void _drawTraffic(Canvas canvas, Size size, double horizonY, double centerX) {
    const horizonWidth = 50.0;
    final bottomWidth = size.width * 0.92;

    // Sort by distance so closer cars render on top
    final sorted = List<TrafficCar>.from(traffic)..sort((a, b) => a.distance.compareTo(b.distance));

    for (final car in sorted) {
      if (car.distance < 0.05 || car.distance > 1.05) continue;
      final t = car.distance;

      final y = horizonY + math.pow(t, 2.2) * (size.height - horizonY);
      final w = horizonWidth + (bottomWidth - horizonWidth) * math.pow(t, 2.2);
      final cx = centerX + (size.width * 0.5 - centerX) * t;

      final carX = cx + (car.lane * (w / 4.0));
      final scale = math.max(0.18, math.pow(t, 1.9).toDouble());

      final isTruck = car.type == 'truck';
      final carW = (isTruck ? 44.0 : 36.0) * scale;
      final carH = (isTruck ? 60.0 : 34.0) * scale;

      // Shadow
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(carX, y + 4 * scale), width: carW * 1.1, height: carH * 0.6),
          Radius.circular(6 * scale),
        ),
        Paint()..color = Colors.black54,
      );

      // Chassis Body
      final bodyRect = Rect.fromCenter(center: Offset(carX, y - carH * 0.3), width: carW, height: carH);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bodyRect, Radius.circular(6 * scale)),
        Paint()..color = car.color,
      );

      // Rear Windshield
      final windowRect = Rect.fromCenter(center: Offset(carX, y - carH * 0.5), width: carW * 0.7, height: carH * 0.35);
      canvas.drawRRect(
        RRect.fromRectAndRadius(windowRect, Radius.circular(4 * scale)),
        Paint()..color = const Color(0xFF0F172A),
      );

      // Red Taillights
      final lightSize = 5.0 * scale;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(carX - carW * 0.38, y - 4 * scale), width: lightSize * 1.5, height: lightSize),
          Radius.circular(2 * scale),
        ),
        Paint()
          ..color = const Color(0xFFFF2222)
          ..maskFilter = MaskFilter.blur(BlurStyle.solid, 3 * scale),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(carX + carW * 0.38, y - 4 * scale), width: lightSize * 1.5, height: lightSize),
          Radius.circular(2 * scale),
        ),
        Paint()
          ..color = const Color(0xFFFF2222)
          ..maskFilter = MaskFilter.blur(BlurStyle.solid, 3 * scale),
      );

      // Taxi Roof Sign or Truck details
      if (car.type == 'taxi') {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(carX, y - carH * 0.8), width: carW * 0.3, height: 6 * scale),
            Radius.circular(2 * scale),
          ),
          Paint()..color = const Color(0xFFFBBF24),
        );
      }
    }
  }

  void _drawPlayerVehicle(Canvas canvas, Size size, double horizonY) {
    if (cameraView == CameraView.hood) {
      // Hood camera: Draw only front hood edges
      _drawHoodView(canvas, size);
      return;
    }

    if (cameraView == CameraView.cockpit) {
      // Cockpit camera: Draw interior dashboard & steering
      _drawCockpitView(canvas, size);
      return;
    }

    // Default: Third-Person Chase Cam
    final carY = size.height * 0.82 - (jumpHeight * 120.0);
    final carX = size.width * 0.5 + (playerLane * (size.width * 0.92 / 4.0));

    const carW = 76.0;
    const carH = 110.0;
    final tiltAngle = isDrifting ? (playerLane > 0 ? 0.15 : -0.15) : (playerLane * 0.04);

    canvas.save();
    canvas.translate(carX, carY);
    canvas.rotate(tiltAngle);

    // 1. Neon Underglow
    final underglowPaint = Paint()
      ..color = playerCar.underglowColor.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 20), width: carW * 1.3, height: carH * 0.7),
      underglowPaint,
    );

    // 2. Ground Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 25), width: carW * 1.1, height: carH * 0.7),
        const Radius.circular(16),
      ),
      Paint()..color = Colors.black87,
    );

    // 3. Wide Tires (Rear Left & Right)
    final tirePaint = Paint()..color = const Color(0xFF111827);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(-carW * 0.48, 20), width: 14, height: 32),
        const Radius.circular(4),
      ),
      tirePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(carW * 0.48, 20), width: 14, height: 32),
        const Radius.circular(4),
      ),
      tirePaint,
    );

    // 4. Main Vehicle Chassis Body
    final chassisPath = Path()
      ..moveTo(-carW * 0.38, -carH * 0.48)
      ..quadraticBezierTo(0, -carH * 0.54, carW * 0.38, -carH * 0.48)
      ..lineTo(carW * 0.46, carH * 0.35)
      ..quadraticBezierTo(0, carH * 0.42, -carW * 0.46, carH * 0.35)
      ..close();

    final bodyPaint = Paint()..color = playerCar.primaryColor;
    canvas.drawPath(chassisPath, bodyPaint);

    // Carbon fiber roof / Metallic shading
    final roofPath = Path()
      ..moveTo(-carW * 0.28, -carH * 0.25)
      ..lineTo(carW * 0.28, -carH * 0.25)
      ..lineTo(carW * 0.32, carH * 0.12)
      ..lineTo(-carW * 0.32, carH * 0.12)
      ..close();
    canvas.drawPath(roofPath, Paint()..color = const Color(0xFF0F172A));

    // Rear Windshield
    final rearGlassPath = Path()
      ..moveTo(-carW * 0.26, carH * 0.08)
      ..lineTo(carW * 0.26, carH * 0.08)
      ..lineTo(carW * 0.30, carH * 0.26)
      ..lineTo(-carW * 0.30, carH * 0.26)
      ..close();
    canvas.drawPath(
      rearGlassPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF0284C7).withValues(alpha: 0.8), const Color(0xFF0F172A)],
        ).createShader(Rect.fromCenter(center: const Offset(0, 15), width: carW, height: 30)),
    );

    // 5. Sports Spoiler / Aerodynamic Wing
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, carH * 0.36), width: carW * 0.95, height: 8),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.black,
    );

    // 6. Glowing Red Tail Lights (Brighter on Brake)
    final brakeGlow = isBraking ? 1.0 : 0.6;
    final brakeColor = Color.lerp(const Color(0xFF880000), const Color(0xFFFF0033), brakeGlow)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(-carW * 0.35, carH * 0.34), width: 18, height: 7),
        const Radius.circular(2),
      ),
      Paint()
        ..color = brakeColor
        ..maskFilter = MaskFilter.blur(BlurStyle.solid, isBraking ? 8 : 4),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(carW * 0.35, carH * 0.34), width: 18, height: 7),
        const Radius.circular(2),
      ),
      Paint()
        ..color = brakeColor
        ..maskFilter = MaskFilter.blur(BlurStyle.solid, isBraking ? 8 : 4),
    );

    // 7. Dual Nitro Boost Exhaust Flames (When NOS Active)
    if (isNitroActive) {
      final flameH = 30.0 + (math.sin(animationTick * 20) * 8);
      final flamePaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFF00E5FF), Color(0xFF3B82F6), Colors.transparent],
        ).createShader(Rect.fromLTWH(-20, carH * 0.38, 40, flameH));

      // Left exhaust flame
      final leftFlame = Path()
        ..moveTo(-carW * 0.22, carH * 0.38)
        ..lineTo(-carW * 0.18, carH * 0.38 + flameH)
        ..lineTo(-carW * 0.14, carH * 0.38)
        ..close();
      canvas.drawPath(leftFlame, flamePaint);

      // Right exhaust flame
      final rightFlame = Path()
        ..moveTo(carW * 0.14, carH * 0.38)
        ..lineTo(carW * 0.18, carH * 0.38 + flameH)
        ..lineTo(carW * 0.22, carH * 0.38)
        ..close();
      canvas.drawPath(rightFlame, flamePaint);
    }

    // 8. Damage Scratches & Smoke if health < 70%
    if (playerHealth < 70.0) {
      canvas.drawLine(
        const Offset(-carW * 0.2, -10),
        const Offset(-carW * 0.05, 15),
        Paint()
          ..color = Colors.black87
          ..strokeWidth = 2.5,
      );
      canvas.drawLine(
        const Offset(carW * 0.15, -20),
        const Offset(carW * 0.3, 0),
        Paint()
          ..color = Colors.black87
          ..strokeWidth = 2.0,
      );
    }

    canvas.restore();
  }

  void _drawHoodView(Canvas canvas, Size size) {
    final hoodPath = Path()
      ..moveTo(size.width * 0.2, size.height)
      ..lineTo(size.width * 0.35, size.height * 0.88)
      ..lineTo(size.width * 0.65, size.height * 0.88)
      ..lineTo(size.width * 0.8, size.height)
      ..close();

    canvas.drawPath(hoodPath, Paint()..color = playerCar.primaryColor);
    canvas.drawPath(
      hoodPath,
      Paint()
        ..color = Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _drawCockpitView(Canvas canvas, Size size) {
    // Interior Dashboard
    final dashRect = Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28);
    canvas.drawRect(dashRect, Paint()..color = const Color(0xFF0F172A));

    // Windshield frame
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 16, size.height),
      Paint()..color = const Color(0xFF020617),
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - 16, 0, 16, size.height),
      Paint()..color = const Color(0xFF020617),
    );

    // Steering Wheel in center
    final wheelCenter = Offset(size.width * 0.32, size.height * 0.88);
    canvas.drawCircle(
      wheelCenter,
      50,
      Paint()
        ..color = const Color(0xFF1E293B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14,
    );
    // Steering badge
    canvas.drawCircle(wheelCenter, 14, Paint()..color = playerCar.primaryColor);
  }

  void _drawVisualEffects(Canvas canvas, Size size, double horizonY) {
    // 1. Particle Effects (Smoke, Sparks, Boost)
    for (final p in particles) {
      if (p.life <= 0) continue;
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.size * p.life,
        Paint()..color = p.color.withValues(alpha: p.life * 0.8),
      );
    }

    // 2. High Speed Motion Blur Streaks (Above 140 km/h)
    if (playerSpeed > 140.0) {
      final streakIntensity = ((playerSpeed - 140.0) / 160.0).clamp(0.0, 1.0);
      final streakPaint = Paint()
        ..color = Colors.white.withValues(alpha: streakIntensity * 0.25)
        ..strokeWidth = 2.0;

      for (int i = 0; i < 12; i++) {
        final sx = (i * (size.width / 11) + math.sin(animationTick * 10 + i) * 20).clamp(0.0, size.width);
        final sy = horizonY + (math.cos(i * 3 + animationTick * 8) * 80).abs();
        canvas.drawLine(Offset(sx, sy), Offset(sx, sy + 60 * streakIntensity), streakPaint);
      }
    }

    // 3. Rain overlay
    if (weather == WeatherType.rainy) {
      final rainPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 1.5;

      for (int i = 0; i < 35; i++) {
        final rx = (i * 27 + animationTick * 400) % size.width;
        final ry = (i * 43 + animationTick * 900) % size.height;
        canvas.drawLine(Offset(rx, ry), Offset(rx - 4, ry + 18), rainPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant RoadPainter oldDelegate) => true;
}
