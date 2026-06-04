import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youscout_app/core/theme/app_colors.dart';
import 'package:youscout_app/features/feed/presentation/providers/feed_provider.dart';
import 'package:youscout_app/features/feed/presentation/widgets/video_item.dart';

/// The main feed screen — full-screen vertical PageView (TikTok-style).
///
/// - Loads the explore feed on first visit.
/// - Triggers [FeedNotifier.loadMore] when 3 pages from the end.
/// - Each page is a full-viewport [VideoItem] that self-manages playback.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _pageController = PageController();
  int _currentIndex = 0;
  bool _isForYouTab = true;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final page = _pageController.page?.round() ?? 0;
    if (page != _currentIndex) {
      setState(() => _currentIndex = page);
    }

    // Load more when 3 videos from the end
    final total = ref.read(feedProvider).videos.length;
    if (page >= total - 3) {
      ref.read(feedProvider.notifier).loadMore();
    }
  }

  void _switchTab(bool forYou) {
    if (_isForYouTab == forYou) return;
    setState(() => _isForYouTab = forYou);
    // Reset page controller
    _currentIndex = 0;
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    // Reload feed — both tabs use trending for demo
    ref.read(feedProvider.notifier).loadFeed();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);

    // ── Loading first page ────────────────────────────────────────────────────
    if (feedState.isLoading && feedState.videos.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
              SizedBox(height: 16),
              Text(
                'Loading feed…',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // ── Error state (empty feed) ──────────────────────────────────────────────
    if (feedState.error != null && feedState.videos.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: AppColors.textSecondary, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Could not load feed',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.read(feedProvider.notifier).loadFeed(),
                child: const Text('Retry',
                    style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ),
      );
    }

    final videos = feedState.videos;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _switchTab(true),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'For You',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: _isForYouTab ? FontWeight.w700 : FontWeight.w400,
                      color: _isForYouTab ? Colors.white : Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 24,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: _isForYouTab ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            GestureDetector(
              onTap: () => _switchTab(false),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Following',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: !_isForYouTab ? FontWeight.w700 : FontWeight.w400,
                      color: !_isForYouTab ? Colors.white : Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 24,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: !_isForYouTab ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: videos.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam_off_outlined,
                      color: AppColors.textTertiary, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    _isForYouTab
                        ? 'No videos yet'
                        : 'Follow users to see their videos here',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            )
          : PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: videos.length + (feedState.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                // Loading spinner at the bottom while fetching more
                if (index >= videos.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                    ),
                  );
                }

                return VideoItem(
                  key: ValueKey(videos[index].id),
                  video: videos[index],
                  index: index,
                  isActive: index == _currentIndex,
                );
              },
            ),
    );
  }
}
