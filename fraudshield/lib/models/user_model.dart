class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final bool isEmailVerified;
  final DateTime createdAt;
  final UserProfile? profile;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    required this.isEmailVerified,
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
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      profile: json['profile'] != null ? UserProfile.fromJson(json['profile']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt.toIso8601String(),
      'profile': profile?.toJson(),
    };
  }
}

class UserProfile {
  final String id;
  final String? avatar;
  final String? bio;
  final Map<String, dynamic>? metadata;

  UserProfile({
    required this.id,
    this.avatar,
    this.bio,
    this.metadata,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      avatar: json['avatar'],
      bio: json['bio'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'avatar': avatar,
      'bio': bio,
      'metadata': metadata,
    };
  }
}
