import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/game_stat.dart';
import 'auth_service.dart';
import 'wallet_service.dart';

class ArcadeHubService extends ChangeNotifier {
  static final ArcadeHubService instance = ArcadeHubService._internal();
  ArcadeHubService._internal();

  final Map<String, GameStat> _games = {};

  List<GameStat> get allGames => _games.values.toList();
  GameStat? getGame(String id) => _games[id];

  int get totalStarsEarned =>
      _games.values.fold(0, (sum, g) => sum + g.totalStars);

  int get totalLevelsUnlocked =>
      _games.values.fold(0, (sum, g) => sum + g.unlockedLevel);

  Future<void> init() async {
    // 1. Setup default 6 games
    _initDefaultGames();

    // 2. Load saved progression from storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString('arcade_hub_stats');
      if (statsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(statsJson);
        for (final entry in decoded.entries) {
          if (_games.containsKey(entry.key)) {
            _games[entry.key] =
                GameStat.fromJson(entry.value as Map<String, dynamic>);
          }
        }
      }
    } catch (e) {
      debugPrint('ArcadeHubService init error: $e');
    }
    notifyListeners();
  }

  void _initDefaultGames() {
    _games['bubble_shooter'] = const GameStat(
      id: 'bubble_shooter',
      title: 'Bubble Shooter Arcade',
      description: 'Hexagonal physics, wall bounce & special orbs',
      icon: '🎯',
      unlockedLevel: 1,
    );

    _games['car_racing'] = const GameStat(
      id: 'car_racing',
      title: 'Highway Speed Racer 3D',
      description: 'Multi-lane traffic, drift, nitro, obstacles & garage tuning',
      icon: '🏎️',
      unlockedLevel: 1,
    );
  }

  Future<void> recordLevelComplete({
    required String gameId,
    required int levelNumber,
    required int score,
    required int stars,
  }) async {
    final game = _games[gameId];
    if (game == null) return;

    final updatedStars = Map<int, int>.from(game.starsPerLevel);
    final previousStars = updatedStars[levelNumber] ?? 0;
    if (stars > previousStars) {
      updatedStars[levelNumber] = stars;
    }

    final nextLevel = levelNumber >= 40
        ? 40
        : (levelNumber >= game.unlockedLevel ? levelNumber + 1 : game.unlockedLevel);

    final newHighScore = score > game.highScore ? score : game.highScore;

    _games[gameId] = game.copyWith(
      unlockedLevel: nextLevel,
      highScore: newHighScore,
      starsPerLevel: updatedStars,
    );

    // Reward skill progression with Gems:
    // Base: 25 Gems + 10 Gems per star
    final earnedGems = 25 + (stars * 10);
    await WalletService.instance.addGems(
      earnedGems,
      reason: 'Cleared ${game.title} Level $levelNumber',
    );

    // Track total levels cleared across the platform
    await AuthService.instance.incrementLevelsCleared();

    await _saveStats();
    notifyListeners();
  }

  Future<void> _saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _games.map((k, v) => MapEntry(k, v.toJson()));
      await prefs.setString('arcade_hub_stats', jsonEncode(map));
    } catch (e) {
      debugPrint('Save stats error: $e');
    }
  }
}
