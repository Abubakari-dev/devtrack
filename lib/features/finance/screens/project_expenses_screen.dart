import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/notification_service.dart';
import '../../projects/models/project_model.dart';
import '../../projects/data/project_repository.dart';
import '../data/finance_repository.dart';

class ProjectExpensesScreen extends StatefulWidget {
  final Project project;
  
  const ProjectExpensesScreen({super.key, required this.project});

  @override
  State<ProjectExpensesScreen> createState() => _ProjectExpensesScreenState();
}

class _ProjectExpensesScreenState extends State<ProjectExpensesScreen> {
  final FinanceRepository _financeRepo = FinanceRepository();
  final ProjectRepository _projectRepo = ProjectRepository();
  final NotificationService _notificationService = NotificationService.instance;

  @override
  void initState() {
    super.initState();
    _scheduleSavingsReminder();
  }

  void _scheduleSavingsReminder() async {
    final project = widget.project;
    final targetSavings = project.totalPrice * (project.savingsPercentage / 100);
    
    if (targetSavings > 0) {
      final reminderDate = DateTime.now().add(const Duration(days: 10));
      final notificationId = project.id.hashCode + 1000;
      
      await _notificationService.schedule(
        id: notificationId,
        title: '💰 Savings Reminder: ${project.name}',
        body: 'Remember to save TSh ${NumberFormat('#,###').format(targetSavings)} from this project!',
        when: reminderDate,
        payload: 'savings_reminder_${project.id}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return StreamBuilder<Project?>(
      stream: _projectRepo.getProjectStream(widget.project.id),
      initialData: widget.project,
      builder: (context, projectSnapshot) {
        final project = projectSnapshot.data ?? widget.project;
        
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.bg,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverHeader(context, project, isDark),
              SliverToBoxAdapter(
                child: StreamBuilder<List<Expense>>(
                  stream: _financeRepo.getExpensesForProject(project.id),
                  builder: (context, expenseSnapshot) {
                    final allExpenses = expenseSnapshot.data ?? [];
                    final totalExpenses = allExpenses.fold(0.0, (sum, exp) => sum + exp.amount);
                    final projectBudget = project.totalPrice;
                    final remaining = projectBudget - totalExpenses;
                    final budgetUsage = projectBudget > 0 ? (totalExpenses / projectBudget).clamp(0.0, 1.0) : 0.0;
                    
                    final targetSavings = projectBudget * (project.savingsPercentage / 100);
                    final budgetAfterSavings = projectBudget - targetSavings;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildBudgetCard(project, totalExpenses, projectBudget, remaining, budgetUsage, isDark),
                          const SizedBox(height: 16),
                          _buildInsightBanner(totalExpenses, budgetAfterSavings, projectBudget, budgetUsage, project.savingsPercentage, isDark),
                          const SizedBox(height: 32),
                          
                          _buildSectionHeader('FINANCIAL CONTROLS', isDark),
                          const SizedBox(height: 16),
                          _buildSavingsControl(project, isDark),
                          const SizedBox(height: 32),
                          
                          _buildSavingsTracker(project, targetSavings, isDark),
                          const SizedBox(height: 32),
                          
                          _buildSectionHeader('EXPENSE HISTORY', isDark),
                          const SizedBox(height: 16),
                          _buildExpenseList(allExpenses, isDark),
                          const SizedBox(height: 120),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showAddExpenseDialog,
            backgroundColor: AppColors.rose,
            elevation: 4,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('New Expense', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
          ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
        );
      },
    );
  }

  Widget _buildSliverHeader(BuildContext context, Project project, bool isDark) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Project Financial Management',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    project.projectColor,
                    project.projectColor.withBlue(150).withRed(100),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -30,
              top: -10,
              child: Opacity(
                opacity: 0.15,
                child: Text(project.projectEmoji, style: const TextStyle(fontSize: 180)),
              ),
            ),
            // Glassmorphism overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.4),
                  ],
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

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        color: isDark ? Colors.white38 : AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildBudgetCard(Project project, double totalExpenses, double projectBudget, double remaining, double budgetUsage, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5),
        ),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BudgetStat(label: 'TOTAL BUDGET', value: NumberFormat.compact().format(projectBudget), color: isDark ? Colors.white : Colors.black, isDark: isDark),
              _BudgetStat(label: 'EXPENSES', value: NumberFormat.compact().format(totalExpenses), color: AppColors.rose, isDark: isDark),
              _BudgetStat(label: remaining >= 0 ? 'AVAILABLE' : 'OVER', value: NumberFormat.compact().format(remaining.abs()), color: remaining >= 0 ? AppColors.emerald : AppColors.rose, isDark: isDark),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: budgetUsage,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: totalExpenses > projectBudget ? AppColors.rose : project.projectColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightBanner(double totalExpenses, double budgetAfterSavings, double projectBudget, double budgetUsage, double savingsPercent, bool isDark) {
    String insight = '';
    Color color = AppColors.emerald;
    IconData icon = Icons.check_circle_rounded;
    
    if (totalExpenses > budgetAfterSavings) {
      insight = 'Eating into savings! Expenses exceeded limit by TSh ${NumberFormat.compact().format(totalExpenses - budgetAfterSavings)}';
      color = AppColors.rose;
      icon = Icons.warning_amber_rounded;
    } else if (budgetUsage > 0.8) {
      insight = 'Budget almost depleted. ${(budgetUsage * 100).toInt()}% utilized.';
      color = AppColors.amber;
      icon = Icons.info_outline_rounded;
    } else {
      insight = 'Healthy budget maintenance. Project on track.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildSavingsControl(Project project, bool isDark) {
    return InkWell(
      onTap: () => _showSavingsSettingsDialog(project),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.emerald.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.percent_rounded, color: AppColors.emerald, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Savings Target', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  Text('Set budget allocation for savings', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 10)),
                ],
              ),
            ),
            Text('${project.savingsPercentage.toInt()}%', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.emerald, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsTracker(Project project, double targetSavings, bool isDark) {
    return StreamBuilder<List<SavingsRecord>>(
      stream: _financeRepo.getSavingsForProject(project.id),
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];
        final totalSaved = records.fold(0.0, (s, r) => s + r.amount);
        final progress = targetSavings > 0 ? (totalSaved / targetSavings).clamp(0.0, 1.0) : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('SAVINGS PERFORMANCE', isDark),
            const SizedBox(height: 16),
            Container(
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
                          const Text('TARGET', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey)),
                          Text('TSh ${NumberFormat.compact().format(targetSavings)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.emerald, fontSize: 20)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('ACCUMULATED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey)),
                          Text('TSh ${NumberFormat.compact().format(totalSaved)}', style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, fontSize: 20)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                    valueColor: const AlwaysStoppedAnimation(AppColors.emerald),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showRecordSavingsDialog(project, targetSavings),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('DEPOSIT TO SAVINGS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExpenseList(List<Expense> expenses, bool isDark) {
    if (expenses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text('No expense records found', style: TextStyle(color: isDark ? Colors.white24 : Colors.grey, fontWeight: FontWeight.w700)),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expenses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final exp = expenses[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.rose.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.receipt_long_rounded, color: AppColors.rose, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exp.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    Text(exp.category, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Text('TSh ${NumberFormat.compact().format(exp.amount)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.rose, fontSize: 15)),
            ],
          ),
        );
      },
    );
  }

  void _showAddExpenseDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String category = 'Materials';
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
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
                const Text('New Expenditure', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 32),
                _dialogField(nameCtrl, 'DESCRIPTION', Icons.label_outline_rounded, AppColors.rose, isDark),
                const SizedBox(height: 16),
                _dialogField(amountCtrl, 'AMOUNT', Icons.attach_money_rounded, AppColors.rose, isDark, isNumber: true),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;
                      final expense = Expense(id: const Uuid().v4(), projectId: widget.project.id, name: nameCtrl.text, amount: double.tryParse(amountCtrl.text) ?? 0, date: selectedDate, category: category);
                      await _financeRepo.recordExpense(expense);
                      if (mounted) Navigator.pop(sheetContext);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose, foregroundColor: Colors.white, padding: const EdgeInsets.all(18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
                    child: const Text('COMMIT EXPENSE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRecordSavingsDialog(Project project, double targetSavings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amountCtrl = TextEditingController();
    String selectedAccount = 'Bank Account';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
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
              const Text('Deposit Savings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 32),
              _dialogField(amountCtrl, 'AMOUNT TO SAVE', Icons.savings_outlined, AppColors.emerald, isDark, isNumber: true),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (amountCtrl.text.isEmpty) return;
                    final amount = double.tryParse(amountCtrl.text) ?? 0;
                    final savingsRecord = SavingsRecord(id: const Uuid().v4(), projectId: project.id, amount: amount, date: DateTime.now(), accountName: selectedAccount);
                    await _financeRepo.recordSavings(savingsRecord);
                    if (mounted) Navigator.pop(sheetContext);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald, foregroundColor: Colors.white, padding: const EdgeInsets.all(18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
                  child: const Text('CONFIRM DEPOSIT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSavingsSettingsDialog(Project project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final savingsCtrl = TextEditingController(text: project.savingsPercentage.toInt().toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Savings Goal', style: TextStyle(fontWeight: FontWeight.w900)),
        content: _dialogField(savingsCtrl, 'PERCENTAGE (%)', Icons.percent_rounded, AppColors.emerald, isDark, isNumber: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCEL', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontWeight: FontWeight.w900))),
          ElevatedButton(
            onPressed: () async {
              final percentage = double.tryParse(savingsCtrl.text) ?? 10.0;
              await _projectRepo.saveProject(project.copyWith(savingsPercentage: percentage.clamp(0, 100)));
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController c, String l, IconData i, Color color, bool isDark, {bool isNumber = false}) {
    return TextField(
      controller: c,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
      decoration: InputDecoration(
        labelText: l,
        labelStyle: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
        prefixIcon: Icon(i, color: color, size: 20),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: color, width: 2)),
      ),
    );
  }
}

class _BudgetStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _BudgetStat({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text('TSh $value', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: -0.5)),
      ],
    );
  }
}
