import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/arcade_hub_service.dart';
import '../../core/theme/app_theme.dart';

class Merge2048Screen extends StatefulWidget {
  final int levelNumber;
  const Merge2048Screen({super.key, this.levelNumber = 1});

  @override
  State<Merge2048Screen> createState() => _Merge2048ScreenState();
}

class _Merge2048ScreenState extends State<Merge2048Screen> {
  static const int size = 4;
  late List<List<int>> board;
  final Random _rand = Random();

  int score = 0;
  late int targetScore;
  late int remainingSteps;
  bool isGameOver = false;
  bool hasWon = false;

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    board = List.generate(size, (_) => List.filled(size, 0));
    targetScore = 500 + (widget.levelNumber * 250);
    remainingSteps = 30 + (widget.levelNumber * 2).clamp(0, 30);
    score = 0;
    isGameOver = false;
    hasWon = false;

    _spawnRandomTile();
    _spawnRandomTile();
  }

  void _spawnRandomTile() {
    final emptyCells = <Point<int>>[];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (board[r][c] == 0) {
          emptyCells.add(Point(r, c));
        }
      }
    }
    if (emptyCells.isNotEmpty) {
      final p = emptyCells[_rand.nextInt(emptyCells.length)];
      board[p.x][p.y] = _rand.nextDouble() < 0.9 ? 2 : 4;
    }
  }

  void _move(int dx, int dy) {
    if (isGameOver || hasWon) return;

    bool moved = false;
    int pointsEarned = 0;

    List<int> slide(List<int> row) {
      final nonZero = row.where((v) => v != 0).toList();
      final result = <int>[];
      int i = 0;
      while (i < nonZero.length) {
        if (i + 1 < nonZero.length && nonZero[i] == nonZero[i + 1]) {
          final mergedVal = nonZero[i] * 2;
          result.add(mergedVal);
          pointsEarned += mergedVal;
          i += 2;
        } else {
          result.add(nonZero[i]);
          i++;
        }
      }
      while (result.length < size) {
        result.add(0);
      }
      return result;
    }

    if (dx != 0) {
      // Horizontal
      for (int r = 0; r < size; r++) {
        List<int> row = List<int>.from(board[r]);
        if (dx > 0) row = row.reversed.toList();
        final newRow = slide(row);
        final finalRow = dx > 0 ? newRow.reversed.toList() : newRow;

        for (int c = 0; c < size; c++) {
          if (board[r][c] != finalRow[c]) moved = true;
          board[r][c] = finalRow[c];
        }
      }
    } else if (dy != 0) {
      // Vertical
      for (int c = 0; c < size; c++) {
        List<int> col = [board[0][c], board[1][c], board[2][c], board[3][c]];
        if (dy > 0) col = col.reversed.toList();
        final newCol = slide(col);
        final finalCol = dy > 0 ? newCol.reversed.toList() : newCol;

        for (int r = 0; r < size; r++) {
          if (board[r][c] != finalCol[r]) moved = true;
          board[r][c] = finalCol[r];
        }
      }
    }

    if (moved) {
      HapticFeedback.lightImpact();
      setState(() {
        score += pointsEarned;
        remainingSteps--;
        _spawnRandomTile();

        if (score >= targetScore) {
          hasWon = true;
          _handleWin();
        } else if (remainingSteps <= 0 || _isBoardFullAndStuck()) {
          isGameOver = true;
          _handleGameOver();
        }
      });
    }
  }

  bool _isBoardFullAndStuck() {
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        if (board[r][c] == 0) return false;
        if (c + 1 < size && board[r][c] == board[r][c + 1]) return false;
        if (r + 1 < size && board[r][c] == board[r + 1][c]) return false;
      }
    }
    return true;
  }

  void _handleWin() {
    int stars = 1;
    if (score >= targetScore * 1.5) {
      stars = 3;
    } else if (score >= targetScore * 1.2) {
      stars = 2;
    }

    ArcadeHubService.instance.recordLevelComplete(
      gameId: 'merge_2048',
      levelNumber: widget.levelNumber,
      score: score,
      stars: stars,
    );

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
            const Text('🔥 2048 TARGET MET!', style: TextStyle(color: AppTheme.neonGold, fontWeight: FontWeight.bold)),
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
            Text('Score: $score / $targetScore', style: const TextStyle(color: Colors.white70, fontSize: 16)),
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
                    builder: (_) => Merge2048Screen(levelNumber: widget.levelNumber + 1),
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.neonPink, width: 1.5),
        ),
        title: const Text('NO MORE MOVES', style: TextStyle(color: AppTheme.neonPink, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Final Score: $score / $targetScore', style: const TextStyle(color: Colors.white70)),
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

  Color _getTileColor(int val) {
    switch (val) {
      case 2:
        return const Color(0xFF1E293B);
      case 4:
        return const Color(0xFF334155);
      case 8:
        return const Color(0xFF00F2FE);
      case 16:
        return const Color(0xFF4FACFE);
      case 32:
        return const Color(0xFF00E676);
      case 64:
        return const Color(0xFFFFD700);
      case 128:
        return const Color(0xFFFF9F43);
      case 256:
        return const Color(0xFFFF7A00);
      case 512:
        return const Color(0xFFFF3366);
      case 1024:
        return const Color(0xFFFF2A85);
      case 2048:
        return const Color(0xFF9B51E0);
      default:
        return const Color(0xFF1E272E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('2048 Merge • Level ${widget.levelNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() => _initLevel()),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Stats Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: AppTheme.neonBoxDecoration(borderColor: AppTheme.neonGold),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('SCORE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('$score / $targetScore', style: const TextStyle(color: AppTheme.neonCyan, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('STEPS LEFT', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('$remainingSteps', style: const TextStyle(color: AppTheme.neonGold, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 4x4 Swipeable Grid
            Expanded(
              child: Center(
                child: GestureDetector(
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity! < -200) _move(0, -1); // Up
                    if (details.primaryVelocity! > 200) _move(0, 1); // Down
                  },
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! < -200) _move(-1, 0); // Left
                    if (details.primaryVelocity! > 200) _move(1, 0); // Right
                  },
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1322),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderGlow, width: 2),
                        ),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: size,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: size * size,
                          itemBuilder: (context, index) {
                            final r = index ~/ size;
                            final c = index % size;
                            final val = board[r][c];

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: _getTileColor(val),
                                borderRadius: BorderRadius.circular(10),
                                border: val > 0
                                    ? Border.all(color: Colors.white24, width: 1.5)
                                    : null,
                                boxShadow: val >= 8
                                    ? [
                                        BoxShadow(
                                          color: _getTileColor(val).withValues(alpha: 0.5),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  val > 0 ? '$val' : '',
                                  style: TextStyle(
                                    color: val >= 8 ? Colors.white : Colors.white70,
                                    fontSize: val >= 1024 ? 18 : 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // On-Screen D-Pad for accessibility and extra precision
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    onPressed: () => _move(-1, 0),
                    icon: const Icon(Icons.arrow_back_rounded),
                    style: IconButton.styleFrom(backgroundColor: AppTheme.cardDark),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      IconButton.filled(
                        onPressed: () => _move(0, -1),
                        icon: const Icon(Icons.arrow_upward_rounded),
                        style: IconButton.styleFrom(backgroundColor: AppTheme.cardDark),
                      ),
                      const SizedBox(height: 8),
                      IconButton.filled(
                        onPressed: () => _move(0, 1),
                        icon: const Icon(Icons.arrow_downward_rounded),
                        style: IconButton.styleFrom(backgroundColor: AppTheme.cardDark),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _move(1, 0),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    style: IconButton.styleFrom(backgroundColor: AppTheme.cardDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
