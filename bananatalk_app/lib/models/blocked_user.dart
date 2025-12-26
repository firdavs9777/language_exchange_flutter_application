// lib/models/blocked_user.dart
// Updated to match your actual backend response

class BlockedUser {
  final String userId;
  final String blockedUserName;
  final String? blockedUserEmail;
  final String? blockedUserAvatar;
  final String? blockedUserBio;
  final DateTime blockedAt;
  final String? reason;

  BlockedUser({
    required this.userId,
    required this.blockedUserName,
    this.blockedUserEmail,
    this.blockedUserAvatar,
    this.blockedUserBio,
    required this.blockedAt,
    this.reason,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    // Extract user data from nested structure
    final user = json['user'] as Map<String, dynamic>?;
    
    // Get avatar from images array
    String? avatar;
    if (user != null && user['images'] != null) {
      final images = user['images'] as List?;
      if (images != null && images.isNotEmpty) {
        avatar = images[0] as String?;
      }
    }
    
    return BlockedUser(
      userId: json['userId']?.toString() ?? '',
      blockedUserName: user?['name'] ?? 'Unknown User',
      blockedUserEmail: user?['email'],
      blockedUserAvatar: avatar,
      blockedUserBio: user?['bio'],
      blockedAt: json['blockedAt'] != null 
          ? DateTime.parse(json['blockedAt']) 
          : DateTime.now(),
      reason: json['reason'],
    );
  }

  // For backward compatibility with existing code
  String get blockedUserId => userId;
}