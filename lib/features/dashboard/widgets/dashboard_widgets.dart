import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/shared_widgets.dart';

/// Hero section for the dashboard home tab.
class DashboardHero extends StatelessWidget {
  final String greeting;
  final String subtitle;
  final String streakLabel;
  final int streakDays;

  const DashboardHero({
    super.key,
    required this.greeting,
    required this.subtitle,
    required this.streakLabel,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              greeting,
              style: AppTextStyles.titleLarge(context),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium(context).copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
        GlowContainer(
          glowColor: AppColors.amber,
          glowRadius: 18,
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          backgroundColor: AppColors.bg,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                '$streakDays',
                style: AppTextStyles.labelMono(context).copyWith(
                  color: AppColors.amber,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                streakLabel.toUpperCase(),
                style: AppTextStyles.labelMono(context).copyWith(
                  fontSize: 10,
                  color: AppColors.amber.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Small wrapper around [StatCard] with fixed padding for the dashboard grid.
class DashboardStatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const DashboardStatTile({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return StatCard(
      value: value,
      label: label,
      icon: icon,
      color: color,
    );
  }
}
