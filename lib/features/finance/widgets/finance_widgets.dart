import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../projects/models/models.dart';

import 'package:devtrack/core/localization/app_localizations.dart';

class FinanceUtils {
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_TZ',
      symbol: 'TSh ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static String formatCompactCurrency(double amount) {
    if (amount >= 1000000) {
      return 'TSh ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'TSh ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return 'TSh ${amount.toStringAsFixed(0)}';
  }
}

class FinanceSummaryCard extends StatelessWidget {
  final double totalReceived;
  final double totalRemaining;
  final double totalPortfolio;
  final String filterLabel;

  const FinanceSummaryCard({
    super.key,
    required this.totalReceived,
    required this.totalRemaining,
    required this.totalPortfolio,
    this.filterLabel = 'All Time',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeTotalRemaining = totalRemaining.clamp(0.0, double.infinity);
    final double totalRevenue = totalPortfolio;
    final double collectionRate = totalRevenue > 0 ? totalReceived / totalRevenue : 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [AppColors.indigo.withValues(alpha: 0.8), const Color(0xFF1E293B)]
            : [AppColors.indigo, const Color(0xFF4F46E5)],
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo.withValues(alpha: 0.3),
            blurRadius: 25,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('total_revenue'), 
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6), 
                              fontSize: 10, 
                              fontWeight: FontWeight.w900, 
                              letterSpacing: 2
                            )
                          ),
                          const SizedBox(height: 8),
                          Text(
                            FinanceUtils.formatCurrency(totalRevenue), 
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 28, 
                              fontWeight: FontWeight.w900, 
                              letterSpacing: -1
                            )
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15), 
                          borderRadius: BorderRadius.circular(16)
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      _SummaryStat(
                        label: context.tr('collected'),
                        value: FinanceUtils.formatCompactCurrency(totalReceived),
                        color: Colors.white,
                        isDark: true,
                      ),
                      Container(
                        width: 1, 
                        height: 30, 
                        color: Colors.white.withValues(alpha: 0.1), 
                        margin: const EdgeInsets.symmetric(horizontal: 24)
                      ),
                      _SummaryStat(
                        label: context.tr('outstanding'),
                        value: safeTotalRemaining > 0 
                          ? FinanceUtils.formatCompactCurrency(safeTotalRemaining)
                          : 'TSh 0',
                        color: safeTotalRemaining > 0 ? const Color(0xFFFDA4AF) : const Color(0xFF6EE7B7),
                        isDark: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('collection_rate'), 
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7), 
                              fontSize: 12, 
                              fontWeight: FontWeight.w700
                            )
                          ),
                          Text(
                            '${(collectionRate * 100).toInt()}%', 
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 14, 
                              fontWeight: FontWeight.w900
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: collectionRate.clamp(0.0, 1.0),
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF818CF8), Colors.white],
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 0),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _SummaryStat({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label, 
            style: TextStyle(
              color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey, 
              fontSize: 9, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 1
            )
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class ProjectFinanceCard extends StatelessWidget {
  final Project project;
  final double projectTotal;
  final double actualPaidAmount;
  final VoidCallback onEdit;
  final VoidCallback? onExpensesTap;

  const ProjectFinanceCard({
    super.key,
    required this.project,
    required this.projectTotal,
    required this.actualPaidAmount,
    required this.onEdit,
    this.onExpensesTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remainingAmount = projectTotal - actualPaidAmount;
    final hasDue = remainingAmount > 10;
    final progress = projectTotal > 0 ? (actualPaidAmount / projectTotal).clamp(0.0, 1.0) : 0.0;
    final isFullyPaid = !hasDue && actualPaidAmount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isFullyPaid 
            ? AppColors.emerald.withValues(alpha: 0.3)
            : (isDark ? const Color(0xFF30363D) : AppColors.borderLight.withValues(alpha: 0.5)),
          width: isFullyPaid ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: project.projectColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        project.projectEmoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name, 
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black, 
                              fontWeight: FontWeight.w900, 
                              fontSize: 17, 
                              letterSpacing: -0.5
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.category_outlined, size: 12, color: isDark ? Colors.white38 : AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                project.getCategoryLabel(context),
                                style: TextStyle(
                                  color: isDark ? Colors.white38 : AppColors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (onExpensesTap != null)
                          _CardActionIcon(
                            icon: Icons.receipt_long_rounded,
                            color: AppColors.rose,
                            onTap: onExpensesTap!,
                            isDark: isDark,
                          ),
                        const SizedBox(width: 8),
                        _CardActionIcon(
                          icon: Icons.edit_rounded,
                          color: AppColors.indigo,
                          onTap: onEdit,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Progress Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('payment_status'),
                      style: TextStyle(
                        color: isDark ? Colors.white54 : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (isFullyPaid)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.emerald.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              context.tr('fully_paid').toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.emerald,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      height: 10,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              isFullyPaid ? AppColors.emerald : project.projectColor,
                              isFullyPaid ? AppColors.emerald.withValues(alpha: 0.6) : project.projectColor.withValues(alpha: 0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: (isFullyPaid ? AppColors.emerald : project.projectColor).withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Bottom Stats Row
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _FinanceItem(
                  label: context.tr('contract'), 
                  value: FinanceUtils.formatCompactCurrency(projectTotal), 
                  color: isDark ? Colors.white70 : Colors.black87, 
                  isDark: isDark
                ),
                _FinanceItem(
                  label: context.tr('received'), 
                  value: FinanceUtils.formatCompactCurrency(actualPaidAmount), 
                  color: AppColors.emerald, 
                  isDark: isDark
                ),
                _FinanceItem(
                  label: hasDue ? context.tr('outstanding') : context.tr('status_label'), 
                  value: hasDue 
                    ? FinanceUtils.formatCompactCurrency(remainingAmount)
                    : context.tr('settled'),
                  color: hasDue ? AppColors.rose : AppColors.emerald, 
                  isDark: isDark,
                  alignRight: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _CardActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _FinanceItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final bool alignRight;

  const _FinanceItem({
    required this.label, 
    required this.value, 
    required this.color, 
    required this.isDark,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: TextStyle(
            color: isDark ? Colors.white24 : Colors.grey.shade500, 
            fontSize: 8, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 1
          )
        ),
        const SizedBox(height: 4),
        Text(
          value, 
          style: TextStyle(
            color: color, 
            fontWeight: FontWeight.w900, 
            fontSize: 14,
            letterSpacing: -0.2,
          )
        ),
      ],
    );
  }
}
