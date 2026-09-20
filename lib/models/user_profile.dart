class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String avatarUrl;
  final int gemsBalance;
  final String referralCode;
  final String? referredBy;
  final bool isGuest;
  final DateTime joinedAt;
  final int totalLevelsCleared;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.gemsBalance,
    required this.referralCode,
    this.referredBy,
    required this.isGuest,
    required this.joinedAt,
    this.totalLevelsCleared = 0,
  });

  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? avatarUrl,
    int? gemsBalance,
    String? referralCode,
    String? referredBy,
    bool? isGuest,
    DateTime? joinedAt,
    int? totalLevelsCleared,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gemsBalance: gemsBalance ?? this.gemsBalance,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      isGuest: isGuest ?? this.isGuest,
      joinedAt: joinedAt ?? this.joinedAt,
      totalLevelsCleared: totalLevelsCleared ?? this.totalLevelsCleared,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'avatarUrl': avatarUrl,
      'gemsBalance': gemsBalance,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'isGuest': isGuest,
      'joinedAt': joinedAt.toIso8601String(),
      'totalLevelsCleared': totalLevelsCleared,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String? ?? 'guest_001',
      displayName: json['displayName'] as String? ?? 'Cyber Gamer',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      gemsBalance: (json['gemsBalance'] as num?)?.toInt() ?? 100,
      referralCode: json['referralCode'] as String? ?? 'IKRAM-7X9Y',
      referredBy: json['referredBy'] as String?,
      isGuest: json['isGuest'] as bool? ?? true,
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      totalLevelsCleared: (json['totalLevelsCleared'] as num?)?.toInt() ?? 0,
    );
  }
}
