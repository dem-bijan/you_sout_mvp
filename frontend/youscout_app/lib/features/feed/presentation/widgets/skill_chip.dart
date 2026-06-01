import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/video_model.dart';

/// Pill-shaped chip displaying a football skill tag.
class SkillChip extends StatelessWidget {
  final SkillModel skill;

  const SkillChip({super.key, required this.skill});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: Text(
        skill.name,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.secondary,
        ),
      ),
    );
  }
}
