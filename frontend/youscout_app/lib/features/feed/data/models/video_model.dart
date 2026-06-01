/// Mirrors VideoDTO from the backend per spec §5.4.
class VideoModel {
  final String id;
  final String userId;
  final String userUsername;
  final String userDisplayName;
  final String? userAvatarUrl;
  final String? title;
  final String? description;
  final String videoUrl;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final List<SkillModel> skills;
  final List<String> hashtags;
  final bool isLikedByCurrentUser;
  final String? createdAt;

  const VideoModel({
    required this.id,
    required this.userId,
    required this.userUsername,
    required this.userDisplayName,
    this.userAvatarUrl,
    this.title,
    this.description,
    required this.videoUrl,
    this.thumbnailUrl,
    this.durationSeconds,
    required this.viewsCount,
    required this.likesCount,
    required this.commentsCount,
    required this.skills,
    required this.hashtags,
    required this.isLikedByCurrentUser,
    this.createdAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) => VideoModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        userUsername: json['userUsername'] as String,
        userDisplayName: json['userDisplayName'] as String,
        userAvatarUrl: json['userAvatarUrl'] as String?,
        title: json['title'] as String?,
        description: json['description'] as String?,
        videoUrl: json['videoUrl'] as String,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
        viewsCount: (json['viewsCount'] as num?)?.toInt() ?? 0,
        likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
        commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
        skills: (json['skills'] as List<dynamic>?)
                ?.map((s) => SkillModel.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        hashtags: (json['hashtags'] as List<dynamic>?)
                ?.map((h) => h as String)
                .toList() ??
            [],
        isLikedByCurrentUser:
            (json['isLikedByCurrentUser'] as bool?) ?? false,
        createdAt: json['createdAt'] as String?,
      );

  /// Return a copy with updated like state (optimistic UI).
  VideoModel copyWithLike({required bool liked}) => VideoModel(
        id: id,
        userId: userId,
        userUsername: userUsername,
        userDisplayName: userDisplayName,
        userAvatarUrl: userAvatarUrl,
        title: title,
        description: description,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        durationSeconds: durationSeconds,
        viewsCount: viewsCount,
        likesCount: liked ? likesCount + 1 : (likesCount - 1).clamp(0, 999999),
        commentsCount: commentsCount,
        skills: skills,
        hashtags: hashtags,
        isLikedByCurrentUser: liked,
        createdAt: createdAt,
      );
}

class SkillModel {
  final String id;
  final String name;
  final String? iconName;

  const SkillModel({required this.id, required this.name, this.iconName});

  factory SkillModel.fromJson(Map<String, dynamic> json) => SkillModel(
        id: json['id'] as String,
        name: json['name'] as String,
        iconName: json['iconName'] as String?,
      );
}
