import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/video_model.dart';
import 'skill_chip.dart';

/// Overlaid on the bottom of each video — username, description, skill chips, hashtags.
class VideoInfoPanel extends StatelessWidget {
  final VideoModel video;

  const VideoInfoPanel({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 72, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Username ────────────────────────────────────────────
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceElevated,
                backgroundImage: video.userAvatarUrl != null
                    ? NetworkImage(video.userAvatarUrl!)
                    : null,
                child: video.userAvatarUrl == null
                    ? Text(
                        video.userDisplayName.isNotEmpty
                            ? video.userDisplayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.userDisplayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '@${video.userUsername}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Description ─────────────────────────────────────────
          if (video.description != null && video.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              video.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ],

          // ── Skill chips ─────────────────────────────────────────
          if (video.skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  video.skills.map((s) => SkillChip(skill: s)).toList(),
            ),
          ],

          // ── Hashtags ────────────────────────────────────────────
          if (video.hashtags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              children: video.hashtags
                  .take(4)
                  .map(
                    (tag) => Text(
                      '#$tag',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
