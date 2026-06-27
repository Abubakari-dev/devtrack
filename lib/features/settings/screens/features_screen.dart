import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/dev_card.dart';

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context, isDark),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader(context, context.tr('financial_tools'), isDark),
                const SizedBox(height: 16),
                ...[
                  _FeatureItemData(
                    title: context.tr('wallets'),
                    subtitle: 'Manage bank & mobile accounts',
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppColors.indigo,
                    onTap: () => context.push('/wallets'),
                  ),
                  _FeatureItemData(
                    title: context.tr('debts'),
                    subtitle: 'Track money lent & borrowed',
                    icon: Icons.people_alt_rounded,
                    color: AppColors.rose,
                    onTap: () => context.push('/debts'),
                  ),
                  _FeatureItemData(
                    title: context.tr('budgets'),
                    subtitle: 'Set spending limits & goals',
                    icon: Icons.pie_chart_rounded,
                    color: AppColors.amber,
                    onTap: () => context.push('/budgets'),
                  ),
                  _FeatureItemData(
                    title: context.tr('expenses_label'),
                    subtitle: 'Track project costs & materials',
                    icon: Icons.receipt_long_rounded,
                    color: AppColors.orange,
                    onTap: () => context.push('/expenses'),
                  ),
                  _FeatureItemData(
                    title: context.tr('transactions'),
                    subtitle: 'View all income & expenses',
                    icon: Icons.history_rounded,
                    color: AppColors.emerald,
                    onTap: () => context.push('/transactions'),
                  ),
                ].map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FeatureCard(item: item, isDark: isDark),
                )),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 56, bottom: 20),
        title: Text(
          context.tr('app_features'),
          style: AppTextStyles.h2.copyWith(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -30,
              top: -30,
              child: Opacity(
                opacity: 0.1,
                child: Transform.rotate(
                  angle: -0.2,
                  child: const Icon(Icons.stars_rounded, size: 200, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: Opacity(
                opacity: 0.15,
                child: const Icon(Icons.grid_view_rounded, size: 80, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: isDark ? Colors.white38 : AppColors.textMuted,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ).animate().fadeIn(duration: 400.ms),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _FeatureItemData item;
  final bool isDark;

  const _FeatureCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return DevCard(
      onTap: () {
        HapticFeedback.lightImpact();
        item.onTap();
      },
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(item.icon, color: item.color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemTitle, 
                  style: AppTextStyles.semiBold.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  )
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle, 
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? Colors.white38 : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  )
                ),
              ],
            )
          ),
          Icon(Icons.chevron_right_rounded, 
            size: 20,
            color: isDark ? Colors.white10 : Colors.grey[300],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }
}

class _FeatureItemData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _FeatureItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  String get itemTitle => title;
}
