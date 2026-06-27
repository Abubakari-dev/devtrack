import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingData> _getPages(BuildContext context) => [
    OnboardingData(
      title: context.tr('onboarding_track_missions'),
      subtitle: context.tr('onboarding_modular_roadmaps'),
      description: context.tr('onboarding_track_missions_desc'),
      icon: Icons.rocket_launch_rounded,
      color: AppColors.indigo,
    ),
    OnboardingData(
      title: context.tr('onboarding_finance_intelligence'),
      subtitle: context.tr('onboarding_cloud_synced'),
      description: context.tr('onboarding_finance_intelligence_desc'),
      icon: Icons.account_balance_wallet_rounded,
      color: AppColors.emerald,
    ),
    OnboardingData(
      title: context.tr('onboarding_secure_by_design'),
      subtitle: context.tr('onboarding_biometric_lock'),
      description: context.tr('onboarding_secure_by_design_desc'),
      icon: Icons.security_rounded,
      color: AppColors.purple,
    ),
  ];

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = _getPages(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              HapticFeedback.selectionClick();
            },
            itemBuilder: (context, index) {
              return _buildPage(pages[index], isDark);
            },
          ),

          // Top Header (Skip)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLogo(isDark),
                TextButton(
                  onPressed: _completeOnboarding,
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? Colors.white38 : AppColors.textMuted,
                  ),
                  child: Text(
                    context.tr('onboarding_skip'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 30,
            left: 30,
            right: 30,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                    (index) => _buildIndicator(index == _currentPage, pages[index].color),
                  ),
                ),
                const SizedBox(height: 40),
                _buildMainButton(context, isDark, pages),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.indigo,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.code_rounded, color: Colors.white, size: 20),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0);
  }

  Widget _buildPage(OnboardingData page, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Illustration Area
          Container(
            height: 280,
            width: double.infinity,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Ring
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: page.color.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat()).rotate(duration: 10.seconds),
                
                // Middle Glow
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: page.color.withValues(alpha: 0.2),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),

                // Icon Background
                Container(
                  padding: const EdgeInsets.all(45),
                  decoration: BoxDecoration(
                    color: page.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    page.icon,
                    size: 80,
                    color: page.color,
                  ),
                ).animate().scale(
                  duration: 800.ms,
                  curve: Curves.elasticOut,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 60),
          
          // Subtitle (Overline style)
          Text(
            page.subtitle.toUpperCase(),
            style: TextStyle(
              color: page.color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 3,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5, end: 0),
          
          const SizedBox(height: 12),
          
          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.h1.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
              height: 1.6,
              fontSize: 16,
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive, Color color) {
    return AnimatedContainer(
      duration: 400.ms,
      curve: Curves.easeOutQuint,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 6,
      width: isActive ? 28 : 6,
      decoration: BoxDecoration(
        color: isActive ? color : color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildMainButton(BuildContext context, bool isDark, List<OnboardingData> pages) {
    final isLastPage = _currentPage == pages.length - 1;
    final color = pages[_currentPage].color;

    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (isLastPage) {
            _completeOnboarding();
          } else {
            _pageController.nextPage(
              duration: 800.ms,
              curve: Curves.easeOutQuint,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLastPage ? context.tr('onboarding_get_started') : context.tr('onboarding_continue'),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isLastPage ? Icons.arrow_forward_rounded : Icons.chevron_right_rounded,
              size: 20,
            ),
          ],
        ),
      ),
    ).animate(target: isLastPage ? 1 : 0).shimmer(delay: 2.seconds, duration: 2.seconds);
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}
