import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/database/app_database.dart';
import '../../providers/finance_providers.dart';
import '../../../../core/utils/currency_formatter.dart';

import '../../../../core/localization/app_localizations.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupedAsync = ref.watch(groupedTransactionsProvider);
    final filter = ref.watch(transactionFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  _buildSearchBar(context, isDark),
                  const SizedBox(height: 16),
                  _buildFilterChips(context, filter, isDark),
                ],
              ),
            ),
          ),
          groupedAsync.when(
            data: (groupedTransactions) {
              if (groupedTransactions.isEmpty) return SliverFillRemaining(child: _buildEmptyState(context, isDark));
              
              // Calculate summary based on ALL filtered transactions
              int totalIncome = 0;
              int totalExpense = 0;
              for (var txs in groupedTransactions.values) {
                for (var tx in txs) {
                  if (tx.type == 'Income') totalIncome += tx.amount;
                  if (tx.type == 'Expense') totalExpense += tx.amount;
                }
              }
              final net = totalIncome - totalExpense;

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: _buildQuickSummary(context, totalIncome, totalExpense, net, isDark),
                        );
                      }
                      
                      final adjustedIndex = index - 1;
                      if (adjustedIndex >= groupedTransactions.length) return null;
                      
                      final date = groupedTransactions.keys.elementAt(adjustedIndex);
                      final txs = groupedTransactions[date]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDateHeader(context, date, isDark),
                          const SizedBox(height: 12),
                          ...txs.map((tx) => _TransactionListItem(transaction: tx, isDark: isDark)),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                    childCount: groupedTransactions.length + 1,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.indigo),
              ),
            ),
            error: (err, _) => SliverFillRemaining(child: Center(child: Text('${context.tr('error')}: $err'))),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-transaction'),
        backgroundColor: AppColors.indigo,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          context.tr('new_record').toUpperCase(), 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12)
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
          context.tr('transactions'),
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
                  child: const Icon(Icons.history_rounded, size: 200, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withValues(alpha: 0.5)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => ref.read(transactionFilterProvider.notifier).update((s) => s.copyWith(searchQuery: value)),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: context.tr('search_transactions'),
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.indigo),
          suffixIcon: _searchController.text.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(transactionFilterProvider.notifier).update((s) => s.copyWith(searchQuery: ''));
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, TransactionFilterState filter, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: TransactionTypeFilter.values.map((type) {
          final isSelected = filter.type == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(context.tr(type.name).toUpperCase()),
              labelStyle: TextStyle(
                fontSize: 10, 
                fontWeight: FontWeight.w900, 
                color: isSelected ? Colors.white : Colors.grey,
                letterSpacing: 0.5
              ),
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
              selectedColor: AppColors.indigo,
              onSelected: (selected) {
                ref.read(transactionFilterProvider.notifier).update((s) => s.copyWith(type: type));
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSelected ? Colors.transparent : Colors.transparent),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, DateTime date, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);

    String label;
    if (txDate == today) {
      label = context.tr('today');
    } else if (txDate == yesterday) {
      label = context.tr('yesterday');
    } else {
      label = DateFormat('MMMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11, 
          fontWeight: FontWeight.w900, 
          color: isDark ? Colors.white24 : AppColors.textMuted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildQuickSummary(BuildContext context, int income, int expense, int net, bool isDark) {
    final formatter = NumberFormat('#,###');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withValues(alpha: 0.5)),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryItem(label: context.tr('income').toUpperCase(), value: formatter.format(income), color: AppColors.emerald, isDark: isDark),
              _SummaryItem(label: context.tr('expense').toUpperCase(), value: formatter.format(expense), color: AppColors.rose, isDark: isDark),
              _SummaryItem(label: context.tr('net').toUpperCase(), value: formatter.format(net), color: AppColors.indigo, isDark: isDark),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined, size: 64, color: isDark ? Colors.white10 : Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('no_transactions_yet'),
            style: AppTextStyles.h3.copyWith(color: isDark ? Colors.white38 : Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _SummaryItem({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: TextStyle(
            fontSize: 9, 
            fontWeight: FontWeight.w900, 
            color: isDark ? Colors.white24 : AppColors.textMuted, 
            letterSpacing: 1
          )
        ),
        const SizedBox(height: 4),
        Text(
          'TSh $value', 
          style: TextStyle(
            color: color, 
            fontWeight: FontWeight.w900, 
            fontSize: 14, 
            letterSpacing: -0.5
          )
        ),
      ],
    );
  }
}

class _TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final bool isDark;

  const _TransactionListItem({required this.transaction, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'Expense';
    final isTransfer = transaction.type == 'Transfer';
    final color = isExpense ? AppColors.rose : (isTransfer ? AppColors.indigo : AppColors.emerald);
    
    // Amount is stored in cents, so divide by 100 for display if needed.
    // However, looking at the previous logic, it seems they store as absolute values.
    // Let's format nicely.
    final displayAmount = CurrencyFormatter.formatScaled(transaction.amount);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withValues(alpha: 0.5)),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1), 
            borderRadius: BorderRadius.circular(14)
          ),
          child: Icon(
            isTransfer 
                ? Icons.swap_horiz_rounded 
                : (isExpense ? Icons.south_east_rounded : Icons.north_east_rounded), 
            color: color, 
            size: 20
          ),
        ),
        title: Text(
          transaction.note ?? context.tr(transaction.type.toLowerCase()), 
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: -0.2),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          DateFormat('hh:mm a').format(transaction.date),
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isExpense ? "-" : (isTransfer ? "" : "+")} $displayAmount',
                  style: TextStyle(
                    color: isDark ? Colors.white : (isExpense ? AppColors.rose : (isTransfer ? AppColors.indigo : AppColors.emerald)), 
                    fontWeight: FontWeight.w900, 
                    fontSize: 14,
                    letterSpacing: -0.5
                  )
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    context.tr(transaction.type.toLowerCase()).toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey.shade500, 
                      fontSize: 8, 
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Consumer(
              builder: (context, ref, child) => IconButton(
                onPressed: () => _showDeleteConfirmation(context, ref),
                icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent.withValues(alpha: 0.7)),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0);
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${context.tr('delete')} ${context.tr('transactions')}?'),
        content: Text(context.tr('delete_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              ref.read(transactionRepositoryProvider).deleteTransaction(transaction.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
  }
}
