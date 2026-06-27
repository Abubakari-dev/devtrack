import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class DevCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double borderRadius;
  final double? height;
  final double? width;
  final bool showBorder;
  final bool useHaptic;

  const DevCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.borderRadius = 24,
    this.height,
    this.width,
    this.showBorder = true,
    this.useHaptic = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final cardContent = Container(
      padding: padding ?? const EdgeInsets.all(20),
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color ?? (isDark ? const Color(0xFF161B22) : Colors.white),
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder 
          ? Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withValues(alpha: 0.5))
          : null,
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) {
      return Container(
        margin: margin,
        child: cardContent,
      );
    }

    return Container(
      margin: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (useHaptic) HapticFeedback.lightImpact();
            onTap!();
          },
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardContent,
        ),
      ),
    );
  }
}

class DevSectionHeader extends StatelessWidget {
  final String title;
  final String? overline;
  final Widget? trailing;

  const DevSectionHeader({
    super.key,
    required this.title,
    this.overline,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (overline != null)
          Text(
            overline!.toUpperCase(),
            style: TextStyle(
              color: AppColors.emerald,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  fontSize: 20,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ],
    );
  }
}
