import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../projects/data/project_repository.dart';
import '../../projects/models/models.dart';
import '../../finance/data/finance_repository.dart';
import '../../finance/providers/finance_providers.dart';
import '../../../core/database/app_database.dart';

import '../../../core/localization/app_localizations.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> with TickerProviderStateMixin {
  final ProjectRepository _projectRepo = ProjectRepository();
  
  int _periodIndex = 0; // 0: Week, 1: Month, 2: Year
  List<String> _getPeriods(BuildContext context) => [
    context.tr('week').toUpperCase(), 
    context.tr('month').toUpperCase(), 
    context.tr('year').toUpperCase()
  ];
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

  List<AnalyticsChartData> _generateChartData(List<Project> projects, BuildContext context) {
    final now = DateTime.now();
    final List<AnalyticsChartData> data = [];
    final locale = Localizations.localeOf(context).toString();
    switch (_periodIndex) {
      case 0: // Week
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final count = projects.where((p) => p.createdAt.year == date.year && p.createdAt.month == date.month && p.createdAt.day == date.day).length;
          data.add(AnalyticsChartData(DateFormat('E', locale).format(date)[0], count.toDouble()));
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
          final monthLabel = DateFormat('MMM', locale).format(DateTime(now.year, month, 1))[0];
          data.add(AnalyticsChartData(monthLabel, count.toDouble()));
        }
        break;
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletsAsync = ref.watch(walletsStreamProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.bg,
      body: StreamBuilder<List<Project>>(
        stream: _projectRepo.getProjectsStream(),
        builder: (context, projectSnapshot) {
          final projects = projectSnapshot.data ?? [];
          final score = _calculateScore(projects);
          final chartData = _generateChartData(projects, context);

          return Consumer(
            builder: (context, ref, child) {
              final globalSummaryAsync = ref.watch(globalFinancialSummaryProvider);
              final filteredFinanceAsync = ref.watch(filteredFinanceDataProvider);
              
              return globalSummaryAsync.when(
                data: (summary) => filteredFinanceAsync.when(
                  data: (filteredData) => CustomScrollView(
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
                              _buildPeriodSelector(context, isDark),
                              const SizedBox(height: 24),
                              _buildScoreSection(context, score, isDark),
                              const SizedBox(height: 32),
                              _buildSectionTitle(context.tr('project_velocity'), isDark),
                              const SizedBox(height: 16),
                              _buildMainChart(chartData, AppColors.indigo, isDark),
                              
                              const SizedBox(height: 32),
                              _buildSectionTitle(context.tr('operational_pulse'), isDark),
                              const SizedBox(height: 16),
                              _buildCompactSummaryGrid(context, projects, isDark),

                              const SizedBox(height: 32),
                              _buildSectionTitle(context.tr('wallet_distribution'), isDark),
                              const SizedBox(height: 16),
                              walletsAsync.when(
                                data: (wallets) => _buildWalletAnalytics(context, wallets, isDark),
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (e, _) => Text('Error loading wallets: $e'),
                              ),

                              const SizedBox(height: 32),
                              _buildSectionTitle(context.tr('risk_detection'), isDark),
                              const SizedBox(height: 16),
                              _buildRiskAnalytics(context, projects, filteredData.allPayments, isDark),

                              const SizedBox(height: 32),
                              _buildSectionTitle(context.tr('revenue_analytics'), isDark),
                              const SizedBox(height: 16),
                              _buildFinancialPulse(
                                context: context,
                                summary: summary,
                                filteredData: filteredData,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFinancialPulse({
    required BuildContext context,
    required Map<String, double> summary,
    required FilteredFinanceData filteredData,
    required bool isDark,
  }) {
    return Column(
      children: [
        _FinanceCard(
          label: context.tr('total_revenue'),
          value: summary['totalRevenue']!,
          icon: Icons.account_balance_rounded,
          color: AppColors.indigo,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _FinanceCard(label: context.tr('collected'), value: filteredData.totalCollected, icon: Icons.check_circle_rounded, color: AppColors.emerald, isDark: isDark, compact: true)),
            const SizedBox(width: 12),
            Expanded(child: _FinanceCard(label: context.tr('pending_label'), value: filteredData.pendingRevenue, icon: Icons.hourglass_bottom_rounded, color: AppColors.amber, isDark: isDark, compact: true)),
          ],
        ),
        const SizedBox(height: 12),
        _FinanceCard(
          label: context.tr('operating_profit'),
          value: summary['operatingProfit']!,
          icon: Icons.trending_up_rounded,
          color: AppColors.emerald,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildWalletAnalytics(BuildContext context, List<Wallet> wallets, bool isDark) {
    if (wallets.isEmpty) return _buildEmptyMetric(isDark, context.tr('no_wallets_found'));
    
    final totalBalance = wallets.fold(0, (sum, w) => sum + w.balance);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('total_liquidity'), style: AppTextStyles.semiBold.copyWith(fontSize: 10, color: Colors.grey, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text('TSh ${NumberFormat('#,###').format(totalBalance)}', style: AppTextStyles.bold.copyWith(fontSize: 22)),
                ],
              ),
              const Icon(Icons.account_balance_wallet_rounded, color: AppColors.indigo, size: 32),
            ],
          ),
          const SizedBox(height: 24),
          ...wallets.take(3).map((w) {
            final percent = totalBalance > 0 ? w.balance / totalBalance : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(w.name, style: AppTextStyles.semiBold.copyWith(fontSize: 13)),
                      Text('TSh ${NumberFormat.compact().format(w.balance)}', style: AppTextStyles.bold.copyWith(fontSize: 13, color: Color(w.color))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation(Color(w.color)),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRiskAnalytics(BuildContext context, List<Project> projects, List<Payment> allPayments, bool isDark) {
    final now = DateTime.now();
    
    final atRiskProjects = projects.where((p) {
      if (p.status == ProjectStatus.completed) return false;
      final daysRemaining = p.endDate.difference(now).inDays;
      final progress = p.progressPercent;
      if (daysRemaining < 7 && progress < 0.8) return true;
      if (p.endDate.isBefore(now)) return true;
      return false;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: atRiskProjects.isNotEmpty ? AppColors.rose.withOpacity(0.3) : (isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: atRiskProjects.isNotEmpty ? AppColors.rose.withOpacity(0.1) : AppColors.emerald.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  atRiskProjects.isNotEmpty ? Icons.warning_amber_rounded : Icons.shield_outlined,
                  color: atRiskProjects.isNotEmpty ? AppColors.rose : AppColors.emerald,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                atRiskProjects.isNotEmpty ? '${atRiskProjects.length} ${context.tr('projects_at_risk')}' : context.tr('system_secure'),
                style: AppTextStyles.bold.copyWith(
                  fontSize: 12,
                  color: atRiskProjects.isNotEmpty ? AppColors.rose : AppColors.emerald,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (atRiskProjects.isEmpty)
            Text(
              context.tr('no_risks'),
              style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.5),
            )
          else
            ...atRiskProjects.take(2).map((p) {
              final days = p.endDate.difference(now).inDays;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(width: 4, height: 32, decoration: BoxDecoration(color: AppColors.rose, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: AppTextStyles.semiBold.copyWith(fontSize: 13)),
                          Text(
                            days < 0 
                              ? context.tr('overdue_by').replaceFirst('{days}', days.abs().toString()) 
                              : context.tr('days_left').replaceFirst('{days}', days.toString()).replaceFirst('{progress}', (p.progressPercent*100).toInt().toString()),
                            style: TextStyle(color: AppColors.rose, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyMetric(bool isDark, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Center(child: Text(message, style: const TextStyle(color: Colors.grey))),
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
          context.tr('analytics_engine'),
          style: AppTextStyles.h2.copyWith(
            color: Colors.white,
            fontSize: 22,
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

  Widget _buildPeriodSelector(BuildContext context, bool isDark) {
    final periods = _getPeriods(context);
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
        children: periods.asMap().entries.map((e) {
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
                  style: AppTextStyles.semiBold.copyWith(
                    color: isSelected ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white38 : AppColors.textSecondary),
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

  Widget _buildScoreSection(BuildContext context, double score, bool isDark) {
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
              Text('${score.round()}%', style: AppTextStyles.semiBold.copyWith(fontSize: 18)),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('productivity_score'), style: AppTextStyles.semiBold.copyWith(fontSize: 10, color: Colors.grey, letterSpacing: 1.2)),
                const SizedBox(height: 6),
                Text(
                  score >= 80 ? context.tr('score_exceptional') : score >= 60 ? context.tr('score_growth') : context.tr('score_developing'),
                  style: AppTextStyles.semiBold.copyWith(fontSize: 16, letterSpacing: -0.4),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('score_desc'),
                  style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSummaryGrid(BuildContext context, List<Project> projects, bool isDark) {
    final completed = projects.where((p) => p.status == ProjectStatus.completed).length;
    final active = projects.where((p) => p.status == ProjectStatus.active).length;
    final onHold = projects.where((p) => p.status == ProjectStatus.onHold).length;
    final overdue = projects.where((p) => p.status == ProjectStatus.overdue).length;

    return Row(
      children: [
        Expanded(child: _CompactMetricTile(label: context.tr('metric_done'), val: '$completed', color: AppColors.emerald, isDark: isDark)),
        const SizedBox(width: 8),
        Expanded(child: _CompactMetricTile(label: context.tr('metric_live'), val: '$active', color: AppColors.indigo, isDark: isDark)),
        const SizedBox(width: 8),
        Expanded(child: _CompactMetricTile(label: context.tr('metric_late'), val: '$overdue', color: AppColors.rose, isDark: isDark)),
        const SizedBox(width: 8),
        Expanded(child: _CompactMetricTile(label: context.tr('metric_hold'), val: '$onHold', color: AppColors.amber, isDark: isDark)),
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

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: AppTextStyles.semiBold.copyWith(
        color: isDark ? Colors.white38 : AppColors.textMuted,
        fontSize: 10,
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

class _CompactMetricTile extends StatelessWidget {
  final String label, val;
  final Color color;
  final bool isDark;
  const _CompactMetricTile({required this.label, required this.val, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(val, style: AppTextStyles.bold.copyWith(color: color, fontSize: 18, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.bold.copyWith(color: Colors.grey, fontSize: 8)),
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
                  style: AppTextStyles.semiBold.copyWith(fontSize: compact ? 16 : 20, letterSpacing: -0.5)
                ),
                Text(label, style: AppTextStyles.semiBold.copyWith(color: Colors.grey, fontSize: 9, letterSpacing: 0.2)),
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

      final barRect = RRect.fromRectAndRadius(Rect.fromLTWH(x - barW / 2, y, barW, chartH - y), const Radius.circular(6));
      final barGrad = ui.Gradient.linear(Offset(x, y), Offset(x, chartH), [color.withOpacity(0.7), color.withOpacity(0.2)]);
      canvas.drawRRect(barRect, Paint()..shader = barGrad);
      
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - barW / 2, y, barW, 4), const Radius.circular(6)), Paint()..color = color.withOpacity(0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

      if (i == 0) path.moveTo(x, y);
      else {
        final prevX = (space / 2) + (i - 1) * (barW + space) + barW / 2;
        final prevY = chartH - (chartH * (data[i - 1].value / maxVal) * progress);
        path.cubicTo(prevX + (x - prevX) / 2, prevY, prevX + (x - prevX) / 2, y, x, y);
      }

      if (data[i].label.isNotEmpty) {
        final tp = TextPainter(text: TextSpan(text: data[i].label, style: AppTextStyles.semiBold.copyWith(color: Colors.grey, fontSize: 8)), textDirection: ui.TextDirection.ltr)..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, chartH + 12));
      }
    }

    canvas.drawPath(path, Paint()..color = color.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 6..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round);

    for (int i = 0; i < count; i++) {
      final x = (space / 2) + i * (barW + space) + barW / 2;
      final y = chartH - (chartH * (data[i].value / maxVal) * progress);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = Colors.white);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
