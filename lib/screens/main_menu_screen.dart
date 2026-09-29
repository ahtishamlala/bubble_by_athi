import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../ad_manager.dart';
import '../banner_ad_widget.dart';
import '../game/models/bubble_color.dart';
import '../game/models/game_progress.dart';
import '../game/painter/bubble_painter.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Animations initialized smoothly
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GameProgress(),
      builder: (context, _) {
        final progress = GameProgress();
        final currentLevel = progress.unlockedLevel;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C3E50), Color(0xFF341F97), Color(0xFF1E272E)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top Stats Bar (Coins & Stars)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        // Stars
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFECA57)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFFECA57), size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${progress.totalStars} Stars',
                                style: const TextStyle(
                                  color: Color(0xFFFECA57),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Coins
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFECA57)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.monetization_on_rounded, color: Color(0xFFFECA57), size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${progress.coins}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Settings Button
                        IconButton.filledTonal(
                          onPressed: _showSettingsDialog,
                          icon: const Icon(Icons.settings_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white12,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hero Title & Animated Glossy Bubbles
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Floating animated bubbles showcase
                          AnimatedBuilder(
                            animation: _animController,
                            builder: (context, _) {
                              return SizedBox(
                                height: 130,
                                width: 280,
                                child: CustomPaint(
                                  painter: _MenuBubblesPainter(animationValue: _animController.value),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 10),
                          const Text(
                            'BUBBLE by ATHI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              shadows: [
                                Shadow(
                                  color: Color(0xFF5F27CD),
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            '40 Exciting Levels • Smooth Physics',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 36),

                          // Play Button
                          SizedBox(
                            width: 220,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => GameScreen(levelNumber: currentLevel),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.play_arrow_rounded, size: 32),
                              label: Text(
                                'PLAY LEVEL $currentLevel',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1DD1A1),
                                foregroundColor: Colors.white,
                                elevation: 8,
                                shadowColor: const Color(0xFF1DD1A1).withValues(alpha: 0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Select Level Button
                          SizedBox(
                            width: 220,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const LevelSelectScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.grid_view_rounded, size: 22),
                              label: const Text(
                                'ALL LEVELS (40)',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Rewarded Video Ad Button (Free Coins)
                          SizedBox(
                            width: 220,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                AdManager.instance.showRewardedAd(
                                  context: context,
                                  onUserEarnedReward: (reward) {
                                    GameProgress().addCoins(50);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('🎉 +50 Coins Added! Thanks for watching!'),
                                          backgroundColor: Color(0xFF1DD1A1),
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                              icon: const Icon(Icons.video_library_rounded, color: Color(0xFFFECA57), size: 20),
                              label: const Text(
                                'FREE 50 COINS 🎬',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5F27CD),
                                foregroundColor: Colors.white,
                                elevation: 6,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: const BorderSide(color: Color(0xFFFECA57), width: 1.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom AdMob Banner
                  const SafeArea(top: false, child: BannerAdWidget()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        content: ListenableBuilder(
          listenable: GameProgress(),
          builder: (context, _) {
            final p = GameProgress();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.volume_up_rounded, color: Colors.white),
                  title: const Text('Sound Effects', style: TextStyle(color: Colors.white)),
                  trailing: Switch(
                    value: p.soundEnabled,
                    onChanged: (_) => p.toggleSound(),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.vibration_rounded, color: Colors.white),
                  title: const Text('Haptics', style: TextStyle(color: Colors.white)),
                  trailing: Switch(
                    value: p.hapticsEnabled,
                    onChanged: (_) => p.toggleHaptics(),
                  ),
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.analytics_outlined, color: Color(0xFF1DD1A1)),
                  title: const Text('AdMob Live Inspector', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Check live ad status & Google fill', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                  onTap: () {
                    AdManager.instance.openAdInspector(context);
                  },
                ),
                const Divider(color: Colors.white24),
                TextButton.icon(
                  onPressed: () async {
                    await p.resetProgress();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF6B6B)),
                  label: const Text('Reset All Progress', style: TextStyle(color: Color(0xFFFF6B6B))),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Color(0xFF1DD1A1))),
          ),
        ],
      ),
    );
  }
}

class _MenuBubblesPainter extends CustomPainter {
  final double animationValue;

  _MenuBubblesPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      BubbleType.pink,
      BubbleType.blue,
      BubbleType.green,
      BubbleType.red,
      BubbleType.purple,
      BubbleType.orange,
      BubbleType.yellow,
    ];

    const radius = 22.0;
    for (int i = 0; i < colors.length; i++) {
      final t = (animationValue + (i / colors.length)) % 1.0;
      final x = 20.0 + (i * 38.0);
      final y = (size.height / 2) + (math.sin(t * math.pi * 2) * 14.0);

      BubblePainter.paintBubble(
        canvas,
        Offset(x, y),
        radius,
        colors[i],
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MenuBubblesPainter oldDelegate) => true;
}
