import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youscout_app/core/theme/app_colors.dart';
import 'package:youscout_app/core/network/api_client.dart';
import 'package:youscout_app/core/network/api_endpoints.dart';
import 'package:youscout_app/core/router/app_router.dart';
import 'package:youscout_app/features/feed/presentation/screens/video_detail_screen.dart';

/// Discover screen showing trending videos and user search.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  List<Map<String, dynamic>> _trendingVideos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadTrending);
  }

  Future<void> _loadTrending() async {
    try {
      final dio = ref.read(apiClientProvider).dio;
      final response = await dio.get(
        ApiEndpoints.trendingVideos,
        queryParameters: {'page': 0, 'size': 20},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>;
      final content = data['content'] as List<dynamic>;
      setState(() {
        _trendingVideos =
            content.map((v) => v as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
      ),
      body: Column(
        children: [
          // ── Search bar ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle, width: 0.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Row(
                children: [
                  Icon(Icons.search, color: AppColors.textTertiary, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search players, skills, hashtags…',
                        hintStyle: TextStyle(
                            color: AppColors.textTertiary, fontSize: 14),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Section title ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.trending_up_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Trending Videos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_trendingVideos.length} videos',
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ),

          // ── Content ────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off_rounded,
                                color: AppColors.textSecondary, size: 48),
                            const SizedBox(height: 12),
                            const Text('Could not load trending',
                                style: TextStyle(
                                    color: AppColors.textSecondary)),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLoading = true;
                                  _error = null;
                                });
                                _loadTrending();
                              },
                              child: const Text('Retry',
                                  style: TextStyle(color: AppColors.primary)),
                            ),
                          ],
                        ),
                      )
                    : _trendingVideos.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.explore_outlined,
                                    color: AppColors.textTertiary, size: 56),
                                SizedBox(height: 12),
                                Text('No trending videos yet',
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 16)),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 9 / 16,
                            ),
                            itemCount: _trendingVideos.length,
                            itemBuilder: (context, index) {
                              final video = _trendingVideos[index];
                              final description =
                                  video['description'] as String? ?? '';
                              final username =
                                  video['userUsername'] as String? ?? 'user';
                              final displayName =
                                  video['userDisplayName'] as String? ??
                                      username;
                              final likesCount =
                                  (video['likesCount'] as num?)?.toInt() ?? 0;
                              final viewsCount =
                                  (video['viewsCount'] as num?)?.toInt() ?? 0;
                              final userId = video['userId'] as String? ?? '';
                              final thumbnailUrl =
                                  video['thumbnailUrl'] as String?;

                              return GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => VideoDetailScreen(
                                        videoData: video,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceCard,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.borderSubtle,
                                        width: 0.5),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      // Thumbnail or placeholder
                                      if (thumbnailUrl != null)
                                        Image.network(thumbnailUrl,
                                            fit: BoxFit.cover)
                                      else
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                AppColors.primary
                                                    .withOpacity(0.3),
                                                AppColors.surfaceCard,
                                              ],
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                                Icons.play_circle_outline,
                                                color: AppColors.primary,
                                                size: 44),
                                          ),
                                        ),

                                      // Bottom info overlay
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                Colors.black87,
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(10),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                description.isNotEmpty
                                                    ? description
                                                    : 'Video by @$username',
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 10,
                                                    backgroundColor:
                                                        AppColors.primary,
                                                    child: Text(
                                                      displayName.isNotEmpty
                                                          ? displayName[0]
                                                              .toUpperCase()
                                                          : '?',
                                                      style: const TextStyle(
                                                          fontSize: 10,
                                                          color:
                                                              Colors.white),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      '@$username',
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      style: const TextStyle(
                                                          color: Colors
                                                              .white70,
                                                          fontSize: 11),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  const Icon(
                                                      Icons
                                                          .favorite_rounded,
                                                      color: AppColors.like,
                                                      size: 14),
                                                  const SizedBox(width: 3),
                                                  Text('$likesCount',
                                                      style:
                                                          const TextStyle(
                                                              color: Colors
                                                                  .white70,
                                                              fontSize:
                                                                  11)),
                                                  const SizedBox(width: 12),
                                                  const Icon(
                                                      Icons
                                                          .visibility_rounded,
                                                      color:
                                                          Colors.white54,
                                                      size: 14),
                                                  const SizedBox(width: 3),
                                                  Text('$viewsCount',
                                                      style:
                                                          const TextStyle(
                                                              color: Colors
                                                                  .white70,
                                                              fontSize:
                                                                  11)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
