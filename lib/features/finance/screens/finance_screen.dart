import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../projects/models/project_model.dart';
import '../../projects/data/project_repository.dart';
import '../data/finance_repository.dart';
import 'project_expenses_screen.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final ProjectRepository _projectRepo = ProjectRepository();
  final FinanceRepository _financeRepo = FinanceRepository();

  late DateTime _selectedDate;
  String _filterType = 'Month'; // 'Month' or 'Year'

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  DateTimeRange _getFilterRange() {
    if (_filterType == 'Month') {
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
      if (_filterType == 'Month') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
      } else {
        _selectedDate = DateTime(_selectedDate.year - 1);
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      if (_filterType == 'Month') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
      } else {
        _selectedDate = DateTime(_selectedDate.year + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final range = _getFilterRange();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.bg,
      body: CustomScrollView(
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
                  _buildFilterControls(isDark),
                  const SizedBox(height: 24),

                  StreamBuilder<List<Project>>(
                    stream: _projectRepo.getProjectsStream(),
                    builder: (context, projectSnapshot) {
                      return StreamBuilder<List<Payment>>(
                        stream: _financeRepo.getAllPayments(),
                        builder: (context, paymentSnapshot) {
                          return StreamBuilder<List<Expense>>(
                            stream: _financeRepo.getAllExpenses(),
                            builder: (context, expenseSnapshot) {
                              return StreamBuilder<List<SavingsRecord>>(
                                stream: _financeRepo.getAllSavings(),
                                builder: (context, savingsSnapshot) {
                                  if (!projectSnapshot.hasData || !paymentSnapshot.hasData ||
                                      !expenseSnapshot.hasData || !savingsSnapshot.hasData) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(40),
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.emerald),
                                      ),
                                    );
                                  }

                                  final allProjects = projectSnapshot.data!;
                                  final allPayments = paymentSnapshot.data!;
                                  final allExpenses = expenseSnapshot.data!;
                                  final allSavings = savingsSnapshot.data!;

                                  final filteredProjects = allProjects.where((p) => _isWithinRange(p.createdAt, range)).toList();
                                  final filteredPayments = allPayments.where((p) => _isWithinRange(p.date, range)).toList();
                                  final filteredExpenses = allExpenses.where((e) => _isWithinRange(e.date, range)).toList();
                                  final filteredSavings = allSavings.where((s) => _isWithinRange(s.date, range)).toList();

                                  double totalRevenue = filteredProjects.fold(0.0, (sum, p) => sum + p.totalPrice);
                                  double totalCollected = filteredPayments.fold(0.0, (sum, p) => sum + p.amount);
                                  double totalExpenses = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
                                  double totalSaved = filteredSavings.fold(0.0, (sum, s) => sum + s.amount);

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildSummaryGrid(totalRevenue, totalCollected, totalExpenses, totalSaved, isDark),
                                      const SizedBox(height: 16),
                                      _BalanceBanner(
                                        totalRevenue: totalRevenue,
                                        totalCollected: totalCollected,
                                        totalExpenses: totalExpenses,
                                        isDark: isDark,
                                      ),
                                      const SizedBox(height: 32),
                                      _buildSectionHeader(context, 'PROJECT FINANCIALS', 'Revenue & Performance'),
                                      const SizedBox(height: 16),
                                      _buildProjectList(allProjects, allPayments, allExpenses, allSavings, isDark),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(double revenue, double collected, double expenses, double saved, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: (constraints.maxWidth / 2) / 75,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            _MetricCard(label: 'Revenue', value: revenue, icon: Icons.trending_up_rounded, color: AppColors.indigo, isDark: isDark),
            _MetricCard(label: 'Collected', value: collected, icon: Icons.account_balance_wallet_rounded, color: AppColors.emerald, isDark: isDark),
            _MetricCard(label: 'Expenses', value: expenses, icon: Icons.shopping_bag_rounded, color: AppColors.rose, isDark: isDark),
            _MetricCard(label: 'Saved', value: saved, icon: Icons.savings_rounded, color: Colors.amber, isDark: isDark),
          ],
        );
      }
    );
  }

  Widget _buildProjectList(List<Project> projects, List<Payment> payments, List<Expense> expenses, List<SavingsRecord> savings, bool isDark) {
    if (projects.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final project = projects[index];
        final projectPayments = payments.where((p) => p.projectId == project.id).toList();
        final projectExpenses = expenses.where((e) => e.projectId == project.id).toList();
        final projectSavings = savings.where((s) => s.projectId == project.id).toList();

        return _ProjectFinanceItem(
          project: project,
          payments: projectPayments,
          expenses: projectExpenses,
          savings: projectSavings,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String overline, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          overline,
          style: AppTextStyles.labelSmall(context).copyWith(
            color: AppColors.emerald,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w900,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: AppTextStyles.h3(context).copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            fontSize: 20,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
        title: Text(
          'Finance Hub',
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
            // Abstract geometric pattern
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
              bottom: 20,
              child: Opacity(
                opacity: 0.15,
                child: const Icon(Icons.account_balance_rounded, size: 80, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterControls(bool isDark) {
    final displayText = _filterType == 'Month' 
        ? DateFormat('MMMM yyyy').format(_selectedDate)
        : DateFormat('yyyy').format(_selectedDate);

    return Column(
      children: [
        Container(
          height: 40,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: ['Month', 'Year'].map((type) {
              final isSelected = _filterType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _filterType = type),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    decoration: BoxDecoration(
                      color: isSelected ? (isDark ? Colors.white : AppColors.textPrimary) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      type,
                      style: TextStyle(
                        color: isSelected ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white38 : AppColors.textSecondary),
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousPeriod,
                icon: const Icon(Icons.chevron_left_rounded),
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(
                  displayText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              IconButton(
                onPressed: _nextPeriod,
                icon: const Icon(Icons.chevron_right_rounded),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.emerald.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text('No Financial Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            'No records found for the selected period.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.compactCurrency(symbol: '', decimalDigits: 1);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 12),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'TSh ',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: color.withOpacity(0.6),
                  ),
                ),
                Text(
                  currencyFormat.format(value),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }
}

class _BalanceBanner extends StatelessWidget {
  final double totalRevenue;
  final double totalCollected;
  final double totalExpenses;
  final bool isDark;

  const _BalanceBanner({
    required this.totalRevenue,
    required this.totalCollected,
    required this.totalExpenses,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final netProfit = totalCollected - totalExpenses;
    final pending = totalRevenue - totalCollected;
    final formatter = NumberFormat.currency(symbol: 'TSh ', decimalDigits: 0);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2128) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (netProfit >= 0 ? AppColors.emerald : AppColors.rose).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  netProfit >= 0 ? Icons.account_balance_wallet_rounded : Icons.trending_down_rounded,
                  color: netProfit >= 0 ? AppColors.emerald : AppColors.rose,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NET CASH FLOW',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isDark ? Colors.white38 : Colors.grey,
                      ),
                    ),
                    Text(
                      formatter.format(netProfit),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: netProfit >= 0 ? AppColors.emerald : AppColors.rose,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, thickness: 0.5)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SmallInfo(label: 'PENDING REVENUE', value: formatter.format(pending), color: AppColors.amber, isDark: isDark),
              _SmallInfo(
                label: 'PROFIT MARGIN',
                value: totalCollected > 0 ? '${((netProfit / totalCollected) * 100).toInt()}%' : '0%',
                color: AppColors.indigo,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _SmallInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _SmallInfo({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: isDark ? Colors.white24 : Colors.grey, letterSpacing: 0.3),
        ),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}

class _ProjectFinanceItem extends StatelessWidget {
  final Project project;
  final List<Payment> payments;
  final List<Expense> expenses;
  final List<SavingsRecord> savings;
  final bool isDark;

  const _ProjectFinanceItem({
    required this.project,
    required this.payments,
    required this.expenses,
    required this.savings,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: 'TSh ', decimalDigits: 0);
    
    final totalCollected = payments.fold(0.0, (sum, p) => sum + p.amount);
    final totalExp = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalSaved = savings.fold(0.0, (sum, s) => sum + s.amount);
    
    final paymentPercent = project.totalPrice == 0 ? 0.0 : (totalCollected / project.totalPrice).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProjectExpensesScreen(project: project)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: project.projectColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(project.projectEmoji, style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: -0.3),
                            ),
                            Text(
                              'Total: ${formatter.format(project.totalPrice)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white38 : AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _ProgressBadge(percent: paymentPercent),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _CustomProgressBar(percent: paymentPercent, color: project.projectColor),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _MiniMetric(
                        label: 'Collected',
                        value: NumberFormat.compactCurrency(symbol: '').format(totalCollected),
                        color: AppColors.emerald,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _MiniMetric(
                        label: 'Expenses',
                        value: NumberFormat.compactCurrency(symbol: '').format(totalExp),
                        color: AppColors.rose,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _MiniMetric(
                        label: 'Saved',
                        value: NumberFormat.compactCurrency(symbol: '').format(totalSaved),
                        color: Colors.amber,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  final double percent;
  const _ProgressBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    final isDone = percent >= 1.0;
    final color = isDone ? AppColors.emerald : AppColors.indigo;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(
        '${(percent * 100).toInt()}%',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _CustomProgressBar extends StatelessWidget {
  final double percent;
  final Color color;

  const _CustomProgressBar({required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(3)),
        ),
        FractionallySizedBox(
          widthFactor: percent,
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _MiniMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.02) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white38 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              child: Text(
                'TSh $value',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
