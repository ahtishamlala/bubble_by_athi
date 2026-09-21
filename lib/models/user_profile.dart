class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String phone;
  final String avatarUrl;
  final String? avatarPath; // Custom image path picked from camera/gallery
  final String? dateOfBirth; // e.g. "1998-05-15"
  final String? gender; // "Male", "Female", "Other"
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
    this.phone = '',
    required this.avatarUrl,
    this.avatarPath,
    this.dateOfBirth,
    this.gender,
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
    String? phone,
    String? avatarUrl,
    String? avatarPath,
    String? dateOfBirth,
    String? gender,
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
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarPath: avatarPath ?? this.avatarPath,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
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
      'phone': phone,
      'avatarUrl': avatarUrl,
      'avatarPath': avatarPath,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
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
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      avatarPath: json['avatarPath'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      gender: json['gender'] as String?,
      gemsBalance: (json['gemsBalance'] as num?)?.toInt() ?? 100,
      referralCode: json['referralCode'] as String? ?? 'PLAYER-7X9Y',
      referredBy: json['referredBy'] as String?,
      isGuest: json['isGuest'] as bool? ?? true,
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      totalLevelsCleared: (json['totalLevelsCleared'] as num?)?.toInt() ?? 0,
    );
  }
}
