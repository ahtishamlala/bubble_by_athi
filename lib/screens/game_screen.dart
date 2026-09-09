import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../banner_ad_widget.dart';
import '../game/game_controller.dart';
import '../game/models/bubble_color.dart';
import '../game/models/level_data.dart';
import '../game/painter/game_board_painter.dart';
import '../widgets/game_dialogs.dart';

class GameScreen extends StatefulWidget {
  final int levelNumber;

  const GameScreen({
    super.key,
    required this.levelNumber,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late GameController _controller;
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  double _animTick = 0.0;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _startLevel(widget.levelNumber);

    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
      _lastElapsed = elapsed;

      _animTick += dt;
      if (_animTick > 1000) _animTick = 0;

      _controller.update(dt.clamp(0.001, 0.05));
      _checkGameState();
    });

    _ticker.start();
  }

  void _startLevel(int levelNum) {
    _dialogShown = false;
    final levelData = LevelData.getLevel(levelNum);
    _controller = GameController(levelData: levelData);
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _checkGameState() {
    if (_dialogShown) return;

    if (_controller.state == GameState.won) {
      _dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => VictoryDialog(
          levelNumber: _controller.levelData.levelNumber,
          score: _controller.score,
          stars: _controller.calculateStars(),
          onNextLevel: () {
            Navigator.of(context).pop();
            setState(() {
              _startLevel(_controller.levelData.levelNumber + 1);
            });
          },
          onRetry: () {
            Navigator.of(context).pop();
            setState(() {
              _startLevel(_controller.levelData.levelNumber);
            });
          },
          onExitToMenu: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        ),
      );
    } else if (_controller.state == GameState.lost) {
      _dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => GameOverDialog(
          score: _controller.score,
          onRetry: () {
            Navigator.of(context).pop();
            setState(() {
              _startLevel(_controller.levelData.levelNumber);
            });
          },
          onExitToMenu: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: SafeArea(
        child: Column(
          children: [
            // Top HUD Bar
            _buildTopHUD(),

            // Interactive Game Board Canvas
            Expanded(
              child: ClipRect(
                child: Listener(
                  onPointerDown: (e) => _controller.onTouchStart(e.localPosition),
                  onPointerMove: (e) => _controller.onTouchMove(e.localPosition),
                  onPointerUp: (_) => _controller.onTouchEnd(),
                  child: CustomPaint(
                    painter: GameBoardPainter(
                      controller: _controller,
                      animationValue: _animTick,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),

            // Shooter Controls & Booster Bar
            _buildControlDock(),

            // Bottom AdMob Banner
            const SafeArea(top: false, child: BannerAdWidget()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHUD() {
    final level = _controller.levelData;
    final starProgress = (_controller.score / level.targetScore3Star).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E272E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Pause Button
              IconButton.filledTonal(
                onPressed: _showPauseMenu,
                icon: const Icon(Icons.pause_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white12,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 10),
              // Level Title & World
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level ${level.levelNumber}: ${level.title}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    level.worldName,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
              const Spacer(),
              // Shots Left Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bubble_chart_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${_controller.remainingShots}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Score and Star bar
          Row(
            children: [
              Text(
                'Score: ${_controller.score}',
                style: const TextStyle(
                  color: Color(0xFFFECA57),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: starProgress,
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFECA57)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: List.generate(3, (i) {
                  final target = i == 0
                      ? level.targetScore1Star
                      : (i == 1 ? level.targetScore2Star : level.targetScore3Star);
                  final isReached = _controller.score >= target;
                  return Icon(
                    isReached ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 16,
                    color: isReached ? const Color(0xFFFECA57) : Colors.white24,
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlDock() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF1E272E),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Swap Button
          ElevatedButton.icon(
            onPressed: _controller.swapBubbles,
            icon: const Icon(Icons.swap_horiz_rounded, size: 20),
            label: const Text('Swap'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF341F97),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),

          // Boosters Tray
          _buildBoosterItem(
            BubbleType.bomb,
            'Bomb',
            Icons.local_fire_department_rounded,
            const Color(0xFF2C3E50),
          ),
          _buildBoosterItem(
            BubbleType.rainbow,
            'Rainbow',
            Icons.star_rounded,
            const Color(0xFF6C5CE7),
          ),
          _buildBoosterItem(
            BubbleType.fireball,
            'Fireball',
            Icons.whatshot_rounded,
            const Color(0xFFEE5253),
          ),
        ],
      ),
    );
  }

  Widget _buildBoosterItem(BubbleType type, String label, IconData icon, Color color) {
    final isSelected = _controller.activeBooster == type;

    return GestureDetector(
      onTap: () => _controller.activateBooster(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _showPauseMenu() {
    showDialog(
      context: context,
      builder: (_) => PauseDialog(
        onResume: () => Navigator.of(context).pop(),
        onRestart: () {
          Navigator.of(context).pop();
          setState(() {
            _startLevel(_controller.levelData.levelNumber);
          });
        },
        onExitToMenu: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
