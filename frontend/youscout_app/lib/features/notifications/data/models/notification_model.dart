class NotificationModel {
  final String id;
  final String type; // NEW_FOLLOWER | VIDEO_LIKED | NEW_COMMENT
  final String actorId;
  final String actorUsername;
  final String? actorAvatarUrl;
  final String? referenceId;
  final String? referencePreview;
  final bool isRead;
  final String createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.actorId,
    required this.actorUsername,
    this.actorAvatarUrl,
    this.referenceId,
    this.referencePreview,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as String,
        type: json['type'] as String,
        actorId: json['actorId'] as String,
        actorUsername: json['actorUsername'] as String,
        actorAvatarUrl: json['actorAvatarUrl'] as String?,
        referenceId: json['referenceId'] as String?,
        referencePreview: json['referencePreview'] as String?,
        isRead: (json['isRead'] as bool?) ?? false,
        createdAt: json['createdAt'] as String,
      );

  String get bodyText => switch (type) {
        'NEW_FOLLOWER' => '@$actorUsername started following you',
        'VIDEO_LIKED'  => '@$actorUsername liked your video',
        'NEW_COMMENT'  =>
          '@$actorUsername commented: ${referencePreview ?? ''}',
        _              => '@$actorUsername interacted with you',
      };

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        type: type,
        actorId: actorId,
        actorUsername: actorUsername,
        actorAvatarUrl: actorAvatarUrl,
        referenceId: referenceId,
        referencePreview: referencePreview,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}
