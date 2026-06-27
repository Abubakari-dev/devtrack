import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/database/app_database.dart';
import 'package:devtrack/core/utils/currency_formatter.dart';
import '../../providers/finance_providers.dart';
import '../../../projects/providers/projects_providers.dart';

import '../../../../core/localization/app_localizations.dart';

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtsAsync = ref.watch(debtsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, isDark),
          SliverToBoxAdapter(
            child: debtsAsync.when(
              data: (debts) {
                if (debts.isEmpty) return _buildEmptyState(context, isDark);

                final lent = debts
                    .where((d) => d.type == 'lent' && d.status != 'paid')
                    .fold(0, (sum, d) => sum + (d.principalAmount - d.amountPaid));
                final borrowed = debts
                    .where((d) => d.type == 'borrowed' && d.status != 'paid')
                    .fold(0, (sum, d) => sum + (d.principalAmount - d.amountPaid));

                return Column(
                  children: [
                    _buildQuickSummary(context, lent, borrowed, isDark),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: debts.length,
                      itemBuilder: (context, index) {
                        final debt = debts[index];
                        return _DebtListItem(debt: debt, isDark: isDark);
                      },
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(100),
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.rose),
                ),
              ),
              error: (err, _) => Center(child: Text('${context.tr('error')}: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.push('/add-debt');
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4,
        icon: Icon(Icons.person_add_rounded, color: Theme.of(context).colorScheme.onPrimary),
        label: Text(
          context.tr('new_debt').toUpperCase(), 
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12)
        ),
      ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 140,
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
          context.tr('debts_loans'),
          style: AppTextStyles.bold.copyWith(
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
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
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
                  child: const Icon(Icons.people_alt_rounded, size: 180, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSummary(BuildContext context, int lent, int borrowed, bool isDark) {
    final formatter = NumberFormat('#,###');
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
            : [const Color(0xFF4F46E5), const Color(0xFF6366F1)],
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.indigo).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SummaryItem(
            label: context.tr('total_lent'),
            value: formatter.format(lent),
            icon: Icons.arrow_outward_rounded,
            color: AppColors.emerald,
          ),
          Container(height: 40, width: 1, color: Colors.white.withOpacity(0.1)),
          _SummaryItem(
            label: context.tr('total_borrowed'),
            value: formatter.format(borrowed),
            icon: Icons.arrow_downward_rounded,
            color: const Color(0xFFFDA4AF), // Light Rose
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Column(
          children: [
            Icon(Icons.people_outline_rounded, size: 64, color: isDark ? Colors.white10 : Colors.grey.shade200),
            const SizedBox(height: 16),
            Text(
              context.tr('no_debts_recorded'),
              style: AppTextStyles.h3.copyWith(color: isDark ? Colors.white38 : Colors.grey.shade400),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('track_money_lent_borrowed'),
              style: TextStyle(color: isDark ? Colors.white12 : Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: Colors.white.withOpacity(0.6),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'TSh $value',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _DebtListItem extends ConsumerWidget {
  final Debt debt;
  final bool isDark;

  const _DebtListItem({required this.debt, required this.isDark});

  void _markAsPaid(BuildContext context, WidgetRef ref) async {
    final remaining = debt.principalAmount - debt.amountPaid;
    if (remaining <= 0) return;

    HapticFeedback.heavyImpact();
    
    try {
      final repo = ref.read(debtRepositoryProvider);
      await repo.recordPayment(DebtPaymentsCompanion.insert(
        id: drift.Value(const Uuid().v4()),
        debtId: debt.id,
        amount: remaining,
        date: DateTime.now(),
      ));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('settled').toUpperCase()),
            backgroundColor: AppColors.emerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showPaymentSheet(BuildContext context, WidgetRef ref) {
    final amountCtrl = TextEditingController();
    final isLent = debt.type == 'lent';
    final accentColor = isLent ? AppColors.indigo : Colors.amber;
    String? selectedWalletId;
    String? selectedProjectId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final walletsAsync = ref.watch(walletsStreamProvider);
          
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B22) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 24),
                  Text(
                    isLent ? context.tr('receive_payment') : context.tr('repay_loan'), 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${context.tr('balance')}: TSh ${NumberFormat('#,###').format(debt.principalAmount - debt.amountPaid)}',
                    style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    autofocus: true,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    decoration: InputDecoration(
                      labelText: context.tr('payment_amount'),
                      labelStyle: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
                      prefixIcon: Icon(Icons.payments_outlined, color: accentColor, size: 20),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: accentColor, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  walletsAsync.when(
                    data: (wallets) => DropdownButtonFormField<String>(
                      value: selectedWalletId,
                      isDense: true,
                      dropdownColor: isDark ? const Color(0xFF161B22) : Colors.white,
                      hint: Text(context.tr('select_wallet'), style: const TextStyle(fontSize: 14)),
                      items: wallets.map((w) => DropdownMenuItem(
                        value: w.id, 
                        child: Text(w.name, style: TextStyle(color: isDark ? Colors.white : Colors.black))
                      )).toList(),
                      onChanged: (val) => setModalState(() => selectedWalletId = val),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: accentColor, width: 2)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  ref.watch(allProjectsStreamProvider).when(
                    data: (projects) => DropdownButtonFormField<String?>(
                      value: selectedProjectId,
                      isDense: true,
                      dropdownColor: isDark ? const Color(0xFF161B22) : Colors.white,
                      hint: Text(context.tr('select_project'), style: const TextStyle(fontSize: 14)),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(context.tr('none'), style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
                        ),
                        ...projects.map((p) => DropdownMenuItem(
                          value: p.id, 
                          child: Text(p.name, style: TextStyle(color: isDark ? Colors.white : Colors.black))
                        )).toList(),
                      ],
                      onChanged: (val) => setModalState(() => selectedProjectId = val),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: accentColor, width: 2)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (amountCtrl.text.isEmpty) return;
                        final amount = CurrencyInputFormatter.parse(amountCtrl.text).toInt();
                        
                        final repo = ref.read(debtRepositoryProvider);
                        await repo.recordPayment(DebtPaymentsCompanion.insert(
                          id: drift.Value(const Uuid().v4()),
                          debtId: debt.id,
                          amount: amount,
                          date: DateTime.now(),
                          walletId: drift.Value(selectedWalletId),
                          projectId: drift.Value(selectedProjectId),
                        ));
                        
                        if (context.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor, 
                        foregroundColor: Colors.white, 
                        padding: const EdgeInsets.all(18), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
                        elevation: 0
                      ),
                      child: Text(context.tr('confirm_payment'), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLent = debt.type == 'lent';
    final isPaid = debt.status == 'paid';
    final color = isPaid ? AppColors.emerald : (isLent ? Theme.of(context).colorScheme.primary : Colors.amber);
    final remaining = debt.principalAmount - debt.amountPaid;
    final percent = debt.principalAmount > 0 
        ? (debt.amountPaid / debt.principalAmount).clamp(0.0, 1.0)
        : 0.0;

    String deadlineText = '';
    Color deadlineColor = isDark ? Colors.white38 : AppColors.textMuted;
    
    if (!isPaid && debt.dueDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final due = DateTime(debt.dueDate!.year, debt.dueDate!.month, debt.dueDate!.day);
      final difference = due.difference(today).inDays;

      if (difference < 0) {
        final overdueDays = difference.abs();
        deadlineText = '${context.tr('overdue_label')} ($overdueDays ${context.tr("days")})';
        deadlineColor = AppColors.rose;
      } else if (difference == 0) {
        deadlineText = context.tr('due_today');
        deadlineColor = Colors.orange;
      } else {
        deadlineText = '$difference ${context.tr("days")} ${context.tr("left")}';
        if (difference <= 3) deadlineColor = Colors.orange;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isPaid ? Icons.check_circle_rounded : (isLent ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded),
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            debt.contactName.toUpperCase(),
                            style: AppTextStyles.bold.copyWith(fontSize: 14, letterSpacing: -0.2),
                          ),
                          Row(
                            children: [
                              Text(
                                isLent ? context.tr('lent_money') : context.tr('borrowed'),
                                style: TextStyle(
                                  color: isDark ? Colors.white24 : AppColors.textMuted,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (deadlineText.isNotEmpty) ...[
                                Container(width: 3, height: 3, margin: const EdgeInsets.symmetric(horizontal: 6), decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? Colors.white10 : Colors.grey[300])),
                                Text(
                                  deadlineText,
                                  style: TextStyle(color: deadlineColor, fontSize: 9, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isPaid 
                              ? 'TSh ${NumberFormat('#,###').format(debt.principalAmount)}'
                              : 'TSh ${NumberFormat('#,###').format(remaining)}',
                          style: TextStyle(
                            color: isPaid ? AppColors.emerald : AppColors.rose,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          (isPaid ? context.tr('paid_status') : '${context.tr('remaining')}').toUpperCase(),
                          style: TextStyle(
                            color: isPaid ? AppColors.emerald : AppColors.rose,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (!isPaid && debt.amountPaid > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${context.tr('paid_amount')}: ${NumberFormat('#,###').format(debt.amountPaid)}',
                              style: TextStyle(
                                color: AppColors.emerald,
                                fontSize: 7,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (!isPaid) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 6,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(3),
                              ),
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
                        ),
                      ),
                      const SizedBox(width: 16),
                      _ActionButtonSmall(
                        onTap: () => _markAsPaid(context, ref),
                        icon: Icons.check_rounded,
                        label: context.tr('mark_paid'),
                        color: AppColors.emerald,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _ActionButtonSmall(
                        onTap: () => _showPaymentSheet(context, ref),
                        icon: Icons.add_rounded,
                        label: context.tr('pay_now'),
                        color: color,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => context.push('/debt-details', extra: debt),
                  icon: const Icon(Icons.info_outline_rounded, size: 14),
                  label: Text(context.tr('details').toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                  style: TextButton.styleFrom(foregroundColor: isDark ? Colors.white24 : Colors.grey),
                ),
                Opacity(
                  opacity: 0.5,
                  child: IconButton(
                    onPressed: () => _showDeleteConfirmation(context, ref),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0);
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${context.tr('delete')} ${debt.contactName}?'),
        content: Text(context.tr('delete_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              ref.read(debtRepositoryProvider).deleteDebt(debt.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
  }

  String _getDebtStatusLabel(BuildContext context, String status) {
    switch (status) {
      case 'paid': return context.tr('status_done');
      case 'pending': return context.tr('pending_label');
      default: return status;
    }
  }
}

class _ActionButtonSmall extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _ActionButtonSmall({
    required this.onTap, 
    required this.icon, 
    required this.label, 
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
