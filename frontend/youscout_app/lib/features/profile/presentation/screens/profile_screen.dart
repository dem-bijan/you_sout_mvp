import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider(userId));
    final authState    = ref.watch(authProvider).valueOrNull;
    final isOwnProfile = authState is AuthStateAuthenticated &&
        authState.userId == userId;

    if (profileState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2),
        ),
      );
    }

    if (profileState.error != null || profileState.user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off_outlined,
                  color: AppColors.textSecondary, size: 48),
              const SizedBox(height: 12),
              const Text('Profile not found',
                  style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    final user = profileState.user!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar with avatar ────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background gradient
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF0D1B2A), AppColors.background],
                      ),
                    ),
                  ),
                  // Avatar
                  Positioned(
                    bottom: 16,
                    left: 20,
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.surfaceElevated,
                      backgroundImage: user.avatarUrl != null
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null
                          ? Text(
                              user.displayName.isNotEmpty
                                  ? user.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (isOwnProfile)
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    // TODO: settings screen
                  },
                ),
            ],
          ),

          // ── Profile info ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + follow button row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '@${user.username}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (!isOwnProfile) ...[
                        const SizedBox(width: 12),
                        _FollowButton(
                          isFollowing: profileState.isFollowing,
                          isLoading: profileState.isFollowLoading,
                          onPressed: () => ref
                              .read(profileProvider(userId).notifier)
                              .toggleFollow(),
                        ),
                      ],
                    ],
                  ),

                  // Bio
                  if (user.bio.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      user.bio,
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Stats row
                  Row(
                    children: [
                      _StatBox(
                          label: 'Videos',
                          value: user.videoCount.toString()),
                      const SizedBox(width: 32),
                      _StatBox(
                          label: 'Followers',
                          value: _fmt(user.followerCount)),
                      const SizedBox(width: 32),
                      _StatBox(
                          label: 'Following',
                          value: _fmt(user.followingCount)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Divider(color: AppColors.borderSubtle, height: 1),
                ],
              ),
            ),
          ),

          // ── Video grid ─────────────────────────────────────────────
          profileState.videos.isEmpty
              ? const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam_off_outlined,
                            color: AppColors.textTertiary, size: 40),
                        SizedBox(height: 8),
                        Text('No videos yet',
                            style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(1),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final video = profileState.videos[index];
                        return GestureDetector(
                          onTap: () {
                            // TODO: open video
                          },
                          child: Container(
                            color: AppColors.surfaceCard,
                            child: video.thumbnailUrl != null
                                ? Image.network(
                                    video.thumbnailUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : const Center(
                                    child: Icon(Icons.play_circle_outline,
                                        color: AppColors.textSecondary,
                                        size: 32),
                                  ),
                          ),
                        );
                      },
                      childCount: profileState.videos.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 1,
                      crossAxisSpacing: 1,
                      childAspectRatio: 9 / 16,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final bool isLoading;
  final VoidCallback onPressed;

  const _FollowButton({
    required this.isFollowing,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor:
              isFollowing ? AppColors.textSecondary : AppColors.primary,
          side: BorderSide(
            color: isFollowing
                ? AppColors.borderDefault
                : AppColors.primary,
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                isFollowing ? 'Following' : 'Follow',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
