import 'package:flutter/material.dart';
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
import '../../../../core/localization/app_localizations.dart';

class DebtDetailsScreen extends ConsumerWidget {
  final Debt debt;

  const DebtDetailsScreen({super.key, required this.debt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(debtPaymentsStreamProvider(debt.id));
    final remindersAsync = ref.watch(debtRemindersStreamProvider(debt.id));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLent = debt.type == 'lent';
    final accentColor = isLent ? AppColors.indigo : Colors.amber;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, isDark, accentColor),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(context, isDark, accentColor),
                _buildSectionHeader(context, context.tr('payment_history'), Icons.history_rounded),
                paymentsAsync.when(
                  data: (payments) {
                    if (payments.isEmpty) return _buildEmptyList(context, context.tr('no_payments_yet'), isDark);
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: payments.length,
                      itemBuilder: (context, index) => _PaymentListItem(payment: payments[index], isDark: isDark, color: accentColor),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
                _buildSectionHeader(context, context.tr('reminders'), Icons.notifications_active_outlined),
                remindersAsync.when(
                  data: (reminders) {
                    if (reminders.isEmpty) return _buildEmptyList(context, context.tr('no_active_reminders'), isDark);
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: reminders.length,
                      itemBuilder: (context, index) => _ReminderListItem(reminder: reminders[index], isDark: isDark),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: debt.status != 'paid' ? _buildBottomAction(context, ref, accentColor, isDark) : null,
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark, Color accentColor) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          debt.contactName,
          style: AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 20),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accentColor, accentColor.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, bool isDark, Color color) {
    final remaining = debt.principalAmount - debt.amountPaid;
    final formatter = NumberFormat('#,###');
    final isPaid = debt.status == 'paid';

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: color.withValues(alpha: 0.05),
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
              _InfoItem(label: context.tr('total_amount'), value: 'TSh ${formatter.format(debt.principalAmount)}', isDark: isDark),
              _InfoItem(label: context.tr('paid_amount'), value: 'TSh ${formatter.format(debt.amountPaid)}', isDark: isDark, color: AppColors.emerald),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (isPaid ? context.tr('total_paid') : context.tr('remaining_balance')).toUpperCase(), 
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : AppColors.textMuted, letterSpacing: 0.5)
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TSh ${formatter.format(isPaid ? debt.principalAmount : remaining)}', 
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: isPaid ? AppColors.emerald : color)
                    ),
                  ],
                ),
                _StatusBadge(status: debt.status, isDark: isDark),
              ],
            ),
          ),
          if (debt.dueDate != null) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.calendar_today_rounded, size: 14, color: isDark ? Colors.white54 : AppColors.textMuted),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('due_date').toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: isDark ? Colors.white38 : AppColors.textMuted)),
                    Text(
                      DateFormat('MMMM dd, yyyy').format(debt.dueDate!),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : AppColors.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.indigo),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyList(BuildContext context, String message, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400, fontSize: 13, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, WidgetRef ref, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : AppColors.bg,
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight)),
      ),
      child: ElevatedButton(
        onPressed: () => _showPaymentSheet(context, ref, isDark),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded),
            const SizedBox(width: 8),
            Text(context.tr('record_payment').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  void _showPaymentSheet(BuildContext context, WidgetRef ref, bool isDark) {
    final amountCtrl = TextEditingController();
    final accentColor = debt.type == 'lent' ? AppColors.indigo : Colors.amber;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
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
                context.tr('record_payment'), 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)
              ),
              const SizedBox(height: 32),
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
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: accentColor, width: 2)),
                ),
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
                      debtId: debt.id,
                      amount: amount,
                      date: DateTime.now(),
                    ));
                    
                    if (context.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor, 
                    foregroundColor: Colors.white, 
                    padding: const EdgeInsets.all(18), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
                  ),
                  child: Text(context.tr('confirm_payment'), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color? color;

  const _InfoItem({required this.label, required this.value, required this.isDark, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isDark ? Colors.white24 : AppColors.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color ?? (isDark ? Colors.white : AppColors.textPrimary))),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isDark;

  const _StatusBadge({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = status == 'paid' ? AppColors.emerald : (status == 'partial' ? AppColors.indigo : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    );
  }
}

class _PaymentListItem extends StatelessWidget {
  final DebtPayment payment;
  final bool isDark;
  final Color color;

  const _PaymentListItem({required this.payment, required this.isDark, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMMM dd, yyyy').format(payment.date),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              Text(
                DateFormat('hh:mm a').format(payment.date),
                style: TextStyle(color: isDark ? Colors.white24 : AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          Text(
            '+ TSh ${NumberFormat('#,###').format(payment.amount)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ReminderListItem extends StatelessWidget {
  final Reminder reminder;
  final bool isDark;

  const _ReminderListItem({required this.reminder, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM dd, yyyy @ hh:mm a').format(reminder.scheduledDate),
                style: TextStyle(color: AppColors.rose, fontWeight: FontWeight.w800, fontSize: 11),
              ),
              if (reminder.isRead)
                const Icon(Icons.check_circle_outline, size: 14, color: AppColors.emerald),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reminder.message,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
