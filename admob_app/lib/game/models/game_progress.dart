import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages persistent progress: unlocked levels, stars, high scores, coins, settings
class GameProgress extends ChangeNotifier {
  static final GameProgress _instance = GameProgress._internal();
  factory GameProgress() => _instance;
  GameProgress._internal();

  int _unlockedLevel = 1;
  final Map<int, int> _starsPerLevel = {};
  final Map<int, int> _highScores = {};
  int _coins = 150;
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  bool _isInitialized = false;

  int get unlockedLevel => _unlockedLevel;
  int get coins => _coins;
  bool get soundEnabled => _soundEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get isInitialized => _isInitialized;

  int getStarsForLevel(int level) => _starsPerLevel[level] ?? 0;
  int getHighScoreForLevel(int level) => _highScores[level] ?? 0;

  int get totalStars => _starsPerLevel.values.fold(0, (sum, s) => sum + s);

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      _unlockedLevel = prefs.getInt('unlocked_level') ?? 1;
      _coins = prefs.getInt('coins') ?? 150;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _hapticsEnabled = prefs.getBool('haptics_enabled') ?? true;

      for (int i = 1; i <= 40; i++) {
        final stars = prefs.getInt('stars_level_$i');
        if (stars != null) _starsPerLevel[i] = stars;

        final hs = prefs.getInt('highscore_level_$i');
        if (hs != null) _highScores[i] = hs;
      }
    } catch (e) {
      debugPrint('SharedPreferences init fallback: $e');
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> saveLevelResult(int level, int score, int stars) async {
    // Update in-memory state
    final currentStars = _starsPerLevel[level] ?? 0;
    if (stars > currentStars) {
      _starsPerLevel[level] = stars;
    }

    final currentHs = _highScores[level] ?? 0;
    if (score > currentHs) {
      _highScores[level] = score;
    }

    if (stars > 0 && level >= _unlockedLevel && level < 40) {
      _unlockedLevel = level + 1;
    }

    final coinReward = stars * 15;
    _coins += coinReward;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (stars > currentStars) {
        await prefs.setInt('stars_level_$level', stars);
      }
      if (score > currentHs) {
        await prefs.setInt('highscore_level_$level', score);
      }
      if (stars > 0) {
        await prefs.setInt('unlocked_level', _unlockedLevel);
      }
      await prefs.setInt('coins', _coins);
    } catch (e) {
      debugPrint('SharedPreferences save error: $e');
    }
  }

  Future<void> addCoins(int amount) async {
    _coins += amount;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('coins', _coins);
    } catch (e) {
      debugPrint('SharedPreferences coins error: $e');
    }
  }

  Future<bool> spendCoins(int amount) async {
    if (_coins < amount) return false;
    _coins -= amount;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('coins', _coins);
    } catch (e) {
      debugPrint('SharedPreferences spend coins error: $e');
    }
    return true;
  }

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sound_enabled', _soundEnabled);
    } catch (e) {
      debugPrint('SharedPreferences toggle sound error: $e');
    }
  }

  Future<void> toggleHaptics() async {
    _hapticsEnabled = !_hapticsEnabled;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('haptics_enabled', _hapticsEnabled);
    } catch (e) {
      debugPrint('SharedPreferences toggle haptics error: $e');
    }
  }

  Future<void> resetProgress() async {
    _unlockedLevel = 1;
    _starsPerLevel.clear();
    _highScores.clear();
    _coins = 150;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint('SharedPreferences reset error: $e');
    }
  }
}
