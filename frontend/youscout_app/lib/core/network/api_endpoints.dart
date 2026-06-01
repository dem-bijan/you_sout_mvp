/// All API endpoint constants, grouped by service.
///
/// The gateway prefix is already set in ApiClient.baseUrl so every
/// path here starts after `/api`.
class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth / Users ─────────────────────────────────────────
  static const String register          = '/users/register';
  static const String login             = '/users/login';
  static const String refresh           = '/users/refresh';
  static const String logout            = '/users/logout';
  static const String ownProfile        = '/users/profile';
  static const String updateProfile     = '/users/profile';
  static String userById(String id)     => '/users/$id';
  static String userStats(String id)    => '/users/$id/stats';
  static String checkUsername(String u) => '/users/check-username/$u';

  // ── Videos ───────────────────────────────────────────────
  static const String uploadVideo       = '/videos';
  static const String skills            = '/videos/skills';
  static const String trendingVideos    = '/videos/trending';
  static String videoById(String id)    => '/videos/$id';
  static String videosByUser(String id) => '/videos/user/$id';
  static String likeVideo(String id)    => '/videos/$id/like';
  static String viewVideo(String id)    => '/videos/$id/view';

  // ── Feed ─────────────────────────────────────────────────
  static const String personalFeed = '/feed';
  static const String exploreFeed  = '/feed/explore';

  // ── Comments ─────────────────────────────────────────────
  static const String createComment           = '/comments';
  static String commentsByVideo(String videoId) => '/comments/video/$videoId';
  static String deleteComment(String id)        => '/comments/$id';

  // ── Social ───────────────────────────────────────────────
  static String follow(String targetId)      => '/social/follow/$targetId';
  static String isFollowing(String targetId) => '/social/is-following/$targetId';
  static String followers(String userId)     => '/social/$userId/followers';
  static String following(String userId)     => '/social/$userId/following';

  // ── Notifications ────────────────────────────────────────
  static const String notifications        = '/notifications';
  static const String markRead             = '/notifications/mark-read';
  static const String markAllRead          = '/notifications/mark-all-read';
  static const String unreadCount          = '/notifications/unread-count';
}
