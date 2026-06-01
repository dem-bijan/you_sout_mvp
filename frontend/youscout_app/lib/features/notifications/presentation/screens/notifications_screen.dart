import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/theme/app_colors.dart';
import '../providers/notifications_provider.dart';
import '../../data/models/notification_model.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(color: AppColors.primary, fontSize: 13),
              ),
            ),
        ],
      ),
      body: Builder(builder: (context) {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2),
          );
        }

        if (state.error != null && state.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded,
                    color: AppColors.textSecondary, size: 40),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      ref.read(notificationsProvider.notifier).load(),
                  child: const Text('Retry',
                      style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          );
        }

        if (state.items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_none_rounded,
                    color: AppColors.textTertiary, size: 48),
                SizedBox(height: 12),
                Text('No notifications yet',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 15)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceCard,
          onRefresh: () =>
              ref.read(notificationsProvider.notifier).load(),
          child: ListView.separated(
            itemCount: state.items.length,
            separatorBuilder: (_, __) =>
                const Divider(color: AppColors.borderSubtle, height: 0.5),
            itemBuilder: (context, index) {
              return _NotificationTile(item: state.items[index]);
            },
          ),
        );
      }),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel item;

  const _NotificationTile({required this.item});

  IconData get _icon => switch (item.type) {
        'NEW_FOLLOWER' => Icons.person_add_rounded,
        'VIDEO_LIKED'  => Icons.favorite_rounded,
        'NEW_COMMENT'  => Icons.chat_bubble_rounded,
        _              => Icons.notifications_rounded,
      };

  Color get _iconColor => switch (item.type) {
        'NEW_FOLLOWER' => AppColors.primary,
        'VIDEO_LIKED'  => AppColors.like,
        'NEW_COMMENT'  => AppColors.secondary,
        _              => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: item.isRead
          ? Colors.transparent
          : AppColors.primaryGlow.withOpacity(0.05),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.surfaceElevated,
              backgroundImage: item.actorAvatarUrl != null
                  ? NetworkImage(item.actorAvatarUrl!)
                  : null,
              child: item.actorAvatarUrl == null
                  ? Text(
                      item.actorUsername.isNotEmpty
                          ? item.actorUsername[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: _iconColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 1.5),
                ),
                child: Icon(_icon, size: 10, color: Colors.white),
              ),
            ),
          ],
        ),
        title: Text(
          item.bodyText,
          style: TextStyle(
            fontSize: 14,
            color: item.isRead
                ? AppColors.textSecondary
                : AppColors.textPrimary,
            fontWeight:
                item.isRead ? FontWeight.w400 : FontWeight.w500,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            timeago.format(DateTime.tryParse(item.createdAt) ??
                DateTime.now()),
            style: const TextStyle(
                fontSize: 12, color: AppColors.textTertiary),
          ),
        ),
        trailing: item.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }
}
