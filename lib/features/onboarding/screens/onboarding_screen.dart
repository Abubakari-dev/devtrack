import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/screens/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  late AnimationController _floatCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _floatAnim;

  final List<OnboardPageData> _pages = const [
    OnboardPageData(
      accentColor: AppColors.indigo,
      icon: '📊',
      emoji1: '📋', emoji2: '✅', emoji3: '🚀',
      title: 'Track Everything',
      subtitle: 'From idea to delivery',
      description:
          'Manage projects across 4 levels — Projects, Phases, Tasks and Subtasks. Every detail is tracked automatically.',
    ),
    OnboardPageData(
      accentColor: AppColors.amber,
      icon: '💰',
      emoji1: '💵', emoji2: '📈', emoji3: '🧾',
      title: 'Control Your Money',
      subtitle: 'Every dollar accounted for',
      description:
          'Track project prices, advance payments, remaining balances and expenses. Know your net profit at a glance.',
    ),
    OnboardPageData(
      accentColor: AppColors.emerald,
      icon: '📊',
      emoji1: '📅', emoji2: '📉', emoji3: '🎯',
      title: 'Analyze & Grow',
      subtitle: 'Data-driven decisions',
      description:
          'Weekly, monthly and annual analytics reveal your performance trends and help you grow your business.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _floatAnim = Tween<double>(begin: 0, end: 12).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _particleCtrl.dispose();
    _slideCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _slideCtrl.reset();
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOutCubic);
      _slideCtrl.forward();
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const LoginScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Subtle glow orb (lightened for white background)
          Positioned(
            top: -80, left: MediaQuery.of(context).size.width / 2 - 140,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [page.accentColor.withOpacity(0.1), Colors.transparent],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Centered Logo
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          gradient: AppColors.indigoGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(child: Text('P', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
                      ),
                      const SizedBox(width: 8),
                      Text('ProTrack', style: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
                    ],
                  ),
                ),

                // PageView content
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _pages.length,
                    itemBuilder: (_, i) => _buildPage(_pages[i]),
                  ),
                ),

                // Bottom controls
                _buildBottomControls(page),
                const SizedBox(height: 24),
              ],
            ),
          ),
          
          // Skip button top right
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: TextButton(
              onPressed: _goToLogin,
              child: Text('Skip', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardPageData page) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Floating illustration
            AnimatedBuilder(
              animation: _floatAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, -_floatAnim.value),
                child: child,
              ),
              child: _buildIllustration(page),
            ),

            const SizedBox(height: 48),

            // Slide-in text
            SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
                  .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic)),
              child: FadeTransition(
                opacity: CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut),
                child: Column(
                  children: [
                    // Subtitle pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: page.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: page.accentColor.withOpacity(0.2)),
                      ),
                      child: Text(page.subtitle, style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: page.accentColor, letterSpacing: 0.3,
                      )),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(page.title, textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 32, fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary, letterSpacing: -0.8,
                        height: 1.15,
                      )),
                    const SizedBox(height: 16),

                    // Description
                    Text(page.description, textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 15, color: AppColors.textSecondary,
                        height: 1.6, fontWeight: FontWeight.w400,
                      )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(OnboardPageData page) {
    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 180, height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                page.accentColor.withOpacity(0.1),
                Colors.transparent,
              ]),
            ),
          ),
          // Middle ring
          Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: page.accentColor.withOpacity(0.1), width: 1.5),
              color: page.accentColor.withOpacity(0.02),
            ),
          ),
          // Center icon
          Container(
            width: 100, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: page.accentColor.withOpacity(0.15), blurRadius: 30, spreadRadius: 5),
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: Center(child: Text(page.icon, style: const TextStyle(fontSize: 42))),
          ),
          // Orbiting emoji 1
          _buildOrbitEmoji(page.emoji1, 110, 0, page.accentColor),
          // Orbiting emoji 2
          _buildOrbitEmoji(page.emoji2, 110, 2.09, page.accentColor),
          // Orbiting emoji 3
          _buildOrbitEmoji(page.emoji3, 110, 4.19, page.accentColor),
        ],
      ),
    );
  }

  Widget _buildOrbitEmoji(String emoji, double radius, double offset, Color accent) {
    return AnimatedBuilder(
      animation: _particleCtrl,
      builder: (_, __) {
        final angle = (_particleCtrl.value * 2 * pi) + offset;
        return Transform.translate(
          offset: Offset(cos(angle) * radius * 0.65, sin(angle) * radius * 0.5),
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: accent.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(color: accent.withOpacity(0.1), blurRadius: 10),
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2)),
              ],
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
          ),
        );
      },
    );
  }

  Widget _buildBottomControls(OnboardPageData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) =>
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _currentPage ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _currentPage ? page.accentColor : AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              )
            ),
          ),
          const SizedBox(height: 32),

          // Next / Get Started
          GestureDetector(
            onTap: _nextPage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                color: page.accentColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: page.accentColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentPage == _pages.length - 1 ? "Get Started" : "Continue",
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _currentPage == _pages.length - 1 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                    color: Colors.white, size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sign in link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Already have an account? ", style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
              GestureDetector(
                onTap: _goToLogin,
                child: Text("Sign In", style: GoogleFonts.poppins(
                  fontSize: 13, color: page.accentColor, fontWeight: FontWeight.w700,
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── DATA ─────────────────────────────────────────────────────────────────────
class OnboardPageData {
  final Color accentColor;
  final String icon, emoji1, emoji2, emoji3;
  final String title, subtitle, description;
  const OnboardPageData({
    required this.accentColor,
    required this.icon, required this.emoji1, required this.emoji2, required this.emoji3,
    required this.title, required this.subtitle, required this.description,
  });
}
