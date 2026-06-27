import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../providers/finance_providers.dart';

import 'package:devtrack/core/localization/app_localizations.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final String? initialWalletId;
  const AddTransactionScreen({super.key, this.initialWalletId});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  String _transactionType = 'Income'; 
  String? _selectedWalletId;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _selectedWalletId = widget.initialWalletId;
  }

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
              primary: _transactionType == 'Income' ? AppColors.emerald : AppColors.rose,
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

  void _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWalletId == null || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('please_select_wallet_category')),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final double doubleAmount = CurrencyInputFormatter.parse(_amountController.text);
    if (doubleAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('please_enter_amount')), backgroundColor: AppColors.rose),
      );
      return;
    }
    
    // Store as scaled integer (e.g. cents)
    final amountInCents = (doubleAmount * 100).round();
    
    final transaction = TransactionsCompanion.insert(
      amount: amountInCents,
      type: _transactionType,
      walletId: _selectedWalletId!,
      date: _selectedDate,
      note: drift.Value(_noteController.text.trim().isEmpty ? null : _noteController.text.trim()),
    );

    try {
      await ref.read(transactionRepositoryProvider).createSimpleTransaction(
        transaction: transaction,
        categoryId: _selectedCategoryId!,
        attachmentPath: _imagePath,
      );

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _transactionType == 'Income' ? AppColors.emerald : AppColors.rose;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.bg,
      appBar: AppBar(
        title: Text(
          (_transactionType == 'Income' ? context.tr('income') : context.tr('expense')).toUpperCase(), 
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
            _buildTypeToggle(context),
            const SizedBox(height: 32),

            _buildSectionLabel(context.tr('amount_label').toUpperCase(), accentColor),
            const SizedBox(height: 12),
            _buildAmountInput(isDark, accentColor),
            const SizedBox(height: 28),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel(context.tr('wallet_label').toUpperCase(), accentColor),
                      const SizedBox(height: 12),
                      _buildWalletSelector(walletsAsync, isDark, accentColor),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel(context.tr('category').toUpperCase(), accentColor),
                      const SizedBox(height: 12),
                      _buildCategorySelector(categoriesAsync, isDark, accentColor),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            _buildSectionLabel(context.tr('date_label').toUpperCase(), accentColor),
            const SizedBox(height: 12),
            _buildDateTrigger(context, isDark, accentColor),
            const SizedBox(height: 28),

            _buildSectionLabel(context.tr('note_optional_label').toUpperCase(), accentColor),
            const SizedBox(height: 12),
            _buildNoteInput(isDark, accentColor),
            const SizedBox(height: 28),

            _buildSectionLabel(context.tr('attach_receipt').toUpperCase(), accentColor),
            const SizedBox(height: 12),
            _buildPerfectAttachment(isDark, accentColor),
            
            const SizedBox(height: 48),
            _buildSaveButton(context, accentColor),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildToggleOption(context, 'Income', AppColors.emerald),
          _buildToggleOption(context, 'Expense', AppColors.rose),
        ],
      ),
    );
  }

  Widget _buildToggleOption(BuildContext context, String type, Color color) {
    final isSelected = _transactionType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _transactionType = type;
          _selectedCategoryId = null; // Reset category when type changes
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            context.tr(type.toLowerCase()).toUpperCase(),
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade500,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput(bool isDark, Color accentColor) {
    return TextFormField(
      controller: _amountController,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1.5),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [CurrencyInputFormatter()],
      decoration: InputDecoration(
        hintText: '0',
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
          borderSide: BorderSide(color: accentColor, width: 2)
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty || value == '0') return context.tr('please_enter_amount');
        return null;
      },
    );
  }

  Widget _buildWalletSelector(AsyncValue<List<Wallet>> walletsAsync, bool isDark, Color accentColor) {
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
          isDense: true,
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

  Widget _buildCategorySelector(AsyncValue<List<Category>> categoriesAsync, bool isDark, Color accentColor) {
    return categoriesAsync.when(
      data: (categories) {
        final filteredCategories = categories.where((c) => c.type == _transactionType).toList();
        
        // Auto-select first category if none selected
        if (_selectedCategoryId == null && filteredCategories.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedCategoryId == null) {
              setState(() => _selectedCategoryId = filteredCategories.first.id);
            }
          });
        }

        return DropdownButtonFormField<String>(
          value: _selectedCategoryId,
          isDense: true,
          dropdownColor: isDark ? const Color(0xFF161B22) : Colors.white,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary),
          decoration: _inputDecoration(isDark),
          items: filteredCategories.map((c) => DropdownMenuItem(
            value: c.id, 
            child: Text(context.tr(c.name), overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary))
          )).toList(),
          onChanged: (val) => setState(() => _selectedCategoryId = val),
          validator: (val) => val == null ? context.tr('please_select_category') : null,
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (err, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildDateTrigger(BuildContext context, bool isDark, Color accentColor) {
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(18),
      child: InputDecorator(
        decoration: _inputDecoration(isDark).copyWith(
          suffixIcon: Icon(Icons.calendar_today_rounded, size: 18, color: accentColor),
        ),
        child: Text(
          DateFormat('EEEE, MMM dd', Localizations.localeOf(context).toString()).format(_selectedDate),
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildNoteInput(bool isDark, Color accentColor) {
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

  Widget _buildPerfectAttachment(bool isDark, Color accentColor) {
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
                          color: accentColor.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add_a_photo_outlined, color: isDark ? Colors.white24 : accentColor.withValues(alpha: 0.4), size: 28),
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

  Widget _buildSaveButton(BuildContext context, Color accentColor) {
    return Container(
      height: 64,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: accentColor.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: ElevatedButton(
        onPressed: _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
        ),
        child: Text(
          context.tr('save_label').toUpperCase(),
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

  Widget _buildSectionLabel(String label, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label, 
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: accentColor)
      ),
    );
  }
}
