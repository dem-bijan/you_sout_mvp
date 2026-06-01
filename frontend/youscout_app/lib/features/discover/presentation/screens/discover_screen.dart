import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Stub discover/search screen.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Search bar ─────────────────────────────────────────
            Container(
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
                        hintStyle:
                            TextStyle(color: AppColors.textTertiary, fontSize: 14),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Placeholder
            const Icon(Icons.explore_outlined,
                color: AppColors.textTertiary, size: 56),
            const SizedBox(height: 12),
            const Text(
              'Coming soon',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Search by skill, hashtag, or username',
              style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
