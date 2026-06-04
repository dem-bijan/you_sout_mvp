import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youscout_app/core/theme/app_colors.dart';
import 'package:youscout_app/core/router/app_router.dart';
import 'package:youscout_app/core/network/api_client.dart';
import 'package:youscout_app/core/network/api_endpoints.dart';
import 'package:youscout_app/features/feed/presentation/widgets/comments_sheet.dart';

/// Full-screen video detail page opened from Discover or Profile grids.
/// Shows the video with its info, like/comment/share buttons.
class VideoDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> videoData;

  const VideoDetailScreen({super.key, required this.videoData});

  @override
  ConsumerState<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends ConsumerState<VideoDetailScreen> {
  late int _likesCount;
  late int _commentsCount;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _likesCount = (widget.videoData['likesCount'] as num?)?.toInt() ?? 0;
    _commentsCount = (widget.videoData['commentsCount'] as num?)?.toInt() ?? 0;
    _isLiked = (widget.videoData['isLikedByCurrentUser'] as bool?) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.videoData;
    final description = video['description'] as String? ?? '';
    final username = video['userUsername'] as String? ?? 'user';
    final displayName = video['userDisplayName'] as String? ?? username;
    final userId = video['userId'] as String? ?? '';
    final videoId = video['id'] as String? ?? '';
    final viewsCount = (video['viewsCount'] as num?)?.toInt() ?? 0;
    final hashtags = (video['hashtags'] as List<dynamic>?)
            ?.map((h) => '#$h')
            .join(' ') ??
        '';

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background gradient ──────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D1B2A),
                  Color(0xFF1B2838),
                  Color(0xFF0A4DA2),
                ],
              ),
            ),
          ),

          // Decorative elements
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.06),
              ),
            ),
          ),

          // ── Center content ──────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sport icon
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.3),
                          AppColors.secondary.withValues(alpha: 0.2),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.sports_soccer_rounded,
                      color: AppColors.primary,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  if (description.isNotEmpty)
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  if (hashtags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      hashtags,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatChip(
                          icon: Icons.visibility_rounded,
                          label: '$viewsCount views'),
                      const SizedBox(width: 20),
                      _StatChip(
                          icon: Icons.favorite_rounded,
                          label: '$_likesCount likes'),
                      const SizedBox(width: 20),
                      _StatChip(
                          icon: Icons.chat_bubble_rounded,
                          label: '$_commentsCount comments'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom gradient ─────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 220,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                ),
              ),
            ),
          ),

          // ── Bottom info bar ─────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info row
                    GestureDetector(
                      onTap: () {
                        if (userId.isNotEmpty) {
                          context.push(Routes.profilePath(userId));
                        }
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '@$username',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ActionPill(
                          icon: _isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _isLiked ? AppColors.like : Colors.white,
                          label: _isLiked ? 'Liked' : 'Like',
                          onTap: () {
                            setState(() {
                              _isLiked = !_isLiked;
                              _likesCount += _isLiked ? 1 : -1;
                            });
                          },
                        ),
                        _ActionPill(
                          icon: Icons.chat_bubble_outline_rounded,
                          color: Colors.white,
                          label: 'Comment',
                          onTap: () {
                            if (videoId.isNotEmpty) {
                              showCommentsSheet(context, ref, videoId,
                                  onCommentAdded: () {
                                setState(() => _commentsCount++);
                              });
                            }
                          },
                        ),
                        _ActionPill(
                          icon: Icons.person_outline_rounded,
                          color: Colors.white,
                          label: 'Profile',
                          onTap: () {
                            if (userId.isNotEmpty) {
                              context.push(Routes.profilePath(userId));
                            }
                          },
                        ),
                        _ActionPill(
                          icon: Icons.ios_share_rounded,
                          color: Colors.white,
                          label: 'Share',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Link copied!'),
                                backgroundColor: AppColors.primary,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white38, size: 14),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionPill({
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15), width: 0.5),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
