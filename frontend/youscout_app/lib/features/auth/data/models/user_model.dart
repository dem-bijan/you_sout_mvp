/// Mirrors the UserDTO from the backend per spec §5.3.
class UserModel {
  final String id;
  final String username;
  final String displayName;
  final String bio;
  final String? avatarUrl;
  final int followerCount;
  final int followingCount;
  final int videoCount;
  final bool isFollowedByCurrentUser;

  const UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    required this.bio,
    this.avatarUrl,
    required this.followerCount,
    required this.followingCount,
    required this.videoCount,
    this.isFollowedByCurrentUser = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        username: json['username'] as String,
        displayName: json['displayName'] as String,
        bio: (json['bio'] as String?) ?? '',
        avatarUrl: json['avatarUrl'] as String?,
        followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
        followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
        videoCount: (json['videoCount'] as num?)?.toInt() ?? 0,
        isFollowedByCurrentUser:
            (json['isFollowedByCurrentUser'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        'bio': bio,
        'avatarUrl': avatarUrl,
        'followerCount': followerCount,
        'followingCount': followingCount,
        'videoCount': videoCount,
        'isFollowedByCurrentUser': isFollowedByCurrentUser,
      };
}
