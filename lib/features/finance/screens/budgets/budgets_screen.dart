import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/database/app_database.dart';
import '../../providers/finance_providers.dart';
import '../../domain/models/budget_with_progress.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/currency_formatter.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsWithProgressProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, isDark),
          budgetsAsync.when(
            data: (budgets) {
              if (budgets.isEmpty) return SliverToBoxAdapter(child: _buildEmptyState(context, isDark));

              // Group budgets by Month
              final groupedBudgets = <String, List<BudgetWithProgress>>{};
              for (var budget in budgets) {
                final monthKey = DateFormat('MMMM yyyy').format(budget.startDate);
                if (!groupedBudgets.containsKey(monthKey)) {
                  groupedBudgets[monthKey] = [];
                }
                groupedBudgets[monthKey]!.add(budget);
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final monthKey = groupedBudgets.keys.elementAt(index);
                      final monthBudgets = groupedBudgets[monthKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                            child: Text(
                              monthKey.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: AppColors.emerald,
                              ),
                            ),
                          ),
                          ...monthBudgets.map((b) => _BudgetCard(budgetWithProgress: b, isDark: isDark)),
                        ],
                      );
                    },
                    childCount: groupedBudgets.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (err, _) => SliverFillRemaining(child: Center(child: Text('${context.tr('error')}: $err'))),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-budget'),
        backgroundColor: AppColors.indigo,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          context.tr('set_budget').toUpperCase(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
      ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 56, bottom: 20),
        title: Text(
          context.tr('budgets'),
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
                  child: const Icon(Icons.pie_chart_rounded, size: 200, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: Opacity(
                opacity: 0.15,
                child: const Icon(Icons.account_balance_wallet_rounded, size: 80, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 40),
      child: Column(
        children: [
          Icon(Icons.pie_chart_outline_rounded, size: 64, color: isDark ? Colors.white10 : Colors.grey.shade200),
          const SizedBox(height: 24),
          Text(context.tr('no_budgets_title'), style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            context.tr('no_budgets_desc'),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _BudgetCard extends ConsumerStatefulWidget {
  final BudgetWithProgress budgetWithProgress;
  final bool isDark;

  const _BudgetCard({required this.budgetWithProgress, required this.isDark});

  @override
  ConsumerState<_BudgetCard> createState() => _BudgetCardState();
}

class _BudgetCardState extends ConsumerState<_BudgetCard> {
  bool _isExpanded = false;

  void _handleItemToggle(BuildContext context, BudgetItem item, BudgetWithProgress budgetWithProgress) async {
    if (item.isChecked) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MarkSpentDialog(item: item, isDark: widget.isDark),
    );

    if (result != null) {
      final actualPrice = result['price'] as int;
      final walletId = result['walletId'] as String;

      if (walletId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('please_select_wallet'))),
          );
        }
        return;
      }

      try {
        await ref.read(budgetRepositoryProvider).markItemAsSpent(item, actualPrice, walletId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${context.tr('delete')} ${widget.budgetWithProgress.budget.name ?? context.tr('untitled_budget')}?'),
        content: Text(context.tr('delete_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              ref.read(budgetRepositoryProvider).deleteBudget(widget.budgetWithProgress.budget.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetWithProgress = widget.budgetWithProgress;
    final isDark = widget.isDark;
    final budget = budgetWithProgress.budget;
    final percent = budgetWithProgress.progressPercent;
    final isOverspent = budgetWithProgress.isOverspent;
    final color = isOverspent ? AppColors.rose : (percent > 0.8 ? AppColors.amber : AppColors.emerald);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.indigo.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.wallet_rounded,
                              color: AppColors.indigo,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                budget.name ?? context.tr('untitled_budget'),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                              Text(
                                budget.period.toUpperCase(),
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w800, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.formatScaled(budget.amount),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _showDeleteConfirmation(context, ref),
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                visualDensity: VisualDensity.compact,
                              ),
                              Icon(
                                _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${context.tr('spent')}: ${CurrencyFormatter.formatScaled(budgetWithProgress.spentAmount)}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : AppColors.textSecondary),
                      ),
                      Text(
                        '${(percent * 100).toInt()}%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1, indent: 20, endIndent: 20),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (budgetWithProgress.items.isEmpty)
                    Center(
                      child: Text(
                        context.tr('no_items_desc'),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    )
                  else
                    ...budgetWithProgress.items.map((item) => _BudgetItemTile(
                          item: item,
                          isDark: isDark,
                          onToggle: (val) => _handleItemToggle(context, item, budgetWithProgress),
                        )),
                  const SizedBox(height: 16),
                  _buildOutOfBudgetInfo(context, budgetWithProgress),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetric(
                        context,
                        context.tr('remaining'),
                        CurrencyFormatter.formatScaled(budgetWithProgress.remainingAmount.abs()),
                        isOverspent ? AppColors.rose : AppColors.emerald,
                      ),
                      _buildMetric(
                        context,
                        context.tr('prediction'),
                        CurrencyFormatter.formatScaled(budgetWithProgress.predictedSpending.round()),
                        budgetWithProgress.predictedSpending > budget.amount ? AppColors.amber : Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildOutOfBudgetInfo(BuildContext context, BudgetWithProgress budgetWithProgress) {
    final itemsSpent = budgetWithProgress.items
        .where((i) => i.isChecked)
        .fold<int>(0, (sum, i) => sum + (i.actualPrice ?? 0));
    final outOfBudget = budgetWithProgress.spentAmount - itemsSpent;

    if (outOfBudget <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.rose.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.rose, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${context.tr('out_of_budget')}: ${CurrencyFormatter.formatScaled(outOfBudget)}',
              style: const TextStyle(color: AppColors.rose, fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(BuildContext context, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}

class _BudgetItemTile extends StatelessWidget {
  final BudgetItem item;
  final bool isDark;
  final ValueChanged<bool?> onToggle;

  const _BudgetItemTile({required this.item, required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: item.isChecked,
              onChanged: onToggle,
              activeColor: AppColors.emerald,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    decoration: item.isChecked ? TextDecoration.lineThrough : null,
                    color: item.isChecked ? Colors.grey : (isDark ? Colors.white : AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          if (item.isChecked && item.actualPrice != null)
            Text(
              CurrencyFormatter.formatScaled(item.actualPrice!),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.emerald),
            ),
        ],
      ),
    );
  }
}

class _MarkSpentDialog extends ConsumerStatefulWidget {
  final BudgetItem item;
  final bool isDark;

  const _MarkSpentDialog({required this.item, required this.isDark});

  @override
  ConsumerState<_MarkSpentDialog> createState() => _MarkSpentDialogState();
}

class _MarkSpentDialogState extends ConsumerState<_MarkSpentDialog> {
  late TextEditingController _priceController;
  String? _selectedWalletId;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsStreamProvider);

    return AlertDialog(
      backgroundColor: widget.isDark ? const Color(0xFF161B22) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(context.tr('mark_as_spent'), style: const TextStyle(fontWeight: FontWeight.w900)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [CurrencyInputFormatter()],
            decoration: InputDecoration(
              labelText: context.tr('actual_price'),
              prefixText: 'TSh ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          walletsAsync.when(
            data: (wallets) => DropdownButtonFormField<String>(
              value: _selectedWalletId,
              isDense: true,
              hint: Text(context.tr('select_wallet')),
              items: wallets.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
              onChanged: (val) => setState(() => _selectedWalletId = val),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('cancel'))),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'price': (CurrencyInputFormatter.parse(_priceController.text) * 100).round(),
            'walletId': _selectedWalletId ?? '',
          }),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.indigo),
          child: Text(context.tr('confirm'), style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
