import 'package:flutter/material.dart';
import '../game/models/game_progress.dart';
import '../game/models/level_data.dart';
import 'game_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _worlds = const [
    ('Emerald Garden 🌿', 1, 10, Color(0xFF1DD1A1)),
    ('Sapphire Lagoon 🌊', 11, 20, Color(0xFF2E86DE)),
    ('Amethyst Canyon 🔮', 21, 30, Color(0xFF9B59B6)),
    ('Cosmic Galaxy 🌌', 31, 40, Color(0xFFE056FD)),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _worlds.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GameProgress(),
      builder: (context, _) {
        final progress = GameProgress();
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C3E50), Color(0xFF1E272E)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // App Bar Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white12,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Select Level',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        // Total Stars Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFECA57).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFECA57)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFFECA57), size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${progress.totalStars} / 120',
                                style: const TextStyle(
                                  color: Color(0xFFFECA57),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // World Tabs
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: const Color(0xFF1DD1A1),
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    tabAlignment: TabAlignment.start,
                    tabs: _worlds.map((w) => Tab(text: w.$1)).toList(),
                  ),

                  // Level Grid View for each world
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: _worlds.map((world) {
                        final startLevel = world.$2;
                        final endLevel = world.$3;
                        final worldColor = world.$4;

                        return _buildLevelGrid(startLevel, endLevel, worldColor, progress);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelGrid(int start, int end, Color accentColor, GameProgress progress) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.88,
      ),
      itemCount: end - start + 1,
      itemBuilder: (context, i) {
        final levelNum = start + i;
        final isUnlocked = levelNum <= progress.unlockedLevel;
        final stars = progress.getStarsForLevel(levelNum);
        final levelInfo = LevelData.getLevel(levelNum);

        return GestureDetector(
          onTap: isUnlocked
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GameScreen(levelNumber: levelNum),
                    ),
                  );
                }
              : null,
          child: Container(
            decoration: BoxDecoration(
              gradient: isUnlocked
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withValues(alpha: 0.25),
                        accentColor.withValues(alpha: 0.1),
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isUnlocked ? accentColor : Colors.white12,
                width: isUnlocked ? 2.0 : 1.0,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isUnlocked) ...[
                  const Icon(Icons.lock_rounded, color: Colors.white24, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    'Level $levelNum',
                    style: const TextStyle(color: Colors.white24, fontSize: 13),
                  ),
                ] else ...[
                  Text(
                    '$levelNum',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    levelInfo.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  // Stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (starIdx) {
                      final isEarned = starIdx < stars;
                      return Icon(
                        isEarned ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 16,
                        color: isEarned ? const Color(0xFFFECA57) : Colors.white24,
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
