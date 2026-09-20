import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/arcade_hub_service.dart';
import '../../core/services/audio_service.dart';
import '../../core/theme/app_theme.dart';

class KnifeHitScreen extends StatefulWidget {
  final int levelNumber;
  const KnifeHitScreen({super.key, this.levelNumber = 1});

  @override
  State<KnifeHitScreen> createState() => _KnifeHitScreenState();
}

class _KnifeHitScreenState extends State<KnifeHitScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  late int totalKnives;
  late int remainingKnives;
  List<double> embeddedKnivesAngles = []; // Angles in radians
  List<double> obstacleAngles = []; // For boss stages

  double currentTargetAngle = 0.0;
  bool isKnifeInFlight = false;
  double knifeFlyY = 0.0; // 0 to 1 progress
  bool isGameOver = false;
  bool hasWon = false;
  int score = 0;

  bool get isBossLevel => widget.levelNumber % 5 == 0;

  @override
  void initState() {
    super.initState();
    _initLevel();

    _rotationController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (3000 - (widget.levelNumber * 40)).clamp(1200, 3500),
      ),
    )..addListener(() {
        if (!mounted) return;
        setState(() {
          // Dynamic angle rotation with occasional direction shifts
          final t = _rotationController.value;
          final speedFactor = 1.0 + (math.sin(t * math.pi * 4) * 0.3);
          currentTargetAngle = (t * math.pi * 2 * speedFactor) % (math.pi * 2);
        });
      });

    _rotationController.repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _initLevel() {
    totalKnives = 6 + (widget.levelNumber ~/ 5).clamp(0, 6);
    remainingKnives = totalKnives;
    embeddedKnivesAngles = [];
    obstacleAngles = [];
    isKnifeInFlight = false;
    knifeFlyY = 0.0;
    isGameOver = false;
    hasWon = false;
    score = 0;

    // Initial pre-embedded obstacles/knives
    final initialObstaclesCount = (widget.levelNumber ~/ 8).clamp(0, 3);
    for (int i = 0; i < initialObstaclesCount; i++) {
      embeddedKnivesAngles.add((i * (math.pi * 2 / 3)));
    }

    if (isBossLevel) {
      obstacleAngles.add(math.pi / 2);
      obstacleAngles.add(-math.pi / 2);
    }
  }

  void _throwKnife() {
    if (isKnifeInFlight || isGameOver || hasWon || remainingKnives <= 0) return;

    HapticFeedback.lightImpact();
    AudioService.instance.playShoot();

    setState(() {
      isKnifeInFlight = true;
      knifeFlyY = 0.0;
    });

    // Animate knife flying upwards
    const steps = 10;
    int currentStep = 0;

    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 16));
      if (!mounted) return false;
      currentStep++;
      setState(() {
        knifeFlyY = currentStep / steps;
      });

      if (currentStep >= steps) {
        _checkHitCollision();
        return false;
      }
      return true;
    });
  }

  void _checkHitCollision() {
    // Check if the knife at bottom (pointing at angle: -currentTargetAngle + pi/2) collides with existing knives
    // Normalized angle relative to target
    final hitAngle = (math.pi / 2 - currentTargetAngle) % (math.pi * 2);

    // Collision threshold in radians (~15 degrees)
    const collisionThreshold = 0.26;

    bool collided = false;

    for (final angle in embeddedKnivesAngles) {
      final diff = ((angle - hitAngle + math.pi * 3) % (math.pi * 2)) - math.pi;
      if (diff.abs() < collisionThreshold) {
        collided = true;
        break;
      }
    }

    for (final angle in obstacleAngles) {
      final diff = ((angle - hitAngle + math.pi * 3) % (math.pi * 2)) - math.pi;
      if (diff.abs() < collisionThreshold) {
        collided = true;
        break;
      }
    }

    if (collided) {
      // Clang! Defeat!
      HapticFeedback.heavyImpact();
      setState(() {
        isKnifeInFlight = false;
        isGameOver = true;
      });
      _handleGameOver();
    } else {
      // Thud! Success hit!
      HapticFeedback.mediumImpact();
      AudioService.instance.playPop();
      setState(() {
        embeddedKnivesAngles.add(hitAngle);
        isKnifeInFlight = false;
        remainingKnives--;
        score += 100 + (widget.levelNumber * 10);

        if (remainingKnives <= 0) {
          hasWon = true;
          _handleWin();
        }
      });
    }
  }

  void _handleWin() {
    int stars = 1;
    if (totalKnives - embeddedKnivesAngles.length <= 1) {
      stars = 3;
    } else {
      stars = 2;
    }

    ArcadeHubService.instance.recordLevelComplete(
      gameId: 'knife_hit',
      levelNumber: widget.levelNumber,
      score: score,
      stars: stars,
    );
    AudioService.instance.playVictory();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.neonCyan, width: 1.5),
        ),
        title: Column(
          children: [
            Text(
              isBossLevel ? '👑 BOSS DEFEATED!' : '🎯 TARGET SHATTERED!',
              style: const TextStyle(color: AppTheme.neonGold, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Icon(
                  i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppTheme.neonGold,
                  size: 36,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Score: $score', style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: AppTheme.neonBoxDecoration(borderColor: AppTheme.neonGreen),
              child: Text(
                '💎 +${25 + (stars * 10)} Ikram Gems Earned!',
                style: const TextStyle(color: AppTheme.neonGreen, fontWeight: FontWeight.bold),
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
            child: const Text('Menu', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (widget.levelNumber < AppConstants.levelsPerGame) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => KnifeHitScreen(levelNumber: widget.levelNumber + 1),
                  ),
                );
              } else {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan),
            child: Text(widget.levelNumber < 40 ? 'Next Level' : 'Done'),
          ),
        ],
      ),
    );
  }

  void _handleGameOver() {
    AudioService.instance.playGameOver();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.neonPink, width: 1.5),
        ),
        title: const Text('KNIFE CLASH!', style: TextStyle(color: AppTheme.neonPink, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You hit another knife!', style: TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Quit', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _initLevel());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonPink),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isBossLevel ? 'BOSS STAGE • Level ${widget.levelNumber}' : 'Knife Hit • Level ${widget.levelNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() => _initLevel()),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _throwKnife,
        child: SafeArea(
          child: Column(
            children: [
              // Top Stats Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: AppTheme.neonBoxDecoration(borderColor: isBossLevel ? AppTheme.neonPink : AppTheme.neonCyan),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('SCORE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('$score', style: const TextStyle(color: AppTheme.neonCyan, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('KNIVES LEFT', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('$remainingKnives / $totalKnives', style: const TextStyle(color: AppTheme.neonGold, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Game Arena
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating Target Log
                      Positioned(
                        top: 60,
                        child: Transform.rotate(
                          angle: currentTargetAngle,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: isBossLevel
                                    ? [const Color(0xFFFF2A85), const Color(0xFF8A2387)]
                                    : [const Color(0xFFDAA520), const Color(0xFF8B4513)],
                              ),
                              border: Border.all(
                                color: isBossLevel ? AppTheme.neonPink : AppTheme.neonGold,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isBossLevel ? AppTheme.neonPink : AppTheme.neonGold).withValues(alpha: 0.5),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  isBossLevel ? Icons.shield_rounded : Icons.radar_rounded,
                                  size: 48,
                                  color: Colors.white24,
                                ),
                                // Embedded Knives
                                ...embeddedKnivesAngles.map((angle) {
                                  return Transform.rotate(
                                    angle: angle,
                                    child: Transform.translate(
                                      offset: const Offset(0, 75),
                                      child: const _KnifeWidget(),
                                    ),
                                  );
                                }),
                                // Boss Obstacles
                                ...obstacleAngles.map((angle) {
                                  return Transform.rotate(
                                    angle: angle,
                                    child: Transform.translate(
                                      offset: const Offset(0, 75),
                                      child: const Icon(Icons.block_rounded, color: AppTheme.neonPink, size: 28),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Flying Knife
                      if (isKnifeInFlight)
                        Positioned(
                          bottom: 120 + (knifeFlyY * 260),
                          child: const _KnifeWidget(),
                        ),

                      // Ready Knife at Shooter Station
                      if (!isKnifeInFlight && remainingKnives > 0)
                        const Positioned(
                          bottom: 120,
                          child: _KnifeWidget(),
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom Knives Gauge
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalKnives, (i) {
                    final isUsed = i >= remainingKnives;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        Icons.navigation_rounded,
                        size: 22,
                        color: isUsed ? Colors.white24 : AppTheme.neonCyan,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KnifeWidget extends StatelessWidget {
  const _KnifeWidget();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFF00F2FE)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F2FE).withValues(alpha: 0.6),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }
}
