import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/database/app_database.dart';
import '../../providers/finance_providers.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/currency_formatter.dart';

class AddBudgetScreen extends ConsumerStatefulWidget {
  const AddBudgetScreen({super.key});

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  final _budgetNameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedPeriod = 'monthly';
  bool _rolloverEnabled = false;
  bool _isLoading = false;
  final List<_BudgetItemEntry> _items = [];

  @override
  void dispose() {
    _budgetNameController.dispose();
    _amountController.dispose();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(_BudgetItemEntry(
        nameController: TextEditingController(),
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  void _saveBudget() async {
    if (_budgetNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('please_enter_budget_name'))),
      );
      return;
    }

    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('please_enter_amount'))),
      );
      return;
    }

    setState(() => _isLoading = true);
    int totalAmount = (CurrencyInputFormatter.parse(_amountController.text) * 100).round();
    
    final companion = BudgetsCompanion.insert(
      id: drift.Value(const Uuid().v4()),
      name: drift.Value(_budgetNameController.text),
      period: _selectedPeriod,
      amount: totalAmount,
      rolloverEnabled: drift.Value(_rolloverEnabled),
    );

    try {
      final repo = ref.read(budgetRepositoryProvider);
      await repo.addBudget(companion);
      
      final budgetId = companion.id.value;
      for (var item in _items) {
        if (item.nameController.text.isNotEmpty) {
          await repo.addBudgetItem(BudgetItemsCompanion.insert(
            budgetId: budgetId,
            name: item.nameController.text,
            estimatedPrice: 0, // No longer using estimated price
          ));
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.tr('set_budget').toUpperCase(), 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1, color: isDark ? Colors.white : AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel(context.tr('budget_name')),
            const SizedBox(height: 12),
            TextField(
              controller: _budgetNameController,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: context.tr('e.g._monthly_shopping'),
                filled: true,
                fillColor: isDark ? const Color(0xFF161B22) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionLabel(context.tr('budget_period')),
            const SizedBox(height: 12),
            _buildPeriodSelector(),
            const SizedBox(height: 32),
            _buildSectionLabel(context.tr('amount_label')),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [CurrencyInputFormatter()],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              decoration: InputDecoration(
                prefixText: 'TSh ',
                hintText: '0',
                filled: true,
                fillColor: isDark ? const Color(0xFF161B22) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionLabel(context.tr('budget_items_list').toUpperCase()),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(context.tr('add_item')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.list_alt_rounded, color: isDark ? Colors.white24 : Colors.grey.withValues(alpha: 0.3)),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('no_items_desc'),
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white24 : Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _items[index].nameController,
                            decoration: InputDecoration(
                              hintText: context.tr('item_name'),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF161B22) : Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeItem(index),
                          icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.rose),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),
            SwitchListTile(
              title: Text(context.tr('enable_rollover'), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(context.tr('rollover_desc'), style: const TextStyle(fontSize: 11)),
              value: _rolloverEnabled,
              onChanged: (val) => setState(() => _rolloverEnabled = val),
              activeColor: AppColors.indigo,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveBudget,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    context.tr('save_budget').toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.emerald));
  }

  Widget _buildPeriodSelector() {
    final periods = ['daily', 'weekly', 'monthly', 'yearly'];
    return Row(
      children: periods.map((p) {
        final isSelected = _selectedPeriod == p;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPeriod = p),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.indigo : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? AppColors.indigo : Colors.grey.withValues(alpha: 0.3)),
              ),
              alignment: Alignment.center,
              child: Text(
                p.substring(0, 1).toUpperCase() + p.substring(1),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BudgetItemEntry {
  final TextEditingController nameController;

  _BudgetItemEntry({required this.nameController});

  void dispose() {
    nameController.dispose();
  }
}
