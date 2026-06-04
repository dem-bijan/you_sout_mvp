import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:youscout_app/core/theme/app_colors.dart';
import 'package:youscout_app/features/feed/data/models/video_model.dart';
import 'package:youscout_app/features/feed/presentation/providers/feed_provider.dart';
import 'package:youscout_app/features/feed/presentation/widgets/video_info_panel.dart';
import 'package:youscout_app/features/feed/presentation/widgets/side_actions.dart';

/// Full-screen video item for the vertical PageView feed.
///
/// Handles its own VideoPlayerController lifecycle — plays when visible,
/// pauses when scrolled away.
class VideoItem extends ConsumerStatefulWidget {
  final VideoModel video;
  final int index;
  final bool isActive; // true when this page is the current page

  const VideoItem({
    super.key,
    required this.video,
    required this.index,
    required this.isActive,
  });

  @override
  ConsumerState<VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends ConsumerState<VideoItem> {
  VideoPlayerController? _controller;
  bool _initialised = false;
  bool _videoError = false;
  bool _showPlayIcon = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // MinIO returns localhost:9000 URLs but Android emulator can't reach localhost
    String url = widget.video.videoUrl;
    if (url.contains('localhost:9000')) {
      url = url.replaceAll('localhost:9000', '10.0.2.2:9000');
    }
    if (url.contains('localhost')) {
      url = url.replaceAll('localhost', '10.0.2.2');
    }
    final ctrl = VideoPlayerController.networkUrl(
      Uri.parse(url),
    );
    try {
      await ctrl.initialize();
      ctrl.setLooping(true);
      _controller = ctrl;
      if (mounted) {
        setState(() => _initialised = true);
        if (widget.isActive) ctrl.play();
      }
    } catch (e) {
      // Video failed to load — show beautiful demo placeholder
      if (mounted) setState(() => _videoError = true);
    }
  }

  @override
  void didUpdateWidget(VideoItem old) {
    super.didUpdateWidget(old);
    if (widget.isActive != old.isActive) {
      if (widget.isActive) {
        _controller?.play();
        ref.read(feedProvider.notifier).recordView(widget.index);
      } else {
        _controller?.pause();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    if (_controller == null) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _showPlayIcon = true;
      } else {
        _controller!.play();
        _showPlayIcon = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: _initialised ? _togglePlayback : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background / video ────────────────────────────────
          Container(color: Colors.black),

          if (_initialised && _controller != null)
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            )
          else if (_videoError)
            // Beautiful fallback when video can't play
            _VideoFallback(video: widget.video, index: widget.index)
          else
            // Thumbnail or shimmer while loading
            widget.video.thumbnailUrl != null
                ? Image.network(
                    widget.video.thumbnailUrl!,
                    fit: BoxFit.cover,
                    width: size.width,
                    height: size.height,
                  )
                : const _LoadingShimmer(),

          // ── Gradient overlays ─────────────────────────────────
          // Bottom gradient for text readability
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.45,
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

          // ── Pause icon flash ──────────────────────────────────
          if (_showPlayIcon)
            Center(
              child: AnimatedOpacity(
                opacity: _showPlayIcon ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pause_rounded,
                      color: Colors.white, size: 36),
                ),
              ),
            ),

          // ── Info panel (bottom left) ──────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoInfoPanel(video: widget.video),
          ),

          // ── Side actions (right rail) ─────────────────────────
          Positioned(
            right: 0,
            bottom: 0,
            child: SideActions(
              video: widget.video,
              onLike: () =>
                  ref.read(feedProvider.notifier).toggleLike(widget.index),
            ),
          ),

          // ── Progress bar ──────────────────────────────────────
          if (_initialised && _controller != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: AppColors.primary,
                  backgroundColor: Colors.white24,
                  bufferedColor: Colors.white38,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Beautiful fallback shown when video can't play.
/// Shows a dynamic gradient background with sport-themed visuals.
class _VideoFallback extends StatelessWidget {
  final VideoModel video;
  final int index;

  const _VideoFallback({required this.video, required this.index});

  @override
  Widget build(BuildContext context) {
    // Different gradient for each video to make the feed look varied
    final gradients = [
      [const Color(0xFF0D1B2A), const Color(0xFF1B2838), const Color(0xFF0A4DA2)],
      [const Color(0xFF1A0A2E), const Color(0xFF16213E), const Color(0xFF533483)],
      [const Color(0xFF0B0E11), const Color(0xFF1D3557), const Color(0xFF457B9D)],
    ];
    final colors = gradients[index % gradients.length];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Decorative circles
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
            bottom: 120,
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
          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sport icon
                Container(
                  width: 80,
                  height: 80,
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
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                // Video title/description preview
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    video.description ?? 'Football Highlights',
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Stats row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility_rounded,
                        color: Colors.white38, size: 14),
                    const SizedBox(width: 4),
                    Text('${video.viewsCount} views',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                    const SizedBox(width: 16),
                    const Icon(Icons.favorite_rounded,
                        color: Colors.white38, size: 14),
                    const SizedBox(width: 4),
                    Text('${video.likesCount} likes',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceCard,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
