import 'package:flutter/material.dart';
import '../game/models/game_progress.dart';

class VictoryDialog extends StatelessWidget {
  final int levelNumber;
  final int score;
  final int stars;
  final VoidCallback onNextLevel;
  final VoidCallback onRetry;
  final VoidCallback onExitToMenu;

  const VictoryDialog({
    super.key,
    required this.levelNumber,
    required this.score,
    required this.stars,
    required this.onNextLevel,
    required this.onRetry,
    required this.onExitToMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF341F97), Color(0xFF5F27CD)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎉 LEVEL COMPLETE! 🎉',
              style: TextStyle(
                color: Color(0xFFFECA57),
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 16),
            // Star rating row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final isEarned = i < stars;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    isEarned ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 48,
                    color: isEarned ? const Color(0xFFFECA57) : Colors.white24,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Score: $score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.monetization_on_rounded, color: Color(0xFFFECA57), size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '+${stars * 15} Coins',
                        style: const TextStyle(color: Color(0xFFFECA57), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.filledTonal(
                  onPressed: onExitToMenu,
                  icon: const Icon(Icons.grid_view_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(14),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: onRetry,
                  icon: const Icon(Icons.replay_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(14),
                  ),
                ),
                if (levelNumber < 40)
                  ElevatedButton.icon(
                    onPressed: onNextLevel,
                    icon: const Icon(Icons.play_arrow_rounded, size: 28),
                    label: const Text('Next Level', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1DD1A1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GameOverDialog extends StatelessWidget {
  final int score;
  final VoidCallback onRetry;
  final VoidCallback onExitToMenu;

  const GameOverDialog({
    super.key,
    required this.score,
    required this.onRetry,
    required this.onExitToMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C3E50), Color(0xFF1A252F)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sentiment_dissatisfied_rounded, size: 56, color: Color(0xFFFF6B6B)),
            const SizedBox(height: 12),
            const Text(
              'OUT OF SHOTS!',
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Score: $score',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: onExitToMenu,
                  icon: const Icon(Icons.grid_view_rounded),
                  label: const Text('Levels'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEE5253),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PauseDialog extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExitToMenu;

  const PauseDialog({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onExitToMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF2C3E50),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'GAME PAUSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.volume_up_rounded, color: Colors.white),
              title: const Text('Sound Effects', style: TextStyle(color: Colors.white)),
              trailing: Switch(
                value: GameProgress().soundEnabled,
                onChanged: (_) => GameProgress().toggleSound(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.vibration_rounded, color: Colors.white),
              title: const Text('Haptics', style: TextStyle(color: Colors.white)),
              trailing: Switch(
                value: GameProgress().hapticsEnabled,
                onChanged: (_) => GameProgress().toggleHaptics(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: onExitToMenu,
                  icon: const Icon(Icons.home_rounded, color: Colors.white, size: 28),
                ),
                IconButton(
                  onPressed: onRestart,
                  icon: const Icon(Icons.replay_rounded, color: Colors.white, size: 28),
                ),
                ElevatedButton.icon(
                  onPressed: onResume,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Resume'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DD1A1),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
