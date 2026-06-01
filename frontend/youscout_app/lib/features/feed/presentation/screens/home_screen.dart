import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/feed_provider.dart';
import '../widgets/video_item.dart';

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
              // TODO: swap to personal feed tab
              child: const Text(
                'For You',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              // TODO: swap to following tab
              child: Text(
                'Following',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () {
              // TODO: navigate to discover
            },
          ),
        ],
      ),
      body: PageView.builder(
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
