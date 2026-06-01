import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/video_model.dart';
import '../providers/feed_provider.dart';
import 'video_info_panel.dart';
import 'side_actions.dart';

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
  bool _showPlayIcon = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final ctrl = VideoPlayerController.networkUrl(
      Uri.parse(widget.video.videoUrl),
    );
    await ctrl.initialize();
    ctrl.setLooping(true);
    _controller = ctrl;
    if (mounted) {
      setState(() => _initialised = true);
      if (widget.isActive) ctrl.play();
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
      onTap: _togglePlayback,
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
                  decoration: BoxDecoration(
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
