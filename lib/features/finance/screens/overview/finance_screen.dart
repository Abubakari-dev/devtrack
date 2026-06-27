import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/dev_card.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/services/security_service.dart';
import '../../../../core/widgets/shared_widgets.dart';
import 'package:devtrack/features/projects/models/models.dart';
import 'package:devtrack/features/projects/providers/projects_providers.dart';
import 'package:devtrack/features/finance/providers/finance_providers.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  bool _isAuthorized = false;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkSecurity();
  }

  Future<void> _checkSecurity() async {
    final isEnabled = await SecurityService.instance.isBiometricEnabled;
    if (!isEnabled || SecurityService.instance.isFinanceUnlocked) {
      setState(() {
        _isAuthorized = true;
        _isCheckingAuth = false;
      });
      return;
    }

    final authenticated = await SecurityService.instance.authenticate(
      reason: 'Please authenticate to access Finance Hub',
    );

    if (authenticated) {
      SecurityService.instance.unlockFinance();
    }

    setState(() {
      _isAuthorized = authenticated;
      _isCheckingAuth = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.indigo)),
      );
    }

    if (!_isAuthorized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 64, color: AppColors.indigo),
              const SizedBox(height: 16),
              const Text('Finance Hub is Locked', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkSecurity,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.indigo),
                child: const Text('Unlock with Fingerprint', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredDataAsync = ref.watch(filteredFinanceDataProvider);
    final globalSummaryAsync = ref.watch(globalFinancialSummaryProvider);
    final filter = ref.watch(financeFilterProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context, isDark, ref),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildFilterControls(context, ref, filter, isDark),
            ),
          ),
          globalSummaryAsync.when(
            data: (summary) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _OperatingProfitCard(
                  operatingProfit: summary['operatingProfit']!,
                  grossProfit: summary['grossProfit']!,
                  overheads: summary['generalOverheads']!,
                  isDark: isDark,
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          filteredDataAsync.when(
            data: (data) => SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _WalletBalanceCard(
                    totalBalance: data.totalBalance,
                    totalRevenue: data.totalRevenue,
                    pendingRevenue: data.pendingRevenue,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 32),
                  DevSectionHeader(
                    overline: context.tr('project_financials'),
                    title: context.tr('revenue_performance'),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 16),
                  if (data.projects.isEmpty)
                    _buildEmptyState(context, isDark)
                  else
                    ...data.projects.map((project) {
                      final projectPayments = data.allPayments.where((p) => p.projectId == project.id).toList();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildProjectFinanceItem(
                          project: project,
                          payments: projectPayments,
                          isDark: isDark,
                          context: context,
                          ref: ref,
                        ),
                      );
                    }),
                  const SizedBox(height: 32),
                  DevSectionHeader(
                    overline: context.tr('detailed_records'),
                    title: context.tr('expense_history'),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 16),
                  if (data.expenses.isEmpty)
                    _buildEmptyState(context, isDark)
                  else
                    ...data.expenses.map((expense) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildExpenseItem(context, ref, expense, isDark),
                    )),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.emerald),
              ),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-transaction'),
        backgroundColor: isDark ? Colors.white : AppColors.textPrimary,
        foregroundColor: isDark ? Colors.black : Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(context.tr('add_transaction').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            if (value == 'clear_all') {
              _showClearAllConfirmation(context, ref);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'clear_all',
              child: Row(
                children: [
                  const Icon(Icons.delete_sweep_rounded, size: 18, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Text(context.tr('clear_all_finance_data'), style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
        title: Text(
          context.tr('finance_hub'),
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

  void _showClearAllConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('clear_all_finance_data')),
        content: Text(context.tr('clear_finance_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () async {
              // 1. Clear Firestore data
              await ref.read(financeRepositoryProvider).clearAllFinanceData();
              // 2. Clear Local Database
              await ref.read(databaseProvider).clearAllData();
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('done'))),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
  }

  void _showDeleteProjectPaymentsConfirmation(BuildContext context, WidgetRef ref, Project project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('delete_payments_q')),
        content: Text(context.tr('delete_payments_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              ref.read(financeRepositoryProvider).deleteProjectPayments(project.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('done'))),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
  }

  void _showDeleteExpenseConfirmation(BuildContext context, WidgetRef ref, Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${context.tr('delete')} ${expense.name}?'),
        content: Text(context.tr('delete_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              ref.read(financeRepositoryProvider).deleteExpense(expense.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('done'))),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(BuildContext context, WidgetRef ref, Expense expense, bool isDark) {
    final hasProject = expense.projectId.isNotEmpty && expense.projectId != 'GENERAL';

    return DevCard(
      padding: EdgeInsets.zero,
      borderRadius: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            // Optional: Action
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Category Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(expense.category).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(expense.category),
                    color: _getCategoryColor(expense.category),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.name,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: -0.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Text(
                            expense.category,
                            style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                          if (hasProject) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.indigo.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.rocket_launch_rounded, size: 8, color: AppColors.indigo),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '- ${CurrencyFormatter.formatScaled(expense.amount.toInt())}',
                      style: const TextStyle(color: AppColors.rose, fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    Text(
                      DateFormat('MMM d').format(expense.date),
                      style: TextStyle(fontSize: 10, color: isDark ? Colors.white24 : AppColors.textMuted),
                    ),
                  ],
                ),
                
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showDeleteExpenseConfirmation(context, ref, expense),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('material') || cat.contains('vifaa')) return Icons.inventory_2_rounded;
    if (cat.contains('labor') || cat.contains('fundi')) return Icons.engineering_rounded;
    if (cat.contains('rent') || cat.contains('pango')) return Icons.home_work_rounded;
    if (cat.contains('debt') || cat.contains('deni') || cat.contains('repayment')) return Icons.price_check_rounded;
    if (cat.contains('marketing') || cat.contains('matangazo')) return Icons.campaign_rounded;
    if (cat.contains('travel') || cat.contains('safari')) return Icons.directions_bus_rounded;
    if (cat.contains('invest') || cat.contains('wekezaji')) return Icons.trending_up_rounded;
    return Icons.receipt_long_rounded;
  }

  Color _getCategoryColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('material') || cat.contains('vifaa')) return AppColors.rose;
    if (cat.contains('labor') || cat.contains('fundi')) return AppColors.amber;
    if (cat.contains('rent') || cat.contains('pango')) return AppColors.blue;
    if (cat.contains('debt') || cat.contains('deni')) return Colors.red;
    if (cat.contains('invest') || cat.contains('wekezaji')) return AppColors.emerald;
    return AppColors.rose;
  }

  Widget _buildProjectFinanceItem({
    required Project project,
    required List<Payment> payments,
    required bool isDark,
    required BuildContext context,
    required WidgetRef ref,
  }) {
    // Both project.totalPrice and p.amount are in CENTS
    final totalCollected = payments.fold(0.0, (sum, p) => p.isReceived ? sum + p.amount : sum - p.amount);
    
    final paymentPercent = project.totalPrice == 0 ? 0.0 : (totalCollected / project.totalPrice).clamp(0.0, 1.0);

    return DevCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: project.projectColor.withValues(alpha: 0.1),
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
                      '${context.tr('total')}: ${CurrencyFormatter.formatScaled(project.totalPrice.toInt())}',
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
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _showDeleteProjectPaymentsConfirmation(context, ref, project),
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CustomProgressBar(percent: paymentPercent, color: project.projectColor),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniMetric(
                label: context.tr('collected'),
                value: CurrencyFormatter.compactScaled(totalCollected.toInt(), symbol: ''),
                color: AppColors.emerald,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _MiniMetric(
                label: context.tr('remaining'),
                value: CurrencyFormatter.compactScaled((project.totalPrice - totalCollected).toInt(), symbol: ''),
                color: AppColors.amber,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls(BuildContext context, WidgetRef ref, FinanceFilter filter, bool isDark) {
    final displayText = filter.type == 'Month' 
        ? DateFormat('MMMM yyyy', Localizations.localeOf(context).toString()).format(filter.selectedDate)
        : DateFormat('yyyy', Localizations.localeOf(context).toString()).format(filter.selectedDate);

    return Column(
      children: [
        DevCard(
          padding: const EdgeInsets.all(4),
          borderRadius: 12,
          child: Row(
            children: ['Month', 'Year'].map((type) {
              final isSelected = filter.type == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(financeFilterProvider.notifier).update((s) => s.copyWith(type: type));
                  },
                  child: AnimatedContainer(
                    duration: 200.ms,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected ? (isDark ? Colors.white : AppColors.textPrimary) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      context.tr(type.toLowerCase()),
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
        DevCard(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          borderRadius: 14,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(financeFilterProvider.notifier).update((s) {
                    final newDate = s.type == 'Month'
                        ? DateTime(s.selectedDate.year, s.selectedDate.month - 1)
                        : DateTime(s.selectedDate.year - 1);
                    return s.copyWith(selectedDate: newDate);
                  });
                },
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
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(financeFilterProvider.notifier).update((s) {
                    final newDate = s.type == 'Month'
                        ? DateTime(s.selectedDate.year, s.selectedDate.month + 1)
                        : DateTime(s.selectedDate.year + 1);
                    return s.copyWith(selectedDate: newDate);
                  });
                },
                icon: const Icon(Icons.chevron_right_rounded),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return DevCard(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.emerald.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(context.tr('no_financial_data'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            context.tr('no_records_period'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  final int totalBalance;
  final double totalRevenue;
  final double pendingRevenue;
  final bool isDark;

  const _WalletBalanceCard({
    required this.totalBalance, 
    required this.totalRevenue,
    required this.pendingRevenue,
    required this.isDark
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.indigo).withValues(alpha: 0.25),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                  ? [const Color(0xFF2E1065), const Color(0xFF0F172A)]
                  : [const Color(0xFF6366F1), const Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -50,
            child: Transform.rotate(
              angle: 0.5,
              child: Icon(
                Icons.account_balance_wallet_rounded, 
                size: 180, 
                color: Colors.white.withValues(alpha: 0.03)
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('total_wallet_balance'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Icon(Icons.contactless_rounded, color: Colors.white.withValues(alpha: 0.3), size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatScaled(totalBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _CardStat(
                          label: context.tr('total_revenue'),
                          value: CurrencyFormatter.compactScaled(totalRevenue.toInt()),
                        ),
                      ),
                      Container(width: 1, height: 24, color: Colors.white12),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _CardStat(
                          label: context.tr('pending_revenue'),
                          value: CurrencyFormatter.compactScaled(pendingRevenue.toInt()),
                          valueColor: AppColors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }
}

class _CardStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _CardStat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
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
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
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
          decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(3)),
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
          color: isDark ? Colors.white38.withValues(alpha: 0.02) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
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

class _OperatingProfitCard extends StatelessWidget {
  final double operatingProfit;
  final double grossProfit;
  final double overheads;
  final bool isDark;

  const _OperatingProfitCard({
    required this.operatingProfit,
    required this.grossProfit,
    required this.overheads,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return DevCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('operating_profit').toUpperCase(),
                style: TextStyle(
                  color: isDark ? Colors.white38 : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              Icon(
                Icons.trending_up_rounded,
                color: operatingProfit >= 0 ? AppColors.emerald : AppColors.rose,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(operatingProfit),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: operatingProfit >= 0 ? (isDark ? Colors.white : Colors.black) : AppColors.rose,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SimpleStat(
                  label: context.tr('gross_profit'),
                  value: CurrencyFormatter.compact(grossProfit),
                  color: AppColors.emerald,
                ),
              ),
              Container(width: 1, height: 20, color: isDark ? Colors.white12 : Colors.grey.shade200),
              const SizedBox(width: 16),
              Expanded(
                child: _SimpleStat(
                  label: context.tr('general_overheads'),
                  value: CurrencyFormatter.compact(overheads),
                  color: AppColors.rose,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimpleStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SimpleStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.grey),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color),
        ),
      ],
    );
  }
}
