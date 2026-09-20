import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/arcade_hub_service.dart';
import '../../core/services/audio_service.dart';
import '../../core/theme/app_theme.dart';

class MemoryCard {
  final int id;
  final String symbol;
  bool isFlipped;
  bool isMatched;

  MemoryCard({
    required this.id,
    required this.symbol,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

class MemoryMatrixScreen extends StatefulWidget {
  final int levelNumber;
  const MemoryMatrixScreen({super.key, this.levelNumber = 1});

  @override
  State<MemoryMatrixScreen> createState() => _MemoryMatrixScreenState();
}

class _MemoryMatrixScreenState extends State<MemoryMatrixScreen> {
  late List<MemoryCard> cards;
  late int rows;
  late int cols;
  late int totalPairs;

  int? firstFlippedIndex;
  int? secondFlippedIndex;
  bool isProcessing = false;

  int score = 0;
  int moves = 0;
  late int timeRemainingSeconds;
  Timer? _timer;

  static const List<String> allSymbols = [
    '⚡', '💎', '🚀', '🔥', '👑', '👾', '🎯', '🪐',
    '🛡️', '⚔️', '🔮', '🌟', '🛸', '🤖', '🕹️', '🏆',
  ];

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initLevel() {
    _timer?.cancel();
    score = 0;
    moves = 0;
    firstFlippedIndex = null;
    secondFlippedIndex = null;
    isProcessing = false;

    // Grid sizing based on level tier
    if (widget.levelNumber <= 10) {
      rows = 3;
      cols = 2; // 6 cards = 3 pairs
      timeRemainingSeconds = 40;
    } else if (widget.levelNumber <= 20) {
      rows = 4;
      cols = 3; // 12 cards = 6 pairs
      timeRemainingSeconds = 45;
    } else if (widget.levelNumber <= 30) {
      rows = 4;
      cols = 4; // 16 cards = 8 pairs
      timeRemainingSeconds = 50;
    } else {
      rows = 5;
      cols = 4; // 20 cards = 10 pairs
      timeRemainingSeconds = 55;
    }

    totalPairs = (rows * cols) ~/ 2;

    // Pick random symbols
    final symbolsShuffled = List<String>.from(allSymbols)..shuffle(Random());
    final levelSymbols = symbolsShuffled.take(totalPairs).toList();

    cards = [];
    int idCounter = 0;
    for (final sym in levelSymbols) {
      cards.add(MemoryCard(id: idCounter++, symbol: sym));
      cards.add(MemoryCard(id: idCounter++, symbol: sym));
    }
    cards.shuffle(Random());

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (timeRemainingSeconds > 0) {
          timeRemainingSeconds--;
        } else {
          timer.cancel();
          _handleGameOver();
        }
      });
    });
  }

  void _onCardTapped(int index) {
    if (isProcessing) return;
    if (cards[index].isFlipped || cards[index].isMatched) return;

    HapticFeedback.selectionClick();
    AudioService.instance.playClick();

    setState(() {
      cards[index].isFlipped = true;
    });

    if (firstFlippedIndex == null) {
      firstFlippedIndex = index;
    } else {
      secondFlippedIndex = index;
      moves++;
      isProcessing = true;

      final card1 = cards[firstFlippedIndex!];
      final card2 = cards[secondFlippedIndex!];

      if (card1.symbol == card2.symbol) {
        // Matched!
        HapticFeedback.mediumImpact();
        AudioService.instance.playMatch();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          setState(() {
            card1.isMatched = true;
            card2.isMatched = true;
            score += 150 + (timeRemainingSeconds * 5);
            firstFlippedIndex = null;
            secondFlippedIndex = null;
            isProcessing = false;

            if (cards.every((c) => c.isMatched)) {
              _timer?.cancel();
              _handleWin();
            }
          });
        });
      } else {
        // No match -> flip back
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          setState(() {
            card1.isFlipped = false;
            card2.isFlipped = false;
            firstFlippedIndex = null;
            secondFlippedIndex = null;
            isProcessing = false;
          });
        });
      }
    }
  }

  void _handleWin() {
    int stars = 1;
    if (timeRemainingSeconds >= 20) {
      stars = 3;
    } else if (timeRemainingSeconds >= 10) {
      stars = 2;
    }

    ArcadeHubService.instance.recordLevelComplete(
      gameId: 'memory_matrix',
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
            const Text('🧠 MATRIX SOLVED!', style: TextStyle(color: AppTheme.neonGold, fontWeight: FontWeight.bold)),
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
            Text('Score: $score (Moves: $moves)', style: const TextStyle(color: Colors.white70, fontSize: 16)),
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
                    builder: (_) => MemoryMatrixScreen(levelNumber: widget.levelNumber + 1),
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
        title: const Text('TIME OUT', style: TextStyle(color: AppTheme.neonPink, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You ran out of time!', style: TextStyle(color: Colors.white70)),
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
        title: Text('Memory Matrix • Level ${widget.levelNumber}'),
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
            // Top Stats Bar
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
                        const Text('TIME LEFT', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('${timeRemainingSeconds}s', style: TextStyle(color: timeRemainingSeconds <= 10 ? AppTheme.neonPink : AppTheme.neonGreen, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('MOVES', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('$moves', style: const TextStyle(color: AppTheme.neonGold, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('PAIRS', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('${cards.where((c) => c.isMatched).length ~/ 2} / $totalPairs', style: const TextStyle(color: AppTheme.neonCyan, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Card Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];

                    return GestureDetector(
                      onTap: () => _onCardTapped(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          color: card.isMatched
                              ? AppTheme.neonGreen.withValues(alpha: 0.2)
                              : (card.isFlipped ? AppTheme.cardDark : const Color(0xFF1E293B)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: card.isMatched
                                ? AppTheme.neonGreen
                                : (card.isFlipped ? AppTheme.neonCyan : AppTheme.borderGlow),
                            width: card.isFlipped || card.isMatched ? 2 : 1,
                          ),
                          boxShadow: card.isFlipped || card.isMatched
                              ? [
                                  BoxShadow(
                                    color: (card.isMatched ? AppTheme.neonGreen : AppTheme.neonCyan).withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            card.isFlipped || card.isMatched ? card.symbol : '❓',
                            style: TextStyle(
                              fontSize: card.isFlipped || card.isMatched ? 28 : 20,
                              color: card.isFlipped ? Colors.white : Colors.white38,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
