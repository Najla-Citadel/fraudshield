class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final bool isEmailVerified;
  final String? acceptedTermsVersion;
  final DateTime? acceptedTermsAt;
  final DateTime createdAt;
  final UserProfile? profile;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    required this.isEmailVerified,
    this.acceptedTermsVersion,
    this.acceptedTermsAt,
    required this.createdAt,
    this.profile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      acceptedTermsVersion: json['acceptedTermsVersion'],
      acceptedTermsAt: json['acceptedTermsAt'] != null
          ? DateTime.parse(json['acceptedTermsAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      profile: json['profile'] != null
          ? UserProfile.fromJson(json['profile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'isEmailVerified': isEmailVerified,
      'acceptedTermsVersion': acceptedTermsVersion,
      'acceptedTermsAt': acceptedTermsAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'profile': profile?.toJson(),
    };
  }
}

class UserProfile {
  final String id;
  final String? avatar;
  final String? bio;
  final int points;
  final int totalPoints;
  final int reputation;
  final int loginStreak;
  final List<String> badges;
  final Map<String, dynamic>? metadata;

  UserProfile({
    required this.id,
    this.avatar,
    this.bio,
    this.points = 0,
    this.totalPoints = 0,
    this.reputation = 0,
    this.loginStreak = 0,
    this.badges = [],
    this.metadata,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      avatar: json['avatar'],
      bio: json['bio'],
      points: json['points'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      reputation: json['reputation'] ?? 0,
      loginStreak: json['loginStreak'] ?? 0,
      badges: (json['badges'] as List<dynamic>?)?.cast<String>() ?? [],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'avatar': avatar,
      'bio': bio,
      'points': points,
      'totalPoints': totalPoints,
      'reputation': reputation,
      'loginStreak': loginStreak,
      'badges': badges,
      'metadata': metadata,
    };
  }
}
