import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youscout_app/core/theme/app_colors.dart';
import 'package:youscout_app/core/router/app_router.dart';
import 'package:youscout_app/core/providers/auth_provider.dart';
import 'package:youscout_app/core/storage/secure_storage.dart';
import 'package:youscout_app/features/notifications/presentation/providers/notifications_provider.dart';

/// Persistent bottom navigation bar.
///
/// Sits outside the router so the bar persists across tab switches.
/// Each tab's icon lights up with the primary color when selected.
class BottomNavBar extends ConsumerWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_filled,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => context.go(Routes.home),
              ),
              _NavItem(
                icon: Icons.explore_outlined,
                label: 'Discover',
                isSelected: currentIndex == 1,
                onTap: () => context.go(Routes.discover),
              ),
              // Upload button — larger, accent-colored
              GestureDetector(
                onTap: () => context.push(Routes.upload),
                child: Container(
                  width: 44,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 26),
                ),
              ),
              _NavItem(
                icon: Icons.notifications_outlined,
                label: 'Inbox',
                isSelected: currentIndex == 3,
                badge: unread > 0 ? unread : null,
                onTap: () => context.go(Routes.notifications),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Profile',
                isSelected: currentIndex == 4,
                onTap: () async {
                  final userId = await SecureStorage.getUserId();
                  if (userId != null && context.mounted) {
                    context.go(Routes.profilePath(userId));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final int? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textTertiary,
                ),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.like,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge! > 99 ? '99+' : badge.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
