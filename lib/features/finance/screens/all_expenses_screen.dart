import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../projects/data/project_repository.dart';
import '../../projects/models/project_model.dart';
import '../data/finance_repository.dart';
import '../models/savings_goal_model.dart';

class AllExpensesScreen extends StatefulWidget {
  const AllExpensesScreen({super.key});

  @override
  State<AllExpensesScreen> createState() => _AllExpensesScreenState();
}

class _AllExpensesScreenState extends State<AllExpensesScreen> 
    with TickerProviderStateMixin {
  final FinanceRepository _financeRepo = FinanceRepository();
  final ProjectRepository _projectRepo = ProjectRepository();
  
  late TabController _tabController;
  late DateTime _selectedDate;
  String _filterType = 'Month'; // 'Week', 'Month' or 'Year'
  late AnimationController _chartCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDate = DateTime.now();
    _chartCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _chartCtrl.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chartCtrl.dispose();
    super.dispose();
  }

  DateTimeRange _getFilterRange() {
    if (_filterType == 'Week') {
      final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      return DateTimeRange(
        start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
        end: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).add(const Duration(days: 7)).subtract(const Duration(seconds: 1)),
      );
    } else if (_filterType == 'Month') {
      return DateTimeRange(
        start: DateTime(_selectedDate.year, _selectedDate.month, 1),
        end: DateTime(_selectedDate.year, _selectedDate.month + 1, 1).subtract(const Duration(seconds: 1)),
      );
    } else {
      return DateTimeRange(
        start: DateTime(_selectedDate.year, 1, 1),
        end: DateTime(_selectedDate.year, 12, 31, 23, 59, 59),
      );
    }
  }

  bool _isWithinRange(DateTime date, DateTimeRange range) {
    return (date.isAfter(range.start) || date.isAtSameMomentAs(range.start)) && 
           (date.isBefore(range.end) || date.isAtSameMomentAs(range.end));
  }

  void _previousPeriod() {
    setState(() {
      if (_filterType == 'Week') {
        _selectedDate = _selectedDate.subtract(const Duration(days: 7));
      } else if (_filterType == 'Month') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
      } else {
        _selectedDate = DateTime(_selectedDate.year - 1);
      }
      _chartCtrl.reset();
      _chartCtrl.forward();
    });
  }

  void _nextPeriod() {
    setState(() {
      if (_filterType == 'Week') {
        _selectedDate = _selectedDate.add(const Duration(days: 7));
      } else if (_filterType == 'Month') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
      } else {
        _selectedDate = DateTime(_selectedDate.year + 1);
      }
      _chartCtrl.reset();
      _chartCtrl.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final range = _getFilterRange();
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.bg,
      body: NestedScrollView(
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: _buildSliverAppBar(context, isDark),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildExpensesTab(isDark, range),
            _buildSavingsTab(isDark, range),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark) {
    final primaryColor = isDark ? const Color(0xFF064E3B) : const Color(0xFF059669);
    
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      stretch: true,
      backgroundColor: primaryColor, // Opaque when collapsed
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Finance Hub',
        style: AppTextStyles.h2(context).copyWith(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 62),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                    ? [const Color(0xFF065F46), const Color(0xFF064E3B)]
                    : [const Color(0xFF10B981), const Color(0xFF059669)],
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
                  child: const Icon(Icons.grid_4x4_rounded, size: 200, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 40,
              child: Opacity(
                opacity: 0.15,
                child: const Icon(Icons.account_balance_rounded, size: 80, color: Colors.white),
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
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D1117) : AppColors.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.emerald,
            labelColor: AppColors.emerald,
            unselectedLabelColor: Colors.grey.shade500,
            indicatorWeight: 4,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [
              Tab(text: 'EXPENSES'),
              Tab(text: 'SAVINGS'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    String displayText;
    if (_filterType == 'Week') {
      final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      displayText = '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d, yyyy').format(endOfWeek)}';
    } else if (_filterType == 'Month') {
      displayText = DateFormat('MMMM yyyy').format(_selectedDate);
    } else {
      displayText = DateFormat('yyyy').format(_selectedDate);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : AppColors.bg,
      ),
      child: Column(
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: ['Week', 'Month', 'Year'].map((type) {
                final isSelected = _filterType == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _filterType = type);
                      _chartCtrl.reset();
                      _chartCtrl.forward();
                    },
                    child: AnimatedContainer(
                      duration: 250.ms,
                      decoration: BoxDecoration(
                        color: isSelected ? (isDark ? Colors.white : AppColors.textPrimary) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        type.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white38 : AppColors.textSecondary),
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _PeriodNavBtn(icon: Icons.chevron_left_rounded, onTap: _previousPeriod, isDark: isDark),
              Expanded(
                child: Container(
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161B22) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
                  ),
                  child: Text(
                    displayText.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                  ),
                ),
              ),
              _PeriodNavBtn(icon: Icons.chevron_right_rounded, onTap: _nextPeriod, isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesTab(bool isDark, DateTimeRange range) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverToBoxAdapter(child: _buildFilterBar(isDark)),
            StreamBuilder<List<Expense>>(
              stream: _financeRepo.getAllExpenses(),
              builder: (context, eSnap) {
                if (!eSnap.hasData) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(strokeWidth: 2))));
                final allExpenses = eSnap.data!;

                return StreamBuilder<List<Payment>>(
                  stream: _financeRepo.getAllPayments(),
                  builder: (context, pSnap) {
                    final allPayments = pSnap.data ?? [];
                    final filteredExpenses = allExpenses.where((e) => _isWithinRange(e.date, range)).toList();
                    final filteredPayments = allPayments.where((p) => _isWithinRange(p.date, range)).toList();

                    final totalExp = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
                    final totalInc = filteredPayments.where((p) => p.isReceived).fold(0.0, (sum, p) => sum + p.amount);
                    final chartData = _generateExpenseChartData(filteredExpenses);

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildSummaryProgress(
                            label: 'Expense Load',
                            spent: totalExp,
                            income: totalInc,
                            color: AppColors.rose,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 32),
                          _buildSectionHeader('EXPENSE MOMENTUM', isDark),
                          const SizedBox(height: 16),
                          _buildMainChart(chartData, AppColors.rose, isDark),
                          const SizedBox(height: 32),
                          _buildSectionHeader('DETAILED RECORDS', isDark),
                          const SizedBox(height: 16),
                          if (filteredExpenses.isEmpty) _buildEmptyState(isDark, 'No Records Found')
                          else ...filteredExpenses.map((e) => _buildExpenseListItem(e, isDark)),
                          const SizedBox(height: 120),
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      }
    );
  }

  Widget _buildSavingsTab(bool isDark, DateTimeRange range) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverToBoxAdapter(child: _buildFilterBar(isDark)),
            StreamBuilder<List<SavingsRecord>>(
              stream: _financeRepo.getAllSavings(),
              builder: (context, sSnap) {
                if (!sSnap.hasData) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(strokeWidth: 2))));
                final allSavings = sSnap.data!;

                return StreamBuilder<List<Project>>(
                  stream: _projectRepo.getProjectsStream(),
                  builder: (context, pSnap) {
                    final projects = pSnap.data ?? [];
                    final projectMap = {for (var p in projects) p.id: p};
                    final filteredSavings = allSavings.where((s) => _isWithinRange(s.date, range)).toList();
                    final totalSaved = filteredSavings.fold(0.0, (s, r) => s + r.amount);

                    return StreamBuilder<SavingsGoal?>(
                      stream: _financeRepo.getSavingsGoal(),
                      builder: (context, goalSnap) {
                        final goal = goalSnap.data;
                        final target = _filterType == 'Week' ? ((goal?.monthlyGoal ?? 0) / 4) : (_filterType == 'Month' ? (goal?.monthlyGoal ?? 0) : (goal?.annualGoal ?? 0));
                        final chartData = _generateSavingsChartData(filteredSavings);

                        return SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _buildSummaryProgress(
                                label: 'Savings Goal',
                                spent: totalSaved,
                                income: target,
                                color: AppColors.indigo,
                                isDark: isDark,
                                isGoal: true,
                              ),
                              const SizedBox(height: 32),
                              _buildSectionHeader('SAVINGS MOMENTUM', isDark),
                              const SizedBox(height: 16),
                              _buildMainChart(chartData, AppColors.indigo, isDark),
                              const SizedBox(height: 32),
                              _buildSectionHeader('SAVINGS RECORDS', isDark),
                              const SizedBox(height: 16),
                              if (filteredSavings.isEmpty) _buildEmptyState(isDark, 'No Records Found')
                              else ...filteredSavings.map((s) => _buildSavingsItem(s, projectMap[s.projectId], isDark)),
                              const SizedBox(height: 120),
                            ]),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        );
      }
    );
  }

  Widget _buildSummaryProgress({
    required String label, 
    required double spent, 
    required double income, 
    required Color color, 
    required bool isDark,
    bool isGoal = false,
  }) {
    final progress = income > 0 ? (spent / income).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
        boxShadow: isDark ? [] : [BoxShadow(color: color.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('$percent%', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'TSh ${NumberFormat('#,###').format(spent)}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -0.5),
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100], borderRadius: BorderRadius.circular(6))),
              AnimatedBuilder(
                animation: _chartCtrl,
                builder: (context, child) => FractionallySizedBox(
                  widthFactor: progress * _chartCtrl.value,
                  child: Container(
                    height: 12, 
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color, color.withOpacity(0.6)]),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoPair(isGoal ? 'TARGET' : 'INCOME', income, isDark),
              _infoPair('REMAINING', (income - spent).clamp(0, double.infinity), isDark, color: (income - spent) < 0 ? AppColors.rose : null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoPair(String l, double v, bool isDark, {Color? color}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(l, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.grey)),
      Text('TSh ${NumberFormat.compact().format(v)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color ?? (isDark ? Colors.white : Colors.black))),
    ],
  );

  Widget _buildMainChart(List<FinanceChartData> data, Color color, bool isDark) {
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
          painter: _HistogramWithLinePainter(data: data, progress: _chartCtrl.value, color: color, isDark: isDark),
        ),
      ),
    );
  }

  List<FinanceChartData> _generateExpenseChartData(List<Expense> expenses) {
    final Map<int, double> map = {};
    if (_filterType == 'Week') {
      for (int i = 1; i <= 7; i++) map[i] = 0;
      final start = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      for (var e in expenses) {
        final d = e.date.difference(DateTime(start.year, start.month, start.day)).inDays + 1;
        if (d >= 1 && d <= 7) map[d] = (map[d] ?? 0) + e.amount;
      }
      return map.entries.map((e) => FinanceChartData(['M','T','W','T','F','S','S'][e.key-1], e.value)).toList();
    } else if (_filterType == 'Month') {
      final days = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
      for (int i = 1; i <= days; i++) map[i] = 0;
      for (var e in expenses) map[e.date.day] = (map[e.date.day] ?? 0) + e.amount;
      return map.entries.map((e) => FinanceChartData(e.key % 5 == 1 ? '${e.key}' : '', e.value)).toList();
    } else {
      for (int i = 1; i <= 12; i++) map[i] = 0;
      for (var e in expenses) map[e.date.month] = (map[e.date.month] ?? 0) + e.amount;
      return map.entries.map((e) => FinanceChartData(['J','F','M','A','M','J','J','A','S','O','N','D'][e.key-1], e.value)).toList();
    }
  }

  List<FinanceChartData> _generateSavingsChartData(List<SavingsRecord> savings) {
    final Map<int, double> map = {};
    if (_filterType == 'Week') {
      for (int i = 1; i <= 7; i++) map[i] = 0;
      final start = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      for (var s in savings) {
        final d = s.date.difference(DateTime(start.year, start.month, start.day)).inDays + 1;
        if (d >= 1 && d <= 7) map[d] = (map[d] ?? 0) + s.amount;
      }
      return map.entries.map((e) => FinanceChartData(['M','T','W','T','F','S','S'][e.key-1], e.value)).toList();
    } else if (_filterType == 'Month') {
      final days = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
      for (int i = 1; i <= days; i++) map[i] = 0;
      for (var s in savings) map[s.date.day] = (map[s.date.day] ?? 0) + s.amount;
      return map.entries.map((e) => FinanceChartData(e.key % 5 == 1 ? '${e.key}' : '', e.value)).toList();
    } else {
      for (int i = 1; i <= 12; i++) map[i] = 0;
      for (var s in savings) map[s.date.month] = (map[s.date.month] ?? 0) + s.amount;
      return map.entries.map((e) => FinanceChartData(['J','F','M','A','M','J','J','A','S','O','N','D'][e.key-1], e.value)).toList();
    }
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(color: isDark ? Colors.white38 : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
    );
  }

  Widget _buildExpenseListItem(Expense e, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.rose.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.outbound_rounded, color: AppColors.rose, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: -0.2)),
                Text(e.category, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('TSh ${NumberFormat('#,###').format(e.amount)}', style: const TextStyle(color: AppColors.rose, fontWeight: FontWeight.w900, fontSize: 15)),
              Text(DateFormat('MMM d').format(e.date), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildSavingsItem(SavingsRecord s, Project? p, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.savings_rounded, color: AppColors.indigo, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.accountName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: -0.2)),
                Text(p?.name ?? 'General Savings', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('TSh ${NumberFormat('#,###').format(s.amount)}', style: const TextStyle(color: AppColors.indigo, fontWeight: FontWeight.w900, fontSize: 15)),
              Text(DateFormat('MMM d').format(s.date), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildEmptyState(bool isDark, String msg) => Center(child: Padding(padding: const EdgeInsets.all(60), child: Column(children: [Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.withOpacity(0.2)), const SizedBox(height: 16), Text(msg, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w800, fontSize: 13))])));
}

class _PeriodNavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const _PeriodNavBtn({required this.icon, required this.onTap, required this.isDark});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isDark ? const Color(0xFF161B22) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5))), child: Icon(icon, size: 20)));
}

class FinanceChartData {
  final String label;
  final double value;
  FinanceChartData(this.label, this.value);
}

class _HistogramWithLinePainter extends CustomPainter {
  final List<FinanceChartData> data;
  final double progress;
  final Color color;
  final bool isDark;
  _HistogramWithLinePainter({required this.data, required this.progress, required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = data.map((e) => e.value).reduce(math.max).clamp(1000.0, double.infinity);
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
      
      // Shadow/Glow for bar top
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - barW / 2, y, barW, 4), const Radius.circular(6)), Paint()..color = color.withOpacity(0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

      // Path for Line
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

    // Dots
    for (int i = 0; i < count; i++) {
      final x = (space / 2) + i * (barW + space) + barW / 2;
      final y = chartH - (chartH * (data[i].value / maxVal) * progress);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = Colors.white);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
