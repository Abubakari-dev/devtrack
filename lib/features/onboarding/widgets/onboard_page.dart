import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart' as constants;
import '../../../core/constants/app_text_styles.dart';

class IllustrationItem {
  final String emoji;
  final String title;
  final String badge;
  final Color color;

  const IllustrationItem({
    required this.emoji,
    required this.title,
    required this.badge,
    required this.color,
  });
}

class OnboardSlide {
  final String emoji;
  final String title;
  final String subtitle;
  final List<IllustrationItem> illustrationData;

  const OnboardSlide({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.illustrationData,
  });
}

class OnboardPage extends StatefulWidget {
  final OnboardSlide slide;
  final bool isActive;

  const OnboardPage({
    super.key,
    required this.slide,
    required this.isActive,
  });

  @override
  State<OnboardPage> createState() => _OnboardPageState();
}

class _OnboardPageState extends State<OnboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.isActive) _ctrl.forward();
  }

  @override
  void didUpdateWidget(OnboardPage old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Illustration cards (Centered)
          Column(
            children: widget.slide.illustrationData.asMap().entries.map((e) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 400 + (e.key * 100)),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Transform.translate(
                  offset: Offset(0, 20 * (1 - v)),
                  child: Opacity(
                    opacity: v.clamp(0, 1),
                    child: _IllustrationCard(
                      item: e.value,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 48),

          // Big emoji (Centered)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            builder: (_, v, __) => Opacity(
              opacity: v.clamp(0, 1),
              child: Text(
                widget.slide.emoji,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 56),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title (Centered)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Opacity(
              opacity: v.clamp(0, 1),
              child: Text(
                widget.slide.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.display(context).copyWith(
                  fontSize: 32,
                  color: constants.AppColors.textPrimary,
                  letterSpacing: -1.0,
                  height: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle (Centered)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            builder: (_, v, __) => Opacity(
              opacity: v.clamp(0, 1),
              child: Text(
                widget.slide.subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(context).copyWith(
                  color: constants.AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IllustrationCard extends StatelessWidget {
  final IllustrationItem item;

  const _IllustrationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: constants.AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: constants.AppColors.border),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.title,
              style: AppTextStyles.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w600,
                color: constants.AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.badge,
              style: AppTextStyles.mono(context).copyWith(
                fontSize: 9,
                color: item.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
