import 'bubble_color.dart';

/// Representation of a single level configuration
class LevelData {
  final int levelNumber;
  final String title;
  final String worldName;
  final int totalShots;
  final int targetScore3Star;
  final int targetScore2Star;
  final int targetScore1Star;
  final List<List<BubbleType?>> initialGrid;
  final List<BubbleType> availableColors;

  const LevelData({
    required this.levelNumber,
    required this.title,
    required this.worldName,
    required this.totalShots,
    required this.targetScore3Star,
    required this.targetScore2Star,
    required this.targetScore1Star,
    required this.initialGrid,
    required this.availableColors,
  });

  /// Factory generator for all 40 levels
  static LevelData getLevel(int levelIndex) {
    final idx = levelIndex.clamp(1, 40);
    return _allLevels[idx - 1];
  }

  static int get totalLevels => 40;

  static final List<LevelData> _allLevels = List.generate(40, (index) {
    final levelNum = index + 1;
    return _generateLevel(levelNum);
  });

  static LevelData _generateLevel(int levelNum) {
    String worldName;
    String title;
    int shots;
    List<BubbleType> colors;

    if (levelNum <= 10) {
      worldName = 'Emerald Garden 🌿';
      title = _levelTitles[levelNum - 1];
      shots = 32 - ((levelNum - 1) ~/ 2);
      if (levelNum <= 4) {
        colors = [BubbleType.pink, BubbleType.blue, BubbleType.green];
      } else if (levelNum <= 7) {
        colors = [BubbleType.pink, BubbleType.blue, BubbleType.green, BubbleType.red];
      } else {
        colors = [BubbleType.pink, BubbleType.blue, BubbleType.green, BubbleType.red, BubbleType.purple];
      }
    } else if (levelNum <= 20) {
      worldName = 'Sapphire Lagoon 🌊';
      title = _levelTitles[levelNum - 1];
      shots = 26 - ((levelNum - 11) ~/ 3);
      colors = [
        BubbleType.pink,
        BubbleType.blue,
        BubbleType.green,
        BubbleType.red,
        BubbleType.purple,
        if (levelNum > 15) BubbleType.orange,
      ];
    } else if (levelNum <= 30) {
      worldName = 'Amethyst Canyon 🔮';
      title = _levelTitles[levelNum - 1];
      shots = 22 - ((levelNum - 21) ~/ 4);
      colors = [
        BubbleType.pink,
        BubbleType.blue,
        BubbleType.green,
        BubbleType.red,
        BubbleType.purple,
        BubbleType.orange,
        if (levelNum > 26) BubbleType.yellow,
      ];
    } else {
      worldName = 'Cosmic Galaxy 🌌';
      title = _levelTitles[levelNum - 1];
      shots = 19 - ((levelNum - 31) ~/ 5);
      colors = [
        BubbleType.pink,
        BubbleType.blue,
        BubbleType.green,
        BubbleType.red,
        BubbleType.purple,
        BubbleType.orange,
        BubbleType.yellow,
      ];
    }

    final grid = _buildGridPattern(levelNum, colors);
    final bubbleCount = grid.fold<int>(
      0,
      (sum, row) => sum + row.where((b) => b != null).length,
    );

    final baseScore = bubbleCount * 150;
    final star3 = (baseScore * 1.8).round();
    final star2 = (baseScore * 1.3).round();
    final star1 = baseScore;

    return LevelData(
      levelNumber: levelNum,
      title: title,
      worldName: worldName,
      totalShots: shots.clamp(14, 38),
      targetScore3Star: star3,
      targetScore2Star: star2,
      targetScore1Star: star1,
      initialGrid: grid,
      availableColors: colors,
    );
  }

  static List<List<BubbleType?>> _buildGridPattern(int levelNum, List<BubbleType> colors) {
    const maxRows = 12;
    final grid = <List<BubbleType?>>[];
    final activeRows = 5 + (levelNum ~/ 5).clamp(0, 4);

    for (int r = 0; r < maxRows; r++) {
      final colsCount = r.isEven ? 8 : 7;
      if (r >= activeRows) {
        grid.add(List.filled(colsCount, null));
        continue;
      }

      final row = List<BubbleType?>.filled(colsCount, null);

      for (int c = 0; c < colsCount; c++) {
        // Create distinct aesthetic patterns per level
        bool shouldPlace = true;

        if (levelNum % 5 == 2) {
          // Diamond / Pyramid gaps
          if (r % 2 == 1 && (c == 0 || c == colsCount - 1)) {
            shouldPlace = false;
          }
        } else if (levelNum % 5 == 3) {
          // Tunnel in center
          if (r >= 2 && (c == 3 || c == 4)) {
            shouldPlace = false;
          }
        } else if (levelNum % 5 == 4) {
          // Floating pillars
          if (c % 2 == 1 && r >= 3) {
            shouldPlace = false;
          }
        } else if (levelNum % 5 == 0) {
          // Checkered honeycomb
          if ((r + c) % 3 == 0 && r > 2) {
            shouldPlace = false;
          }
        }

        if (shouldPlace) {
          // Deterministic cluster generation so levels are strategic and solveable
          final colorIndex = ((r * 2) + (c ~/ 2) + (levelNum * 3)) % colors.length;
          row[c] = colors[colorIndex];
        }
      }

      grid.add(row);
    }

    return grid;
  }

  static const List<String> _levelTitles = [
    // World 1
    'First Pops',
    'Green Meadow',
    'Twin Arches',
    'Rainbow Wave',
    'Diamond Peak',
    'Hidden Gems',
    'Cherry Blossom',
    'Triple Threat',
    'Forest Spiral',
    'Garden Maze',
    // World 2
    'Ocean Breeze',
    'Coral Reef',
    'Deep Dive',
    'Sunken Ship',
    'Pearl Lagoon',
    'Tidal Wave',
    'Sea Shells',
    'Anchor Drop',
    'Water Tunnel',
    'Whirlpool',
    // World 3
    'Crystal Cavern',
    'Purple Haze',
    'Gilded Mine',
    'Rocky Ridge',
    'Sunset Glow',
    'Lava Stream',
    'Canyon Gates',
    'Stone Pillars',
    'Fire Bridge',
    'Magma Core',
    // World 4
    'Starlight Path',
    'Supernova',
    'Eclipse',
    'Meteor Shower',
    'Orbit Rings',
    'Neon Nebula',
    'Cosmic Gate',
    'Black Hole',
    'Galactic Core',
    'Bubble Master 👑',
  ];
}
