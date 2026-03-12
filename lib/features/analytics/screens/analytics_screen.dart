import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../projects/data/project_repository.dart';
import '../../projects/models/project_model.dart';
import '../../finance/data/finance_repository.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with TickerProviderStateMixin {
  final ProjectRepository _projectRepo = ProjectRepository();
  final FinanceRepository _financeRepo = FinanceRepository();
  
  int _periodIndex = 0; // 0: Week, 1: Month, 2: Year
  final _periods = ['WEEK', 'MONTH', 'YEAR'];
  late AnimationController _chartCtrl;

  @override
  void initState() {
    super.initState();
    _chartCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _chartCtrl.forward();
  }

  @override
  void dispose() {
    _chartCtrl.dispose();
    super.dispose();
  }

  double _calculateScore(List<Project> projects) {
    if (projects.isEmpty) return 0;
    final completed = projects.where((p) => p.status == ProjectStatus.completed).length;
    final onTime = projects.where((p) => p.status != ProjectStatus.overdue).length;
    final avgProgress = projects.fold(0.0, (sum, p) => sum + p.progressPercent) / projects.length;
    return ((completed / projects.length) * 40) + ((onTime / projects.length) * 40) + (avgProgress * 20);
  }

  List<AnalyticsChartData> _generateChartData(List<Project> projects) {
    final now = DateTime.now();
    final List<AnalyticsChartData> data = [];
    switch (_periodIndex) {
      case 0: // Week
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final count = projects.where((p) => p.createdAt.year == date.year && p.createdAt.month == date.month && p.createdAt.day == date.day).length;
          data.add(AnalyticsChartData(DateFormat('E').format(date)[0], count.toDouble()));
        }
        break;
      case 1: // Month
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        for (int i = 1; i <= daysInMonth; i++) {
          final count = projects.where((p) => p.createdAt.year == now.year && p.createdAt.month == now.month && p.createdAt.day == i).length;
          data.add(AnalyticsChartData(i % 5 == 1 || i == 1 ? '$i' : '', count.toDouble()));
        }
        break;
      case 2: // Year
        for (int i = 0; i < 12; i++) {
          final month = i + 1;
          final count = projects.where((p) => p.createdAt.year == now.year && p.createdAt.month == month).length;
          data.add(AnalyticsChartData(['J','F','M','A','M','J','J','A','S','O','N','D'][i], count.toDouble()));
        }
        break;
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.bg,
      body: StreamBuilder<List<Project>>(
        stream: _projectRepo.getProjectsStream(),
        builder: (context, projectSnapshot) {
          final projects = projectSnapshot.data ?? [];
          final score = _calculateScore(projects);
          final chartData = _generateChartData(projects);

          return StreamBuilder<List<Payment>>(
            stream: _financeRepo.getAllPayments(),
            builder: (context, paymentSnapshot) {
              final allPayments = paymentSnapshot.data ?? [];
              final totalRevenue = projects.fold(0.0, (sum, p) => sum + p.totalPrice);
              final totalPaid = allPayments.fold(0.0, (sum, pay) => sum + pay.amount);
              
              double totalRemaining = 0.0;
              double totalOverdue = 0.0;
              final now = DateTime.now();
              for (var project in projects) {
                final projectPaid = allPayments.where((p) => p.projectId == project.id).fold(0.0, (sum, pay) => sum + pay.amount);
                final projectRemaining = project.totalPrice - projectPaid;
                totalRemaining += projectRemaining;
                if (project.endDate.isBefore(now) && projectRemaining > 0 && project.status != ProjectStatus.completed) {
                  totalOverdue += projectRemaining;
                }
              }

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildHeader(context, isDark),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildPeriodSelector(isDark),
                          const SizedBox(height: 24),
                          _buildScoreSection(score, isDark),
                          const SizedBox(height: 32),
                          _buildSectionTitle('PROJECT VELOCITY', isDark),
                          const SizedBox(height: 16),
                          _buildMainChart(chartData, AppColors.indigo, isDark),
                          const SizedBox(height: 32),
                          _buildSectionTitle('OPERATIONAL SUMMARY', isDark),
                          const SizedBox(height: 16),
                          _buildSummaryGrid(projects, isDark),
                          const SizedBox(height: 32),
                          _buildSectionTitle('REVENUE ANALYTICS', isDark),
                          const SizedBox(height: 16),
                          _buildFinancialStack(totalRevenue, totalPaid, totalRemaining, totalOverdue, isDark),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
        title: Text(
          'Analytics Engine',
          style: AppTextStyles.h2(context).copyWith(
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
              right: -20,
              top: -20,
              child: Opacity(
                opacity: 0.15,
                child: const Icon(Icons.insights_rounded, size: 200, color: Colors.white),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.4)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: _periods.asMap().entries.map((e) {
          final isSelected = e.key == _periodIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _periodIndex = e.key;
                  _chartCtrl.reset();
                  _chartCtrl.forward();
                });
              },
              child: AnimatedContainer(
                duration: 250.ms,
                decoration: BoxDecoration(
                  color: isSelected ? (isDark ? Colors.white : AppColors.textPrimary) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  e.value,
                  style: TextStyle(
                    color: isSelected ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white38 : AppColors.textSecondary),
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScoreSection(double score, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: CircularProgressIndicator(
                  value: (score / 100) * _chartCtrl.value,
                  strokeWidth: 10,
                  strokeCap: StrokeCap.round,
                  backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                  valueColor: const AlwaysStoppedAnimation(AppColors.indigo),
                ),
              ),
              Text('${score.round()}%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PRODUCTIVITY SCORE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
                const SizedBox(height: 6),
                Text(
                  score >= 80 ? 'Exceptional Phase' : score >= 60 ? 'Consistent Growth' : 'Developing Speed',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.4),
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on project completion and milestone velocity.',
                  style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(List<Project> projects, bool isDark) {
    final completed = projects.where((p) => p.status == ProjectStatus.completed).length;
    final active = projects.where((p) => p.status == ProjectStatus.active).length;
    final onHold = projects.where((p) => p.status == ProjectStatus.onHold).length;
    final overdue = projects.where((p) => p.status == ProjectStatus.overdue).length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _MetricTile(label: 'COMPLETED', val: '$completed', color: AppColors.emerald, isDark: isDark),
        _MetricTile(label: 'ACTIVE', val: '$active', color: AppColors.indigo, isDark: isDark),
        _MetricTile(label: 'OVERDUE', val: '$overdue', color: AppColors.rose, isDark: isDark),
        _MetricTile(label: 'ON HOLD', val: '$onHold', color: AppColors.amber, isDark: isDark),
      ],
    );
  }

  Widget _buildMainChart(List<AnalyticsChartData> data, Color color, bool isDark) {
    return Container(
      height: 260,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 32, 24, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
      ),
      child: AnimatedBuilder(
        animation: _chartCtrl,
        builder: (context, child) => CustomPaint(
          size: Size.infinite,
          painter: _AnalyticsHistogramPainter(data: data, progress: _chartCtrl.value, color: color, isDark: isDark),
        ),
      ),
    );
  }

  Widget _buildFinancialStack(double revenue, double paid, double remaining, double overdue, bool isDark) {
    return Column(
      children: [
        _FinanceCard(label: 'Contract Total', value: revenue, icon: Icons.account_balance_rounded, color: AppColors.indigo, isDark: isDark),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _FinanceCard(label: 'Collected', value: paid, icon: Icons.check_circle_rounded, color: AppColors.emerald, isDark: isDark, compact: true)),
            const SizedBox(width: 12),
            Expanded(child: _FinanceCard(label: 'Pending', value: remaining, icon: Icons.hourglass_bottom_rounded, color: AppColors.amber, isDark: isDark, compact: true)),
          ],
        ),
        if (overdue > 0) ...[
          const SizedBox(height: 12),
          _FinanceCard(label: 'Overdue Payments', value: overdue, icon: Icons.warning_amber_rounded, color: AppColors.rose, isDark: isDark),
        ]
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        color: isDark ? Colors.white38 : AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }
}

class AnalyticsChartData {
  final String label;
  final double value;
  AnalyticsChartData(this.label, this.value);
}

class _MetricTile extends StatelessWidget {
  final String label, val;
  final Color color;
  final bool isDark;
  const _MetricTile({required this.label, required this.val, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -1)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _FinanceCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool compact;
  const _FinanceCard({required this.label, required this.value, required this.icon, required this.color, required this.isDark, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: compact ? 18 : 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TSh ${NumberFormat.compact().format(value)}', 
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: compact ? 16 : 20, letterSpacing: -0.5)
                ),
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsHistogramPainter extends CustomPainter {
  final List<AnalyticsChartData> data;
  final double progress;
  final Color color;
  final bool isDark;
  _AnalyticsHistogramPainter({required this.data, required this.progress, required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = data.map((e) => e.value).reduce(math.max).clamp(1.0, double.infinity);
    final chartH = size.height - 40;
    final chartW = size.width;
    final count = data.length;
    final barW = (chartW / count) * 0.45;
    final space = (chartW / count) * 0.55;

    // Grid
    final gPaint = Paint()..color = (isDark ? Colors.white : Colors.black).withOpacity(0.04)..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = chartH - (chartH / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(chartW, y), gPaint);
    }

    final path = Path();
    for (int i = 0; i < count; i++) {
      final x = (space / 2) + i * (barW + space) + barW / 2;
      final normV = (data[i].value / maxVal) * progress;
      final y = chartH - (chartH * normV);

      // Bars
      final barRect = RRect.fromRectAndRadius(Rect.fromLTWH(x - barW / 2, y, barW, chartH - y), const Radius.circular(6));
      final barGrad = ui.Gradient.linear(Offset(x, y), Offset(x, chartH), [color.withOpacity(0.7), color.withOpacity(0.2)]);
      canvas.drawRRect(barRect, Paint()..shader = barGrad);
      
      // Top Cap Blur
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - barW / 2, y, barW, 4), const Radius.circular(6)), Paint()..color = color.withOpacity(0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

      // Path for Progress Line
      if (i == 0) path.moveTo(x, y);
      else {
        final prevX = (space / 2) + (i - 1) * (barW + space) + barW / 2;
        final prevY = chartH - (chartH * (data[i - 1].value / maxVal) * progress);
        path.cubicTo(prevX + (x - prevX) / 2, prevY, prevX + (x - prevX) / 2, y, x, y);
      }

      // Label
      if (data[i].label.isNotEmpty) {
        final tp = TextPainter(text: TextSpan(text: data[i].label, style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.w900)), textDirection: ui.TextDirection.ltr)..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, chartH + 12));
      }
    }

    // Line Glow
    canvas.drawPath(path, Paint()..color = color.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 6..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    // Main Line
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round);

    // Points
    for (int i = 0; i < count; i++) {
      final x = (space / 2) + i * (barW + space) + barW / 2;
      final y = chartH - (chartH * (data[i].value / maxVal) * progress);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = Colors.white);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
