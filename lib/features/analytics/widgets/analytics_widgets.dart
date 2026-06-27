import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

// ─── CATEGORY BAR ─────────────────────────────────────────────────────────────
class CategoryBar extends StatelessWidget {
  final String label;
  final int percent;
  final Color color;

  const CategoryBar({
    super.key,
    required this.label,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppTextStyles.displayFont,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percent / 100,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$percent%',
          style: TextStyle(
            fontFamily: AppTextStyles.monoFont,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─── INSIGHT CARD ─────────────────────────────────────────────────────────────
class InsightCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String sub;
  final Color color;

  const InsightCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppTextStyles.displayFont,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
              fontFamily: AppTextStyles.monoFont,
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ANALYTICS LINE CHART ─────────────────────────────────────────────────────
class AnalyticsLineChart extends StatelessWidget {
  final List<double> scores;
  final double progress;

  const AnalyticsLineChart({
    super.key,
    required this.scores,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _LineChartPainter(scores: scores, progress: progress),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> scores;
  final double progress;

  _LineChartPainter({required this.scores, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final maxScore = scores.reduce(math.max);
    final minScore = scores.reduce(math.min) - 10;
    final range = maxScore - minScore;
    final drawn = (scores.length * progress).round().clamp(1, scores.length);
    final points = <Offset>[];

    for (int i = 0; i < drawn; i++) {
      final x = i / (scores.length - 1) * size.width;
      final y = size.height - ((scores[i] - minScore) / range * size.height * 0.9);
      points.add(Offset(x, y));
    }

    // Fill area
    final fillPath = Path();
    fillPath.moveTo(0, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.blue.withValues(alpha: 0.25),
          AppColors.blue.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = AppColors.blue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (points.length > 1) {
      final linePath = Path();
      linePath.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        final cp1 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i - 1].dy);
        final cp2 = Offset((points[i - 1].dx + points[i].dx) / 2, points[i].dy);
        linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i].dx, points[i].dy);
      }
      canvas.drawPath(linePath, linePaint);
    }

    // Peak dot
    if (points.length > 1) {
      double maxY = double.infinity;
      Offset? peakPt;
      int peakIdx = 0;
      for (int i = 0; i < points.length; i++) {
        if (points[i].dy < maxY) {
          maxY = points[i].dy;
          peakPt = points[i];
          peakIdx = i;
        }
      }
      if (peakPt != null) {
        final glowPaint = Paint()
          ..color = AppColors.amber.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(peakPt, 10, glowPaint);
        final dotPaint = Paint()
          ..color = AppColors.amber
          ..style = PaintingStyle.fill;
        canvas.drawCircle(peakPt, 5, dotPaint);

        final tp = TextPainter(
          text: TextSpan(
            text: '🔥 ${scores[peakIdx].round()}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: AppColors.amber,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(peakPt.dx - tp.width / 2, peakPt.dy - 24));
      }
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => old.progress != progress;
}
