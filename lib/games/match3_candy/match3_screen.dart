import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/arcade_hub_service.dart';
import '../../core/services/audio_service.dart';
import '../../core/theme/app_theme.dart';

class Match3Screen extends StatefulWidget {
  final int levelNumber;
  const Match3Screen({super.key, this.levelNumber = 1});

  @override
  State<Match3Screen> createState() => _Match3ScreenState();
}

class _Match3ScreenState extends State<Match3Screen> {
  static const int gridSize = 8;
  late List<List<int>> board;
  final Random _rand = Random();

  static const List<String> candyIcons = ['🍓', '🍋', '🍇', '🍊', '🫐'];
  static const List<Color> candyColors = [
    Color(0xFFFF3366),
    Color(0xFFFFD700),
    Color(0xFF9B51E0),
    Color(0xFFFF7A00),
    Color(0xFF00F2FE),
  ];

  int? selectedR;
  int? selectedC;

  int score = 0;
  late int targetScore;
  late int remainingMoves;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    targetScore = 600 + (widget.levelNumber * 200);
    remainingMoves = 24 - (widget.levelNumber ~/ 6).clamp(0, 8);
    score = 0;
    selectedR = null;
    selectedC = null;
    isProcessing = false;

    // Pre-allocate empty board first to avoid LateInitializationError
    board = List.generate(gridSize, (_) => List.filled(gridSize, -1));

    // Populate safely with no initial matches
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        board[r][c] = _getRandomSafeCandy(r, c);
      }
    }
  }

  int _getRandomSafeCandy(int r, int c) {
    int val;
    int attempts = 0;
    do {
      val = _rand.nextInt(candyIcons.length);
      attempts++;
    } while (attempts < 20 &&
        ((c >= 2 && board[r][c - 1] == val && board[r][c - 2] == val) ||
            (r >= 2 && board[r - 1][c] == val && board[r - 2][c] == val)));
    return val;
  }

  void _onCellTapped(int r, int c) {
    if (isProcessing) return;

    if (selectedR == null || selectedC == null) {
      setState(() {
        selectedR = r;
        selectedC = c;
      });
      HapticFeedback.selectionClick();
    } else {
      final prevR = selectedR!;
      final prevC = selectedC!;

      // Check if adjacent
      final isAdjacent = (r == prevR && (c - prevC).abs() == 1) ||
          (c == prevC && (r - prevR).abs() == 1);

      if (isAdjacent) {
        _swapAndCheck(prevR, prevC, r, c);
      } else {
        setState(() {
          selectedR = r;
          selectedC = c;
        });
        HapticFeedback.selectionClick();
      }
    }
  }

  Future<void> _swapAndCheck(int r1, int c1, int r2, int c2) async {
    setState(() {
      isProcessing = true;
      selectedR = null;
      selectedC = null;
      // Swap
      final temp = board[r1][c1];
      board[r1][c1] = board[r2][c2];
      board[r2][c2] = temp;
    });

    final matches = _findMatches();
    if (matches.isEmpty) {
      // Invalid swap -> swap back
      await Future.delayed(const Duration(milliseconds: 250));
      setState(() {
        final temp = board[r1][c1];
        board[r1][c1] = board[r2][c2];
        board[r2][c2] = temp;
        isProcessing = false;
      });
      HapticFeedback.heavyImpact();
    } else {
      // Valid move!
      HapticFeedback.mediumImpact();
      remainingMoves--;
      await _processMatches(matches);
    }
  }

  Set<Point<int>> _findMatches() {
    final matched = <Point<int>>{};

    // Horizontal check
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize - 2; c++) {
        final val = board[r][c];
        if (val != -1 && val == board[r][c + 1] && val == board[r][c + 2]) {
          matched.add(Point(r, c));
          matched.add(Point(r, c + 1));
          matched.add(Point(r, c + 2));
        }
      }
    }

    // Vertical check
    for (int c = 0; c < gridSize; c++) {
      for (int r = 0; r < gridSize - 2; r++) {
        final val = board[r][c];
        if (val != -1 && val == board[r + 1][c] && val == board[r + 2][c]) {
          matched.add(Point(r, c));
          matched.add(Point(r + 1, c));
          matched.add(Point(r + 2, c));
        }
      }
    }

    return matched;
  }

  Future<void> _processMatches(Set<Point<int>> matches) async {
    score += matches.length * 30;
    AudioService.instance.playMatch();

    // Clear matched
    for (final p in matches) {
      board[p.x][p.y] = -1;
    }
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 200));

    // Gravity drop
    for (int c = 0; c < gridSize; c++) {
      int emptyRow = gridSize - 1;
      for (int r = gridSize - 1; r >= 0; r--) {
        if (board[r][c] != -1) {
          if (r != emptyRow) {
            board[emptyRow][c] = board[r][c];
            board[r][c] = -1;
          }
          emptyRow--;
        }
      }
      // Fill remaining empty top cells with new candies
      for (int r = emptyRow; r >= 0; r--) {
        board[r][c] = _rand.nextInt(candyIcons.length);
      }
    }

    setState(() {});
    await Future.delayed(const Duration(milliseconds: 200));

    // Cascade check
    final newMatches = _findMatches();
    if (newMatches.isNotEmpty) {
      await _processMatches(newMatches);
    } else {
      isProcessing = false;
      _checkGameStatus();
    }
  }

  void _checkGameStatus() {
    if (score >= targetScore) {
      _handleWin();
    } else if (remainingMoves <= 0) {
      _handleGameOver();
    }
  }

  void _handleWin() {
    int stars = 1;
    if (score >= targetScore * 1.5) {
      stars = 3;
    } else if (score >= targetScore * 1.2) {
      stars = 2;
    }

    ArcadeHubService.instance.recordLevelComplete(
      gameId: 'match3_candy',
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
            const Text('🍬 SWEET VICTORY!', style: TextStyle(color: AppTheme.neonGold, fontWeight: FontWeight.bold)),
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
                    builder: (_) => Match3Screen(levelNumber: widget.levelNumber + 1),
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
        title: const Text('OUT OF MOVES', style: TextStyle(color: AppTheme.neonPink, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Score: $score / $targetScore', style: const TextStyle(color: Colors.white70)),
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
        title: Text('Candy Match-3 • Level ${widget.levelNumber}'),
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
                decoration: AppTheme.neonBoxDecoration(borderColor: AppTheme.neonPink),
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
                        const Text('MOVES', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('$remainingMoves', style: const TextStyle(color: AppTheme.neonGold, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 8x8 Grid
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131B2A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderGlow, width: 2),
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridSize,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                        itemCount: gridSize * gridSize,
                        itemBuilder: (context, index) {
                          final r = index ~/ gridSize;
                          final c = index % gridSize;
                          final candyVal = board[r][c];
                          final isSelected = selectedR == r && selectedC == c;

                          if (candyVal == -1) {
                            return const SizedBox.shrink();
                          }

                          return GestureDetector(
                            onTap: () => _onCellTapped(r, c),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.neonCyan.withValues(alpha: 0.3)
                                    : candyColors[candyVal].withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? AppTheme.neonCyan : candyColors[candyVal].withValues(alpha: 0.5),
                                  width: isSelected ? 2.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.neonCyan.withValues(alpha: 0.6),
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  candyIcons[candyVal],
                                  style: TextStyle(
                                    fontSize: isSelected ? 26 : 22,
                                  ),
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
