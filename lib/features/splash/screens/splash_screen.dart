import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onFinished;
  const SplashScreen({super.key, this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _setupSystemUI();
    _setupAnimations();
    _startAnimationFlow();
  }

  void _setupSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  void _setupAnimations() {
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  Future<void> _startAnimationFlow() async {
    // Simulate loading progress
    for (int i = 0; i <= 100; i += 2) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 30));
      setState(() => _progress = i / 100);
    }

    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;

    if (widget.onFinished != null) {
      widget.onFinished!();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox.expand(
          child: Stack(
            children: [
              // Animated background particles
              ...List.generate(20, (index) => _buildFloatingParticle(index)),

              // Rotating gradient circles
              Center(
                child: AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationController.value * 2 * math.pi,
                      child: Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.indigo.withOpacity(0.1),
                              AppColors.blue.withOpacity(0.05),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glowing container for logo
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.indigo.withOpacity(0.1 + _pulseController.value * 0.1),
                                blurRadius: 40 + _pulseController.value * 20,
                                spreadRadius: 10 + _pulseController.value * 10,
                              ),
                              BoxShadow(
                                color: AppColors.blue.withOpacity(0.05 + _pulseController.value * 0.05),
                                blurRadius: 60 + _pulseController.value * 30,
                                spreadRadius: 15 + _pulseController.value * 15,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 200,
                        height: 200,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.indigo.withOpacity(0.05),
                              AppColors.blue.withOpacity(0.02),
                            ],
                          ),
                          border: Border.all(
                            color: AppColors.indigo.withOpacity(0.1),
                            width: 2,
                          ),
                        ),
                        child: Image.asset(
                          'lib/features/img/Devtrack.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ).animate()
                      .fadeIn(duration: 800.ms)
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1.0, 1.0),
                        curve: Curves.easeOutBack,
                        duration: 1000.ms,
                      ),

                    const SizedBox(height: 60),

                    // App name with gradient
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          AppColors.indigo,
                          AppColors.blue,
                          Color(0xFF60A5FA),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'DEVTRACK',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: AppColors.indigo.withOpacity(0.2),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    ).animate()
                      .fadeIn(delay: 400.ms, duration: 800.ms)
                      .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 16),

                    Text(
                      'OS FOR MODERN DEVELOPERS',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 6,
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontWeight: FontWeight.w700,
                      ),
                    ).animate()
                      .fadeIn(delay: 800.ms, duration: 800.ms)
                      .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 80),

                    // Progress bar
                    _buildProgressBar(),
                  ],
                ),
              ),

              // Bottom info
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.emerald,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.emerald.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ).animate(onPlay: (controller) => controller.repeat())
                          .fadeIn(duration: 1000.ms)
                          .then()
                          .fadeOut(duration: 1000.ms),
                        const SizedBox(width: 12),
                        Text(
                          'INITIALIZING SYSTEM',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 4,
                            color: AppColors.textSecondary.withOpacity(0.6),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.indigo.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.indigo.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: AppColors.indigo.withOpacity(0.8),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'v1.0.0 PRO',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary.withOpacity(0.8),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animate()
                  .fadeIn(delay: 1200.ms, duration: 800.ms)
                  .slideY(begin: 0.3, end: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = math.Random(index);
    final size = 2.0 + random.nextDouble() * 4;
    final left = random.nextDouble() * MediaQuery.of(context).size.width;
    final top = random.nextDouble() * MediaQuery.of(context).size.height;
    final duration = 3000 + random.nextInt(4000);

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.blue.withOpacity(0.1),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.blue.withOpacity(0.05),
              blurRadius: 4,
            ),
          ],
        ),
      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fadeIn(duration: duration.ms)
        .then()
        .fadeOut(duration: duration.ms)
        .animate(onPlay: (controller) => controller.repeat())
        .moveY(
          begin: 0,
          end: -50 - random.nextDouble() * 50,
          duration: (duration * 2).ms,
        ),
    );
  }

  Widget _buildProgressBar() {
    return SizedBox(
      width: 280,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                width: 280 * _progress,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.indigo,
                      AppColors.blue,
                      Color(0xFF60A5FA),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${(_progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary.withOpacity(0.8),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatusIndicator('BOOT', _progress > 0.3),
              _buildStatusIndicator('SYNC', _progress > 0.6),
              _buildStatusIndicator('READY', _progress > 0.9),
            ],
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: 1000.ms, duration: 800.ms)
      .slideY(begin: 0.2, end: 0);
  }

  Widget _buildStatusIndicator(String label, bool active) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.emerald : AppColors.textMuted.withOpacity(0.2),
            shape: BoxShape.circle,
            boxShadow: active ? [
              BoxShadow(
                color: AppColors.emerald.withOpacity(0.5),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ] : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: active 
                ? AppColors.textPrimary.withOpacity(0.9) 
                : AppColors.textMuted.withOpacity(0.5),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
