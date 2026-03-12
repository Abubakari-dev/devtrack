import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/constants/app_colors.dart';

/// The advanced animated logo used in the splash screen.
class SplashAnimatedLogo extends StatefulWidget {
  final double size;
  const SplashAnimatedLogo({super.key, this.size = 120});

  @override
  State<SplashAnimatedLogo> createState() => _SplashAnimatedLogoState();
}

class _SplashAnimatedLogoState extends State<SplashAnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _LogoPainter(progress: _controller.value),
          ),
        );
      },
    );
  }
}

class _LogoPainter extends CustomPainter {
  final double progress;
  _LogoPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background Glow
    final glowPaint = Paint()
      ..color = AppColors.blue.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, radius * 0.8, glowPaint);

    // Main Outer Hexagon
    final outerPaint = Paint()
      ..shader = AppColors.indigoGradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final outerPath = _getHexPath(center, radius * 0.7, rotation: progress * math.pi * 0.5);
    canvas.drawPath(outerPath, outerPaint);

    // Inner Hexagon (Opposite rotation)
    final innerPaint = Paint()
      ..color = AppColors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final innerPath = _getHexPath(center, radius * 0.4, rotation: -progress * math.pi);
    canvas.drawPath(innerPath, innerPaint);

    // Orbiting "Nodes"
    final nodePaint = Paint()..color = AppColors.blue;
    for (int i = 0; i < 3; i++) {
      final angle = (progress * 2 * math.pi) + (i * 2 * math.pi / 3);
      final nodePos = Offset(
        center.dx + math.cos(angle) * (radius * 0.55),
        center.dy + math.sin(angle) * (radius * 0.55),
      );
      
      // Node glow
      canvas.drawCircle(
        nodePos, 
        6, 
        Paint()..color = AppColors.blue.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(nodePos, 3, nodePaint);
    }

    // Center "Processor" Core
    final corePaint = Paint()
      ..color = AppColors.blue
      ..style = PaintingStyle.fill;
    
    // Core pulse animation
    final corePulse = (math.sin(progress * 2 * math.pi * 2) + 1) / 2;
    canvas.drawCircle(center, 8 + (corePulse * 4), Paint()..color = AppColors.blue.withOpacity(0.2 * corePulse));
    canvas.drawCircle(center, 6, corePaint);
  }

  Path _getHexPath(Offset center, double radius, {double rotation = 0}) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = rotation + (i * 60 * math.pi / 180);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) => oldDelegate.progress != progress;
}

/// A background grid painter for the splash screen background.
class SplashGridPainter extends CustomPainter {
  const SplashGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withOpacity(0.15)
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
