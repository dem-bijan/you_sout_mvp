import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youscout_app/features/notifications/data/notifications_repository.dart';
import 'package:youscout_app/features/notifications/data/models/notification_model.dart';

class NotificationsState {
  final List<NotificationModel> items;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  const NotificationsState({
    this.items = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationsState copyWith({
    List<NotificationModel>? items,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) =>
      NotificationsState(
        items: items ?? this.items,
        unreadCount: unreadCount ?? this.unreadCount,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  @override
  NotificationsState build() {
    Future.microtask(load);
    return const NotificationsState(isLoading: true);
  }

  NotificationsRepository get _repo =>
      ref.read(notificationsRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _repo.getNotifications(),
        _repo.getUnreadCount(),
      ]);
      state = state.copyWith(
        items: results[0] as List<NotificationModel>,
        unreadCount: results[1] as int,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAllRead() async {
    // Optimistic
    final updated = state.items.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(items: updated, unreadCount: 0);
    try {
      await _repo.markAllRead();
    } catch (_) {
      await load(); // revert by reloading
    }
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(
  NotificationsNotifier.new,
);

/// Convenient provider just for the unread badge count.
final unreadCountProvider = Provider<int>(
  (ref) => ref.watch(notificationsProvider).unreadCount,
);
