class GameStat {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int unlockedLevel;
  final int highScore;
  final Map<int, int> starsPerLevel; // levelNumber -> stars (1..3)

  const GameStat({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.unlockedLevel = 1,
    this.highScore = 0,
    this.starsPerLevel = const {},
  });

  int get totalStars => starsPerLevel.values.fold(0, (sum, s) => sum + s);

  GameStat copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    int? unlockedLevel,
    int? highScore,
    Map<int, int>? starsPerLevel,
  }) {
    return GameStat(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      unlockedLevel: unlockedLevel ?? this.unlockedLevel,
      highScore: highScore ?? this.highScore,
      starsPerLevel: starsPerLevel ?? this.starsPerLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'unlockedLevel': unlockedLevel,
      'highScore': highScore,
      'starsPerLevel': starsPerLevel.map((k, v) => MapEntry(k.toString(), v)),
    };
  }

  factory GameStat.fromJson(Map<String, dynamic> json) {
    final starsRaw = json['starsPerLevel'] as Map<String, dynamic>? ?? {};
    final stars = starsRaw.map((k, v) => MapEntry(int.tryParse(k) ?? 1, (v as num).toInt()));

    return GameStat(
      id: json['id'] as String? ?? 'bubble_shooter',
      title: json['title'] as String? ?? 'Bubble Shooter Arcade',
      description: json['description'] as String? ?? 'Hexagonal physics bubble shooter',
      icon: json['icon'] as String? ?? '🎯',
      unlockedLevel: (json['unlockedLevel'] as num?)?.toInt() ?? 1,
      highScore: (json['highScore'] as num?)?.toInt() ?? 0,
      starsPerLevel: stars,
    );
  }
}
