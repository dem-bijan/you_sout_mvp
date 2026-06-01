import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_repository.dart';
import '../../auth/data/models/user_model.dart';
import '../../feed/data/models/video_model.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class ProfileState {
  final UserModel? user;
  final List<VideoModel> videos;
  final bool isFollowing;
  final bool isLoading;
  final bool isFollowLoading;
  final String? error;

  const ProfileState({
    this.user,
    this.videos = const [],
    this.isFollowing = false,
    this.isLoading = false,
    this.isFollowLoading = false,
    this.error,
  });

  ProfileState copyWith({
    UserModel? user,
    List<VideoModel>? videos,
    bool? isFollowing,
    bool? isLoading,
    bool? isFollowLoading,
    String? error,
  }) =>
      ProfileState(
        user: user ?? this.user,
        videos: videos ?? this.videos,
        isFollowing: isFollowing ?? this.isFollowing,
        isLoading: isLoading ?? this.isLoading,
        isFollowLoading: isFollowLoading ?? this.isFollowLoading,
        error: error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ProfileNotifier extends FamilyNotifier<ProfileState, String> {
  @override
  ProfileState build(String userId) {
    Future.microtask(() => _load(userId));
    return const ProfileState(isLoading: true);
  }

  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  Future<void> _load(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _repo.getUserById(userId),
        _repo.getUserVideos(userId),
        _repo.isFollowing(userId),
      ]);
      state = state.copyWith(
        user: results[0] as UserModel,
        videos: results[1] as List<VideoModel>,
        isFollowing: results[2] as bool,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleFollow() async {
    final user = state.user;
    if (user == null || state.isFollowLoading) return;

    final wasFollowing = state.isFollowing;
    // Optimistic update
    state = state.copyWith(
      isFollowing: !wasFollowing,
      isFollowLoading: true,
      user: UserModel(
        id: user.id,
        username: user.username,
        displayName: user.displayName,
        bio: user.bio,
        avatarUrl: user.avatarUrl,
        followerCount:
            wasFollowing ? user.followerCount - 1 : user.followerCount + 1,
        followingCount: user.followingCount,
        videoCount: user.videoCount,
      ),
    );

    try {
      if (wasFollowing) {
        await _repo.unfollow(user.id);
      } else {
        await _repo.follow(user.id);
      }
    } catch (_) {
      // Revert on failure
      state = state.copyWith(
        isFollowing: wasFollowing,
        user: user,
      );
    } finally {
      state = state.copyWith(isFollowLoading: false);
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// Family provider — one instance per userId.
final profileProvider =
    NotifierProviderFamily<ProfileNotifier, ProfileState, String>(
  ProfileNotifier.new,
);
