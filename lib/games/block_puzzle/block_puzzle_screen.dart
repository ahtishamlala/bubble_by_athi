import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/arcade_hub_service.dart';
import '../../core/theme/app_theme.dart';
import 'block_shapes.dart';

class BlockPuzzleScreen extends StatefulWidget {
  final int levelNumber;
  const BlockPuzzleScreen({super.key, this.levelNumber = 1});

  @override
  State<BlockPuzzleScreen> createState() => _BlockPuzzleScreenState();
}

class _BlockPuzzleScreenState extends State<BlockPuzzleScreen> {
  static const int gridSize = 8;
  late List<List<Color?>> grid;
  late List<BlockShape?> currentChoices;
  int? selectedChoiceIndex;

  int score = 0;
  late int targetScore;
  late int remainingMoves;
  int streakCombo = 0;
  bool isGameOver = false;
  bool hasWon = false;

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  void _initLevel() {
    grid = List.generate(gridSize, (_) => List.filled(gridSize, null));
    targetScore = 400 + (widget.levelNumber * 180);
    remainingMoves = 25 - (widget.levelNumber ~/ 5).clamp(0, 10);
    score = 0;
    streakCombo = 0;
    isGameOver = false;
    hasWon = false;
    selectedChoiceIndex = null;
    _generateChoices();
  }

  void _generateChoices() {
    currentChoices = List.generate(3, (_) => BlockShape.randomShape());
  }

  bool _canPlace(BlockShape shape, int startR, int startC) {
    for (int r = 0; r < shape.rows; r++) {
      for (int c = 0; c < shape.cols; c++) {
        if (shape.matrix[r][c] == 1) {
          final targetR = startR + r;
          final targetC = startC + c;
          if (targetR < 0 || targetR >= gridSize || targetC < 0 || targetC >= gridSize) {
            return false;
          }
          if (grid[targetR][targetC] != null) {
            return false;
          }
        }
      }
    }
    return true;
  }

  void _placeBlock(int choiceIndex, int startR, int startC) {
    final shape = currentChoices[choiceIndex];
    if (shape == null) return;

    if (!_canPlace(shape, startR, startC)) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot place block there!'),
          duration: Duration(milliseconds: 600),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();

    setState(() {
      int placedCells = 0;
      for (int r = 0; r < shape.rows; r++) {
        for (int c = 0; c < shape.cols; c++) {
          if (shape.matrix[r][c] == 1) {
            grid[startR + r][startC + c] = shape.color;
            placedCells++;
          }
        }
      }

      score += placedCells * 10;
      remainingMoves--;
      currentChoices[choiceIndex] = null;
      selectedChoiceIndex = null;

      _checkLineClears();

      // Check if all 3 shapes used -> refill
      if (currentChoices.every((s) => s == null)) {
        _generateChoices();
      }

      // Check win/loss
      if (score >= targetScore) {
        hasWon = true;
        _handleGameWin();
      } else if (remainingMoves <= 0) {
        isGameOver = true;
        _showGameOverDialog();
      }
    });
  }

  void _checkLineClears() {
    final fullRows = <int>[];
    final fullCols = <int>[];

    // Check rows
    for (int r = 0; r < gridSize; r++) {
      if (grid[r].every((cell) => cell != null)) {
        fullRows.add(r);
      }
    }

    // Check columns
    for (int c = 0; c < gridSize; c++) {
      bool colFull = true;
      for (int r = 0; r < gridSize; r++) {
        if (grid[r][c] == null) {
          colFull = false;
          break;
        }
      }
      if (colFull) {
        fullCols.add(c);
      }
    }

    final totalLines = fullRows.length + fullCols.length;
    if (totalLines > 0) {
      streakCombo++;
      final bonus = totalLines * 100 * streakCombo;
      score += bonus;
      HapticFeedback.mediumImpact();

      // Clear rows
      for (final r in fullRows) {
        for (int c = 0; c < gridSize; c++) {
          grid[r][c] = null;
        }
      }

      // Clear cols
      for (final c in fullCols) {
        for (int r = 0; r < gridSize; r++) {
          grid[r][c] = null;
        }
      }
    } else {
      streakCombo = 0;
    }
  }

  void _handleGameWin() {
    int stars = 1;
    if (score >= targetScore * 1.5) {
      stars = 3;
    } else if (score >= targetScore * 1.2) {
      stars = 2;
    }

    ArcadeHubService.instance.recordLevelComplete(
      gameId: 'block_puzzle',
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
            const Text('🎉 LEVEL CLEARED!', style: TextStyle(color: AppTheme.neonGold, fontWeight: FontWeight.bold)),
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
                    builder: (_) => BlockPuzzleScreen(levelNumber: widget.levelNumber + 1),
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

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.neonPink, width: 1.5),
        ),
        title: const Text('GAME OVER', style: TextStyle(color: AppTheme.neonPink, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Out of moves!', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('Score: $score / $targetScore', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        title: Text('Block Puzzle • Level ${widget.levelNumber}'),
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
                decoration: AppTheme.neonBoxDecoration(borderColor: AppTheme.neonCyan),
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
                    if (streakCombo > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.neonPink, borderRadius: BorderRadius.circular(10)),
                        child: Text('${streakCombo}x COMBO!', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 8x8 Grid
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
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
                          final cellColor = grid[r][c];

                          return DragTarget<int>(
                            onWillAcceptWithDetails: (details) {
                              final shape = currentChoices[details.data];
                              return shape != null && _canPlace(shape, r, c);
                            },
                            onAcceptWithDetails: (details) {
                              _placeBlock(details.data, r, c);
                            },
                            builder: (context, candidateData, rejectedData) {
                              final isCandidate = candidateData.isNotEmpty;
                              return GestureDetector(
                                onTap: () {
                                  if (selectedChoiceIndex != null) {
                                    _placeBlock(selectedChoiceIndex!, r, c);
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  decoration: BoxDecoration(
                                    color: cellColor ?? (isCandidate ? AppTheme.neonCyan.withValues(alpha: 0.3) : const Color(0xFF1E293B)),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: cellColor != null ? cellColor.withValues(alpha: 0.8) : Colors.white10,
                                      width: cellColor != null ? 1.5 : 1,
                                    ),
                                    boxShadow: cellColor != null
                                        ? [
                                            BoxShadow(
                                              color: cellColor.withValues(alpha: 0.4),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Choice Tray
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (i) {
                  final shape = currentChoices[i];
                  if (shape == null) {
                    return const SizedBox(width: 80, height: 80);
                  }

                  final isSelected = selectedChoiceIndex == i;

                  return Draggable<int>(
                    data: i,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Opacity(
                        opacity: 0.85,
                        child: _buildShapePreview(shape, cellSize: 24),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: _buildShapePreview(shape, cellSize: 18),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedChoiceIndex = isSelected ? null : i;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.neonCyan.withValues(alpha: 0.2) : AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppTheme.neonCyan : AppTheme.borderGlow,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: _buildShapePreview(shape, cellSize: 18),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShapePreview(BlockShape shape, {double cellSize = 18}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(shape.rows, (r) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(shape.cols, (c) {
            final filled = shape.matrix[r][c] == 1;
            return Container(
              width: cellSize,
              height: cellSize,
              margin: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                color: filled ? shape.color : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      }),
    );
  }
}
