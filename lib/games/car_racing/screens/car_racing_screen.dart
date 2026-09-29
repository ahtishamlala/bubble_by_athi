import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../ad_manager.dart';
import '../../../core/services/arcade_hub_service.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/wallet_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/car_model.dart';
import '../painter/road_painter.dart';
import '../services/car_garage_service.dart';
import 'car_garage_screen.dart';

class CarRacingScreen extends StatefulWidget {
  final int levelNumber;
  final CarGameMode gameMode;

  const CarRacingScreen({
    super.key,
    this.levelNumber = 1,
    this.gameMode = CarGameMode.career,
  });

  @override
  State<CarRacingScreen> createState() => _CarRacingScreenState();
}

class _CarRacingScreenState extends State<CarRacingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _gameLoop;
  final math.Random _random = math.Random();

  // Vehicle Dynamics & State
  double _playerLane = 0.0; // -1.5 (far left) to 1.5 (far right)
  double _playerSpeed = 0.0; // km/h
  double _roadScroll = 0.0;
  double _roadCurve = 0.0;
  double _targetCurve = 0.0;
  double _playerHealth = 100.0;
  double _nitroTank = 100.0; // 0 to 100%
  double _jumpHeight = 0.0;
  double _jumpVelocity = 0.0;

  // Race Progression
  double _distanceTraveled = 0.0; // in meters
  late double _targetDistance; // in meters
  int _score = 0;
  int _coinsEarned = 0;
  int _nearMissCount = 0;
  int _driftPoints = 0;
  double _timeRemaining = 60.0; // for time attack

  // Input States
  bool _isSteeringLeft = false;
  bool _isSteeringRight = false;
  bool _isAccelerating = true;
  bool _isBraking = false;
  bool _isNitroActive = false;
  bool _isDrifting = false;

  // Environment & Camera
  CameraView _cameraView = CameraView.thirdPerson;
  late TrackType _trackType;
  late WeatherType _weather;

  // Entities
  final List<TrafficCar> _traffic = [];
  final List<RoadProp> _props = [];
  final List<SkidMark> _skidMarks = [];
  final List<ParticleFX> _particles = [];

  // Feedback notifications
  String? _bannerNotification;
  Timer? _bannerTimer;
  bool _isGameOver = false;
  bool _isVictory = false;
  bool _isPaused = false;
  double _cameraShake = 0.0;

  @override
  void initState() {
    super.initState();

    // Determine track & weather from level
    _setupEnvironment();

    // Target distance: Level 1 = 1200m, Level 40 = 8000m
    _targetDistance = widget.gameMode == CarGameMode.career
        ? 1200.0 + ((widget.levelNumber - 1) * 175.0)
        : 999999.0;

    _gameLoop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onGameTick);

    _gameLoop.repeat();

    // Spawn initial traffic & props
    _spawnInitialTraffic();
  }

  void _setupEnvironment() {
    final lvl = widget.levelNumber;
    if (lvl <= 10) {
      _trackType = TrackType.cityHighway;
      _weather = WeatherType.sunny;
    } else if (lvl <= 20) {
      _trackType = TrackType.mountainRidge;
      _weather = WeatherType.rainy;
    } else if (lvl <= 30) {
      _trackType = TrackType.desertDunes;
      _weather = WeatherType.sunny;
    } else {
      _trackType = TrackType.cityHighway;
      _weather = WeatherType.night;
    }
  }

  @override
  void dispose() {
    _gameLoop.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _showNotification(String text, {Color color = AppTheme.neonGold}) {
    setState(() => _bannerNotification = text);
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _bannerNotification = null);
    });
  }

  void _spawnInitialTraffic() {
    _traffic.clear();
    final lanes = [-1.5, -0.5, 0.5, 1.5];
    for (int i = 0; i < 6; i++) {
      _traffic.add(
        TrafficCar(
          lane: lanes[i % lanes.length],
          distance: 0.2 + (i * 0.14),
          speed: 0.0035 + (_random.nextDouble() * 0.002),
          color: [
            const Color(0xFFE11D48),
            const Color(0xFFFBBF24),
            const Color(0xFF2563EB),
            const Color(0xFF475569),
            const Color(0xFF10B981)
          ][_random.nextInt(5)],
          type: ['sedan', 'taxi', 'truck', 'coupe'][_random.nextInt(4)],
        ),
      );
    }
  }

  void _onGameTick() {
    if (_isPaused || _isGameOver || _isVictory) return;

    final car = CarGarageService.instance.currentCar;
    const dt = 1.0 / 60.0;

    // 1. Acceleration & Speed Physics
    final topSpeed = _isNitroActive ? (car.currentTopSpeed + 60.0) : car.currentTopSpeed;
    final accelRate = car.currentAcceleration * (_isNitroActive ? 32.0 : 20.0);
    final brakeRate = car.currentBraking * 38.0;

    if (_isBraking) {
      _playerSpeed = math.max(0.0, _playerSpeed - (brakeRate * dt));
    } else if (_isAccelerating) {
      if (_playerSpeed < topSpeed) {
        _playerSpeed = math.min(topSpeed, _playerSpeed + (accelRate * dt));
      } else {
        _playerSpeed = math.max(topSpeed, _playerSpeed - 15.0 * dt);
      }
    } else {
      // Natural rolling drag
      _playerSpeed = math.max(0.0, _playerSpeed - (18.0 * dt));
    }

    // 2. Nitro consumption / refill
    if (_isNitroActive) {
      _nitroTank = math.max(0.0, _nitroTank - (30.0 * dt));
      if (_nitroTank <= 0.0) {
        _isNitroActive = false;
      }
      _spawnBoostParticles();
    } else {
      // Slow natural recharge
      _nitroTank = math.min(100.0, _nitroTank + (4.0 * dt));
    }

    // 3. Steering & Mass Inertia
    final steerSensitivity = (car.currentHandling * 0.35) * (_playerSpeed / 120.0).clamp(0.4, 1.2);
    _isDrifting = false;

    if (_isSteeringLeft) {
      _playerLane = (_playerLane - (steerSensitivity * dt * 2.8)).clamp(-1.75, 1.75);
      if (_isBraking && _playerSpeed > 100.0) {
        _isDrifting = true;
      }
    } else if (_isSteeringRight) {
      _playerLane = (_playerLane + (steerSensitivity * dt * 2.8)).clamp(-1.75, 1.75);
      if (_isBraking && _playerSpeed > 100.0) {
        _isDrifting = true;
      }
    }

    // Drift scoring & tire smoke
    if (_isDrifting) {
      _driftPoints += 5;
      _score += 8;
      AudioService.instance.playDrift();
      _spawnDriftSmoke();
      _skidMarks.add(SkidMark(lane: _playerLane, distance: 0.95));
      if (_skidMarks.length > 30) _skidMarks.removeAt(0);
    }

    // 4. Road Curvature dynamics
    if (_random.nextDouble() < 0.02) {
      _targetCurve = (_random.nextDouble() * 1.6) - 0.8;
    }
    _roadCurve += (_targetCurve - _roadCurve) * 0.02;

    // 5. Jump physics (when hitting ramp)
    if (_jumpHeight > 0 || _jumpVelocity > 0) {
      _jumpHeight += _jumpVelocity * dt;
      _jumpVelocity -= 9.8 * dt * 0.8;
      if (_jumpHeight <= 0) {
        _jumpHeight = 0;
        _jumpVelocity = 0;
        HapticFeedback.heavyImpact();
      }
    }

    // 6. Scroll road & distance
    final speedRatio = _playerSpeed / 100.0;
    _roadScroll += _playerSpeed * dt * 12.0;
    final metersAdvanced = (_playerSpeed * (1000.0 / 3600.0)) * dt;
    _distanceTraveled += metersAdvanced;
    _score += (speedRatio * 2).toInt();

    // Time attack countdown
    if (widget.gameMode == CarGameMode.timeAttack) {
      _timeRemaining -= dt;
      if (_timeRemaining <= 0) {
        _triggerGameOver('Time Expired!');
        return;
      }
    }

    // Check Victory (Career Mode)
    if (widget.gameMode == CarGameMode.career && _distanceTraveled >= _targetDistance) {
      _triggerVictory();
      return;
    }

    // 7. Update Traffic & Collision Detection
    _updateTraffic(speedRatio, dt);

    // 8. Update Props & Pickups
    _updateProps(speedRatio, dt);

    // 9. Camera Shake damping
    if (_cameraShake > 0) {
      _cameraShake = math.max(0.0, _cameraShake - 0.05);
    }

    // 10. Update Particles
    for (final p in _particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.life -= 0.03;
    }
    _particles.removeWhere((p) => p.life <= 0);

    setState(() {});
  }

  void _updateTraffic(double speedRatio, double dt) {
    // Spawn traffic ahead
    if (_traffic.length < 8 && _random.nextDouble() < 0.03) {
      final lanes = [-1.5, -0.5, 0.5, 1.5];
      final targetLane = lanes[_random.nextInt(lanes.length)];
      _traffic.add(
        TrafficCar(
          lane: targetLane,
          distance: 0.05,
          speed: 0.002 + (_random.nextDouble() * 0.002),
          color: [
            const Color(0xFFEF4444),
            const Color(0xFFFBBF24),
            const Color(0xFF3B82F6),
            const Color(0xFF10B981)
          ][_random.nextInt(4)],
          type: ['sedan', 'taxi', 'truck', 'coupe'][_random.nextInt(4)],
        ),
      );
    }

    // Move traffic relative to player speed
    for (int i = _traffic.length - 1; i >= 0; i--) {
      final car = _traffic[i];
      // Car approaches as player moves faster
      final delta = (speedRatio * 0.006) - car.speed;
      car.distance += delta;

      // Check Near-Miss Overtake (Longitudinal distance close to 0.88, lateral lane difference < 0.45)
      if (car.distance >= 0.80 && car.distance <= 0.92) {
        final laneDiff = (_playerLane - car.lane).abs();
        if (laneDiff > 0.45 && laneDiff < 0.95 && _playerSpeed > 90.0) {
          _nearMissCount++;
          _score += 150;
          _coinsEarned += 10;
          AudioService.instance.playNearMiss();
          _showNotification('🔥 CLOSE CALL! +10 Coins');
        }
      }

      // Check Collision with Player
      if (car.distance >= 0.85 && car.distance <= 0.96 && _jumpHeight < 0.25) {
        final laneDiff = (_playerLane - car.lane).abs();
        if (laneDiff < 0.42) {
          // BUMP / CRASH COLLISION
          _handleCollision(car);
        }
      }

      // Despawn passed cars
      if (car.distance > 1.2 || car.distance < -0.2) {
        _traffic.removeAt(i);
      }
    }
  }

  void _handleCollision(TrafficCar car) {
    _cameraShake = 1.0;
    AudioService.instance.playCrash();
    _spawnSparks();

    // Push cars apart
    if (_playerLane > car.lane) {
      _playerLane = math.min(1.75, _playerLane + 0.35);
      car.lane -= 0.3;
    } else {
      _playerLane = math.max(-1.75, _playerLane - 0.35);
      car.lane += 0.3;
    }

    // Reduce speed & damage health
    _playerSpeed = math.max(30.0, _playerSpeed * 0.45);
    final damage = (25.0 / CarGarageService.instance.currentCar.baseDurability * 6.5).clamp(10.0, 45.0);
    _playerHealth = math.max(0.0, _playerHealth - damage);

    if (_playerHealth <= 0) {
      _triggerGameOver('Vehicle Totaled! Crash destroyed car chassis.');
    } else {
      _showNotification('⚠️ Collision! -${damage.toInt()}% Armor', color: AppTheme.neonPink);
    }
  }

  void _updateProps(double speedRatio, double dt) {
    // Spawn Coins & Boosts
    if (_props.length < 5 && _random.nextDouble() < 0.04) {
      final lanes = [-1.5, -0.5, 0.5, 1.5];
      final pickLane = lanes[_random.nextInt(lanes.length)];
      final propTypes = ['coin', 'coin', 'coin', 'nitro', 'oil', 'ramp', 'cone'];
      _props.add(RoadProp(lane: pickLane, distance: 0.05, type: propTypes[_random.nextInt(propTypes.length)]));
    }

    for (int i = _props.length - 1; i >= 0; i--) {
      final p = _props[i];
      p.distance += speedRatio * 0.0075;

      // Pickup Collision
      if (!p.collected && p.distance >= 0.85 && p.distance <= 0.98) {
        final laneDiff = (_playerLane - p.lane).abs();
        if (laneDiff < 0.4) {
          p.collected = true;
          _handlePropPickup(p);
        }
      }

      if (p.distance > 1.1) {
        _props.removeAt(i);
      }
    }
  }

  void _handlePropPickup(RoadProp prop) {
    if (prop.type == 'coin') {
      _coinsEarned += 25;
      _score += 100;
      AudioService.instance.playCoinCollect();
      WalletService.instance.addGems(25, reason: 'Picked up Road Coin');
      _showNotification('+25 COINS! 🪙', color: AppTheme.neonGold);
    } else if (prop.type == 'nitro') {
      _nitroTank = math.min(100.0, _nitroTank + 50.0);
      AudioService.instance.playTurbo();
      _showNotification('⚡ NITRO REFILLED! ⚡', color: const Color(0xFF00E5FF));
    } else if (prop.type == 'oil') {
      // Slip & Drift spin
      AudioService.instance.playDrift();
      _playerLane = (_playerLane + (_random.nextBool() ? 0.6 : -0.6)).clamp(-1.75, 1.75);
      _showNotification('⚠️ OIL SLICK SLIP!', color: const Color(0xFF818CF8));
    } else if (prop.type == 'ramp') {
      // Air launch!
      _jumpVelocity = 4.2;
      _score += 250;
      AudioService.instance.playTurbo();
      _showNotification('🚀 AIRBORNE RAMP JUMP! +250', color: Colors.orange);
    } else if (prop.type == 'cone') {
      _playerHealth = math.max(0.0, _playerHealth - 5.0);
      HapticFeedback.mediumImpact();
    }
  }

  void _spawnBoostParticles() {
    final size = MediaQuery.of(context).size;
    final carY = size.height * 0.82;
    final carX = size.width * 0.5 + (_playerLane * (size.width * 0.92 / 4.0));

    for (int i = 0; i < 3; i++) {
      _particles.add(
        ParticleFX(
          x: carX + (_random.nextDouble() * 20 - 10),
          y: carY + 30,
          vx: (_random.nextDouble() * 4 - 2),
          vy: 8 + _random.nextDouble() * 6,
          size: 6 + _random.nextDouble() * 6,
          life: 1.0,
          color: const Color(0xFF00E5FF),
        ),
      );
    }
  }

  void _spawnDriftSmoke() {
    final size = MediaQuery.of(context).size;
    final carY = size.height * 0.82;
    final carX = size.width * 0.5 + (_playerLane * (size.width * 0.92 / 4.0));

    for (int i = 0; i < 2; i++) {
      _particles.add(
        ParticleFX(
          x: carX + (_playerLane > 0 ? -25 : 25),
          y: carY + 20,
          vx: (_random.nextDouble() * 3 - 1.5),
          vy: 4 + _random.nextDouble() * 3,
          size: 8 + _random.nextDouble() * 8,
          life: 0.8,
          color: Colors.white70,
        ),
      );
    }
  }

  void _spawnSparks() {
    final size = MediaQuery.of(context).size;
    final carY = size.height * 0.82;
    final carX = size.width * 0.5 + (_playerLane * (size.width * 0.92 / 4.0));

    for (int i = 0; i < 12; i++) {
      _particles.add(
        ParticleFX(
          x: carX + (_random.nextDouble() * 40 - 20),
          y: carY - 10 + (_random.nextDouble() * 30),
          vx: (_random.nextDouble() * 12 - 6),
          vy: (_random.nextDouble() * 12 - 6),
          size: 4 + _random.nextDouble() * 4,
          life: 1.0,
          color: const Color(0xFFFBBF24),
        ),
      );
    }
  }

  void _triggerVictory() {
    _isVictory = true;
    AudioService.instance.playVictory();

    // Calculate stars: 3 stars = health > 70%, 2 stars = health > 30%, 1 star = completed
    int stars = 1;
    if (_playerHealth >= 70.0) {
      stars = 3;
    } else if (_playerHealth >= 30.0) {
      stars = 2;
    }

    // Award bonus coins for level clear
    final levelCoinsBonus = 100 + (stars * 50);
    WalletService.instance.addGems(levelCoinsBonus, reason: 'Cleared Highway Level ${widget.levelNumber}');

    // Record progression
    ArcadeHubService.instance.recordLevelComplete(
      gameId: 'car_racing',
      levelNumber: widget.levelNumber,
      score: _score,
      stars: stars,
    );

    // Show Interstitial ad with frequency protection
    AdManager.instance.showInterstitialAd();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildVictoryDialog(stars, levelCoinsBonus),
    );
  }

  void _triggerGameOver(String reason) {
    _isGameOver = true;
    AudioService.instance.playGameOver();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildGameOverDialog(reason),
    );
  }

  void _revivePlayer() {
    setState(() {
      _playerHealth = 100.0;
      _playerSpeed = 60.0;
      _isGameOver = false;
      _traffic.removeWhere((c) => c.distance > 0.7); // clear immediate traffic
    });
    Navigator.of(context).pop();
    _showNotification('🛡️ REVIVED! Full Armor Restored');
  }

  @override
  Widget build(BuildContext context) {
    final car = CarGarageService.instance.currentCar;
    final shakeOffset = _cameraShake > 0
        ? Offset((_random.nextDouble() - 0.5) * 12 * _cameraShake, (_random.nextDouble() - 0.5) * 12 * _cameraShake)
        : Offset.zero;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Road Viewport & Canvas
            Transform.translate(
              offset: shakeOffset,
              child: CustomPaint(
                size: Size.infinite,
                painter: RoadPainter(
                  playerLane: _playerLane,
                  playerSpeed: _playerSpeed,
                  roadScrollOffset: _roadScroll,
                  roadCurve: _roadCurve,
                  playerCar: car,
                  trackType: _trackType,
                  weather: _weather,
                  cameraView: _cameraView,
                  isBraking: _isBraking,
                  isDrifting: _isDrifting,
                  isNitroActive: _isNitroActive,
                  playerHealth: _playerHealth,
                  jumpHeight: _jumpHeight,
                  traffic: _traffic,
                  props: _props,
                  skidMarks: _skidMarks,
                  particles: _particles,
                  animationTick: _gameLoop.value,
                ),
              ),
            ),

            // 2. In-Game Banner Notification (Popups like Near Miss, Ramp Jump)
            if (_bannerNotification != null)
              Positioned(
                top: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.neonGold, width: 1.5),
                      boxShadow: [
                        BoxShadow(color: AppTheme.neonGold.withValues(alpha: 0.5), blurRadius: 16),
                      ],
                    ),
                    child: Text(
                      _bannerNotification!,
                      style: const TextStyle(
                        color: AppTheme.neonGold,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),

            // 3. Top HUD (Speedometer, Distance progress, Health, Coins, Camera)
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: _buildTopHudBar(car),
            ),

            // 4. On-Screen Racing Controls (Steering, Gas, Brake, NOS)
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: _buildControlsBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHudBar(CarModel car) {
    final progressFraction = widget.gameMode == CarGameMode.career
        ? (_distanceTraveled / _targetDistance).clamp(0.0, 1.0)
        : 1.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Pause & Garage Button
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () {
                    setState(() => _isPaused = !_isPaused);
                    if (_isPaused) _showPauseDialog();
                  },
                  icon: const Icon(Icons.pause_rounded, color: Colors.white, size: 20),
                  style: IconButton.styleFrom(backgroundColor: AppTheme.cardDark),
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CarGarageScreen()),
                    );
                  },
                  tooltip: 'Tuning Garage',
                  icon: const Icon(Icons.garage_rounded, color: AppTheme.neonGold, size: 20),
                  style: IconButton.styleFrom(backgroundColor: AppTheme.cardDark),
                ),
              ],
            ),

            // Digital Speedometer (Center)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _playerSpeed > 180 ? const Color(0xFFFF2A6D) : AppTheme.neonCyan,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_playerSpeed > 180 ? const Color(0xFFFF2A6D) : AppTheme.neonCyan).withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${_playerSpeed.round()}',
                    style: TextStyle(
                      color: _playerSpeed > 180 ? const Color(0xFFFF2A6D) : Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('KM/H', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            // Camera View Switcher
            IconButton.filledTonal(
              onPressed: () {
                setState(() {
                  if (_cameraView == CameraView.thirdPerson) {
                    _cameraView = CameraView.hood;
                  } else if (_cameraView == CameraView.hood) {
                    _cameraView = CameraView.cockpit;
                  } else {
                    _cameraView = CameraView.thirdPerson;
                  }
                });
                HapticFeedback.selectionClick();
              },
              icon: const Icon(Icons.videocam_rounded, color: AppTheme.neonCyan, size: 20),
              style: IconButton.styleFrom(backgroundColor: AppTheme.cardDark),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Progress & Health Indicator Bar
        Row(
          children: [
            // Vehicle Health / Armor Bar
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: AppTheme.neonGreen, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_playerHealth / 100.0).clamp(0.0, 1.0),
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _playerHealth > 40 ? AppTheme.neonGreen : const Color(0xFFEF4444),
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Distance Progress (Career Mode)
            if (widget.gameMode == CarGameMode.career)
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.flag_rounded, color: AppTheme.neonGold, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressFraction,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.neonGold),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${((_targetDistance - _distanceTraveled).clamp(0, _targetDistance) / 1000).toStringAsFixed(1)}km',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

            // Coins & Score Badge
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Text('🪙 ', style: TextStyle(fontSize: 11)),
                  Text('$_coinsEarned', style: const TextStyle(color: AppTheme.neonGold, fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlsBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Steering Controls (Left & Right Buttons)
        Row(
          children: [
            // Left Turn Button
            GestureDetector(
              onTapDown: (_) {
                setState(() => _isSteeringLeft = true);
                HapticFeedback.lightImpact();
              },
              onTapUp: (_) => setState(() => _isSteeringLeft = false),
              onTapCancel: () => setState(() => _isSteeringLeft = false),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _isSteeringLeft ? AppTheme.neonCyan.withValues(alpha: 0.4) : AppTheme.cardDark.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.neonCyan, width: 2),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(width: 14),

            // Right Turn Button
            GestureDetector(
              onTapDown: (_) {
                setState(() => _isSteeringRight = true);
                HapticFeedback.lightImpact();
              },
              onTapUp: (_) => setState(() => _isSteeringRight = false),
              onTapCancel: () => setState(() => _isSteeringRight = false),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _isSteeringRight ? AppTheme.neonCyan.withValues(alpha: 0.4) : AppTheme.cardDark.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.neonCyan, width: 2),
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),

        // NOS Nitro Button (Center / Right)
        GestureDetector(
          onTapDown: (_) {
            if (_nitroTank > 15.0) {
              setState(() => _isNitroActive = true);
              AudioService.instance.playTurbo();
            }
          },
          onTapUp: (_) => setState(() => _isNitroActive = false),
          onTapCancel: () => setState(() => _isNitroActive = false),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: _isNitroActive ? 0.8 : 0.3),
                  blurRadius: _isNitroActive ? 22 : 10,
                  spreadRadius: _isNitroActive ? 4 : 1,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 28),
                Text(
                  '${_nitroTank.toInt()}%',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),

        // Pedals: Brake & Accelerator
        Row(
          children: [
            // Brake Pedal
            GestureDetector(
              onTapDown: (_) {
                setState(() => _isBraking = true);
                HapticFeedback.mediumImpact();
              },
              onTapUp: (_) => setState(() => _isBraking = false),
              onTapCancel: () => setState(() => _isBraking = false),
              child: Container(
                width: 58,
                height: 72,
                decoration: BoxDecoration(
                  color: _isBraking ? const Color(0xFFEF4444) : AppTheme.cardDark.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEF4444), width: 2),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.horizontal_rule_rounded, color: Colors.white, size: 24),
                    Text('BRAKE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Gas / Accelerator Pedal
            GestureDetector(
              onTapDown: (_) {
                setState(() => _isAccelerating = true);
                HapticFeedback.lightImpact();
              },
              onTapUp: (_) => setState(() => _isAccelerating = false),
              onTapCancel: () => setState(() => _isAccelerating = false),
              child: Container(
                width: 62,
                height: 84,
                decoration: BoxDecoration(
                  color: _isAccelerating ? AppTheme.neonGreen : AppTheme.cardDark.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.neonGreen, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.speed_rounded, color: _isAccelerating ? Colors.black : Colors.white, size: 26),
                    Text(
                      'GAS',
                      style: TextStyle(
                        color: _isAccelerating ? Colors.black : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showPauseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('RACE PAUSED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Score: $_score', style: const TextStyle(color: AppTheme.neonCyan, fontSize: 16)),
            Text('Coins Earned: $_coinsEarned 🪙', style: const TextStyle(color: AppTheme.neonGold, fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // exit race
            },
            child: const Text('Exit to Hub', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _isPaused = false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen),
            child: const Text('RESUME', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildVictoryDialog(int stars, int bonusCoins) {
    return AlertDialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppTheme.neonGold, width: 1.5),
      ),
      title: const Center(
        child: Text(
          '🏁 VICTORY! LEVEL COMPLETE 🏁',
          style: TextStyle(color: AppTheme.neonGold, fontWeight: FontWeight.w900, fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3 Stars Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (idx) {
              final active = idx < stars;
              return Icon(
                active ? Icons.star_rounded : Icons.star_border_rounded,
                color: active ? AppTheme.neonGold : Colors.white24,
                size: 40,
              );
            }),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Race Score:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('$_score', style: const TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Near Misses:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('$_nearMissCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Drift Points:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('$_driftPoints', style: const TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Coins Earned:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('+${_coinsEarned + bonusCoins} 🪙', style: const TextStyle(color: AppTheme.neonGold, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop(); // exit to menu
          },
          child: const Text('Garage / Menu', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => CarRacingScreen(levelNumber: widget.levelNumber + 1),
              ),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen),
          child: const Text('NEXT LEVEL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildGameOverDialog(String reason) {
    return AlertDialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppTheme.neonPink, width: 1.5),
      ),
      title: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.neonPink, size: 26),
          SizedBox(width: 8),
          Text('CRASHED / GAME OVER', style: TextStyle(color: AppTheme.neonPink, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(reason, style: const TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('Distance: ${(_distanceTraveled / 1000).toStringAsFixed(2)} km', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text('Score: $_score  •  Drift: $_driftPoints pts', style: const TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Revive with Rewarded Ad Option
          ElevatedButton.icon(
            onPressed: () {
              AdManager.instance.showRewardedAd(
                context: context,
                onUserEarnedReward: (_) {
                  _revivePlayer();
                },
              );
            },
            icon: const Icon(Icons.video_library_rounded, color: Colors.black, size: 20),
            label: const Text('REVIVE FREE (WATCH VIDEO)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonCyan,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
          child: const Text('Exit', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => CarRacingScreen(levelNumber: widget.levelNumber)),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cardDark),
          child: const Text('RETRY', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
