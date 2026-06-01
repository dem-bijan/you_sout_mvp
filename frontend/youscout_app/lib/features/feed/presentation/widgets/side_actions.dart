import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/video_model.dart';

/// Right-rail action buttons — like, comment, share, follow.
class SideActions extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onLike;

  const SideActions({
    super.key,
    required this.video,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // ── Like ─────────────────────────────────────────────
          _ActionButton(
            icon: video.isLikedByCurrentUser
                ? Icons.favorite
                : Icons.favorite_border,
            color: video.isLikedByCurrentUser
                ? AppColors.like
                : Colors.white,
            label: _formatCount(video.likesCount),
            onTap: onLike,
          ),
          const SizedBox(height: 20),

          // ── Comment ───────────────────────────────────────────
          _ActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            color: Colors.white,
            label: _formatCount(video.commentsCount),
            onTap: () {
              // TODO: open comments sheet
            },
          ),
          const SizedBox(height: 20),

          // ── Share ─────────────────────────────────────────────
          _ActionButton(
            icon: Icons.ios_share_rounded,
            color: Colors.white,
            label: 'Share',
            onTap: () {
              // TODO: share sheet
            },
          ),
          const SizedBox(height: 20),

          // ── Rotating profile ring ─────────────────────────────
          GestureDetector(
            onTap: () {
              // TODO: navigate to profile
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: CircleAvatar(
                radius: 20,
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
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
