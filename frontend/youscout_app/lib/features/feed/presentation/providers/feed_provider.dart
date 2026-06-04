import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youscout_app/features/feed/data/feed_repository.dart';
import 'package:youscout_app/features/feed/data/models/video_model.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class FeedState {
  final List<VideoModel> videos;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int currentPage;

  const FeedState({
    this.videos = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 0,
  });

  FeedState copyWith({
    List<VideoModel>? videos,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? currentPage,
  }) =>
      FeedState(
        videos: videos ?? this.videos,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: error,
        currentPage: currentPage ?? this.currentPage,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class FeedNotifier extends Notifier<FeedState> {
  static const _pageSize = 10;

  @override
  FeedState build() {
    // Kick off initial load
    Future.microtask(loadFeed);
    return const FeedState(isLoading: true);
  }

  FeedRepository get _repo => ref.read(feedRepositoryProvider);

  Future<void> loadFeed() async {
    state = state.copyWith(isLoading: true, error: null, currentPage: 0);
    try {
      final videos = await _repo.getExploreFeed(page: 0, size: _pageSize);
      state = state.copyWith(
        videos: videos,
        isLoading: false,
        hasMore: videos.length == _pageSize,
        currentPage: 0,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final more = await _repo.getExploreFeed(page: nextPage, size: _pageSize);
      state = state.copyWith(
        videos: [...state.videos, ...more],
        isLoadingMore: false,
        hasMore: more.length == _pageSize,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Optimistic like toggle — flips the local state instantly, then syncs.
  Future<void> toggleLike(int index) async {
    final video = state.videos[index];
    final liked = !video.isLikedByCurrentUser;

    // Optimistic update
    final updated = List<VideoModel>.from(state.videos);
    updated[index] = video.copyWithLike(liked: liked);
    state = state.copyWith(videos: updated);

    try {
      if (liked) {
        await _repo.likeVideo(video.id);
      } else {
        await _repo.unlikeVideo(video.id);
      }
    } catch (_) {
      // If "like" fails (already liked), try "unlike" and vice versa
      // This handles the mismatch where backend state != UI state
      try {
        if (liked) {
          // "like" failed → probably already liked, try unlike then re-like
          await _repo.unlikeVideo(video.id);
          await _repo.likeVideo(video.id);
        } else {
          await _repo.likeVideo(video.id);
          await _repo.unlikeVideo(video.id);
        }
      } catch (_) {
        // Keep the optimistic update — don't revert, it's just a demo
      }
    }
  }

  void recordView(int index) {
    if (index >= 0 && index < state.videos.length) {
      _repo.recordView(state.videos[index].id);
    }
  }

  /// Increment the local comment count for a video (after posting a comment).
  void incrementCommentCount(String videoId) {
    final updated = state.videos.map((v) {
      if (v.id == videoId) {
        return v.copyWithCommentCount(v.commentsCount + 1);
      }
      return v;
    }).toList();
    state = state.copyWith(videos: updated);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final feedProvider = NotifierProvider<FeedNotifier, FeedState>(
  FeedNotifier.new,
);
