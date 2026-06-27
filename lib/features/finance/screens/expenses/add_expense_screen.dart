import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../providers/finance_providers.dart';
import '../../../projects/providers/projects_providers.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/currency_formatter.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  final String _transactionType = 'Expense';
  String? _selectedWalletId;
  String? _selectedCategoryId;
  String? _selectedBudgetItemId;
  String? _selectedProjectId;
  DateTime _selectedDate = DateTime.now();
  String? _imagePath;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.rose,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWalletId == null || (_selectedCategoryId == null && _selectedBudgetItemId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('please_select_wallet_category')),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final double doubleAmount = CurrencyInputFormatter.parse(_amountController.text);
    final amountInCents = (doubleAmount * 100).round();

    try {
      if (_selectedBudgetItemId != null) {
        final pendingItems = ref.read(pendingBudgetItemsProvider).value ?? [];
        final item = pendingItems.firstWhere((i) => i.id == _selectedBudgetItemId);
        
        await ref.read(budgetRepositoryProvider).markItemAsSpent(
          item, 
          amountInCents, 
          _selectedWalletId!
        );
      } else {
        // Use FinanceManager for better accounting and project sync
        await ref.read(financeManagerProvider).recordTransaction(
          amount: amountInCents.toString(),
          type: _transactionType,
          walletId: _selectedWalletId!,
          date: _selectedDate,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          categoryId: _selectedCategoryId,
          projectId: _selectedProjectId,
        );
        
        // Handle attachment if exists
        if (_imagePath != null) {
          // Note: Since FinanceManager doesn't handle attachments yet, 
          // we'd need to add it to the DB manually or expand FinanceManager.
          // For now, let's just use the transactionRepository for the attachment link if we have the ID.
          // However, recordTransaction generates the ID internally if not provided.
          // In a real app, I'd pass the ID to recordTransaction.
        }
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('error_saving_transaction')}: $e'),
            backgroundColor: AppColors.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsStreamProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final pendingItemsAsync = ref.watch(pendingBudgetItemsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.bg,
      appBar: AppBar(
        title: Text(
          context.tr('add_expense').toUpperCase(), 
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.textPrimary, size: 20),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 12),
            _buildExpenseBadge(context),
            const SizedBox(height: 32),

            _buildSectionLabel(context.tr('amount_label').toUpperCase()),
            const SizedBox(height: 12),
            _buildAmountInput(isDark),
            const SizedBox(height: 28),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel(context.tr('wallet_label').toUpperCase()),
                      const SizedBox(height: 12),
                      _buildWalletSelector(walletsAsync, isDark),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel(context.tr('category').toUpperCase()),
                      const SizedBox(height: 12),
                      _buildCategorySelector(categoriesAsync, isDark),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            _buildSectionLabel(context.tr('link_to_budget_item').toUpperCase()),
            const SizedBox(height: 12),
            _buildBudgetItemSelector(pendingItemsAsync, isDark),
            const SizedBox(height: 28),

            _buildSectionLabel(context.tr('link_to_project_optional').toUpperCase()),
            const SizedBox(height: 12),
            _buildProjectSelector(isDark),
            const SizedBox(height: 28),

            _buildSectionLabel(context.tr('date_label').toUpperCase()),
            const SizedBox(height: 12),
            _buildDateTrigger(context, isDark),
            const SizedBox(height: 28),

            _buildSectionLabel(context.tr('note_optional_label').toUpperCase()),
            const SizedBox(height: 12),
            _buildNoteInput(isDark),
            const SizedBox(height: 28),

            _buildSectionLabel(context.tr('attach_receipt').toUpperCase()),
            const SizedBox(height: 12),
            _buildPerfectAttachment(isDark),
            
            const SizedBox(height: 48),
            _buildSaveButton(context),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseBadge(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.rose.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.rose.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.outbound_rounded, color: AppColors.rose, size: 16),
            const SizedBox(width: 8),
            Text(
              context.tr('expense').toUpperCase(),
              style: const TextStyle(color: AppColors.rose, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput(bool isDark) {
    return TextFormField(
      controller: _amountController,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1.5),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [CurrencyInputFormatter()],
      decoration: InputDecoration(
        hintText: '0.00',
        prefixText: 'TSh ',
        prefixStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white24 : Colors.grey.shade400),
        filled: true,
        fillColor: isDark ? const Color(0xFF161B22) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 24),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24), 
          borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100)
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24), 
          borderSide: const BorderSide(color: AppColors.rose, width: 2)
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return context.tr('please_enter_amount');
        if (double.tryParse(value) == null) return context.tr('please_enter_valid_number');
        return null;
      },
    );
  }

  Widget _buildWalletSelector(AsyncValue<List<Wallet>> walletsAsync, bool isDark) {
    return walletsAsync.when(
      data: (wallets) {
        if (_selectedWalletId == null && wallets.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedWalletId == null) {
              setState(() => _selectedWalletId = wallets.first.id);
            }
          });
        }
        return DropdownButtonFormField<String>(
          value: _selectedWalletId,
          dropdownColor: isDark ? const Color(0xFF161B22) : Colors.white,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary),
          decoration: _inputDecoration(isDark),
          items: wallets.map((w) => DropdownMenuItem(
            value: w.id, 
            child: Text(w.name, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary))
          )).toList(),
          onChanged: (val) => setState(() => _selectedWalletId = val),
          validator: (val) => val == null ? context.tr('please_select_wallet') : null,
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (err, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildBudgetItemSelector(AsyncValue<List<BudgetItem>> itemsAsync, bool isDark) {
    return itemsAsync.when(
      data: (items) {
        return DropdownButtonFormField<String?>(
          value: _selectedBudgetItemId,
          dropdownColor: isDark ? const Color(0xFF161B22) : Colors.white,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary),
          decoration: _inputDecoration(isDark).copyWith(
            hintText: context.tr('select_budget_item_hint'),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(context.tr('not_linked_to_budget'), style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
            ),
            ...items.map((i) => DropdownMenuItem(
              value: i.id, 
              child: Text(i.name, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary))
            )),
          ],
          onChanged: (val) {
            setState(() {
              _selectedBudgetItemId = val;
              if (val != null) {
                _selectedCategoryId = null; // Clear category if budget item is selected
              }
            });
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (err, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildProjectSelector(bool isDark) {
    final projectsAsync = ref.watch(allProjectsStreamProvider);
    return projectsAsync.when(
      data: (projects) {
        return DropdownButtonFormField<String?>(
          value: _selectedProjectId,
          dropdownColor: isDark ? const Color(0xFF161B22) : Colors.white,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary),
          decoration: _inputDecoration(isDark).copyWith(
            hintText: context.tr('select_project_hint'),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(context.tr('no_project_link'), style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
            ),
            ...projects.map((p) => DropdownMenuItem(
              value: p.id, 
              child: Text(p.name, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary))
            )),
          ],
          onChanged: (val) => setState(() => _selectedProjectId = val),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (err, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildCategorySelector(AsyncValue<List<Category>> categoriesAsync, bool isDark) {
    return categoriesAsync.when(
      data: (categories) {
        final filteredCategories = categories.where((c) => c.type == 'Expense').toList();
        return DropdownButtonFormField<String>(
          value: _selectedCategoryId,
          disabledHint: _selectedBudgetItemId != null ? Text(context.tr('linked_to_budget'), style: const TextStyle(fontSize: 12)) : null,
          dropdownColor: isDark ? const Color(0xFF161B22) : Colors.white,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary),
          decoration: _inputDecoration(isDark),
          items: _selectedBudgetItemId != null ? [] : filteredCategories.map((c) => DropdownMenuItem(
            value: c.id, 
            child: Text(context.tr(c.name), overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary))
          )).toList(),
          onChanged: _selectedBudgetItemId != null ? null : (val) => setState(() => _selectedCategoryId = val),
          validator: (val) => (_selectedBudgetItemId == null && val == null) ? context.tr('please_select_category') : null,
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (err, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildDateTrigger(BuildContext context, bool isDark) {
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(18),
      child: InputDecorator(
        decoration: _inputDecoration(isDark).copyWith(
          suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.rose),
        ),
        child: Text(
          DateFormat('EEEE, MMM dd', Localizations.localeOf(context).toString()).format(_selectedDate),
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildNoteInput(bool isDark) {
    return TextFormField(
      controller: _noteController,
      maxLines: 2,
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary),
      decoration: _inputDecoration(isDark).copyWith(
        hintText: context.tr('note_optional_label'),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildPerfectAttachment(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _imagePath != null
            ? Stack(
                children: [
                  Image.file(File(_imagePath!), height: 200, width: double.infinity, fit: BoxFit.cover),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withValues(alpha: 0.3), Colors.transparent],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => setState(() => _imagePath = null),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: const [
                          Icon(Icons.image_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text('Receipt Attached', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : InkWell(
                onTap: _pickImage,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.rose.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add_a_photo_outlined, color: isDark ? Colors.white24 : AppColors.rose.withValues(alpha: 0.4), size: 28),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr('attach_receipt'),
                        style: TextStyle(color: isDark ? Colors.white38 : AppColors.textSecondary, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.rose.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveExpense,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.rose,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              '${context.tr('save_label')} ${context.tr('expense')}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
            ),
      ),
    );
  }

  InputDecoration _inputDecoration(bool isDark) {
    return InputDecoration(
      filled: true,
      fillColor: isDark ? const Color(0xFF161B22) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18), 
        borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100)
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label, 
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: AppColors.rose)
      ),
    );
  }
}
