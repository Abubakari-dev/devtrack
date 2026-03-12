import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Common header used on auth screens (welcome, login, signup).
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: AppTextStyles.displayFont,
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -2,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: AppTextStyles.displayFont,
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Small helper row for "Don't have an account? Sign up" style links.
class AuthInlineLink extends StatelessWidget {
  final String leading;
  final String action;
  final VoidCallback onTap;

  const AuthInlineLink({
    super.key,
    required this.leading,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: leading,
          style: const TextStyle(
            fontFamily: AppTextStyles.displayFont,
            fontSize: 14,
            color: AppColors.textMuted,
          ),
          children: [
            TextSpan(
              text: action,
              style: const TextStyle(
                color: AppColors.blue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
