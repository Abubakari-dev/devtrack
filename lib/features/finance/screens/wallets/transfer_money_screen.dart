import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../providers/finance_providers.dart';

class TransferMoneyScreen extends ConsumerStatefulWidget {
  const TransferMoneyScreen({super.key});

  @override
  ConsumerState<TransferMoneyScreen> createState() => _TransferMoneyScreenState();
}

class _TransferMoneyScreenState extends ConsumerState<TransferMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _feeController = TextEditingController(text: '0');
  final _noteController = TextEditingController();
  
  Wallet? _fromWallet;
  Wallet? _toWallet;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _feeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _swapWallets() {
    setState(() {
      final temp = _fromWallet;
      _fromWallet = _toWallet;
      _toWallet = temp;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_fromWallet == null || _toWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('select_wallets_error'))),
      );
      return;
    }
    if (_fromWallet!.id == _toWallet!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('same_wallet_error'))),
      );
      return;
    }

    final amount = (CurrencyInputFormatter.parse(_amountController.text) * 100).round();
    final fee = (CurrencyInputFormatter.parse(_feeController.text) * 100).round();

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('amount_greater_than_zero'))),
      );
      return;
    }

    if (_fromWallet!.balance < (amount + fee)) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr('insufficient_balance')),
          content: Text('${_fromWallet!.name} has only ${CurrencyFormatter.formatScaled(_fromWallet!.balance)}. ${context.tr('proceed_anyway')}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.tr('cancel'))),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(context.tr('confirm'))),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(transferRepositoryProvider).performTransfer(
        fromWalletId: _fromWallet!.id,
        toWalletId: _toWallet!.id,
        amount: amount,
        fee: fee,
        date: _selectedDate,
        note: _noteController.text,
      );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('transfer_successful')),
            backgroundColor: AppColors.emerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('error')}: $e'),
            backgroundColor: AppColors.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        title: Text(context.tr('transfer_money'), style: AppTextStyles.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: walletsAsync.when(
        data: (wallets) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildWalletSelector(
                        label: context.tr('from_wallet'),
                        selected: _fromWallet,
                        wallets: wallets,
                        onChanged: (w) => setState(() => _fromWallet = w),
                        isDark: isDark,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            const Expanded(child: Divider()),
                            IconButton.filledTonal(
                              onPressed: _swapWallets,
                              icon: const Icon(Icons.swap_vert_rounded, color: AppColors.indigo, size: 28),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.indigo.withOpacity(0.1),
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                      ),
                      _buildWalletSelector(
                        label: context.tr('to_wallet'),
                        selected: _toWallet,
                        wallets: wallets,
                        onChanged: (w) => setState(() => _toWallet = w),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(context.tr('details').toUpperCase(), style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted, letterSpacing: 1.5)),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _amountController,
                  label: context.tr('amount'),
                  icon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  validator: (v) => v == null || v.isEmpty ? context.tr('field_required') : null,
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _feeController,
                  label: context.tr('transfer_fee'),
                  icon: Icons.receipt_long_rounded,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: AppColors.indigo, size: 22),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr('transfer_date'), style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 10)),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDate),
                              style: AppTextStyles.semiBold.copyWith(fontSize: 15),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _noteController,
                  label: context.tr('note_optional_label'),
                  icon: Icons.notes_rounded,
                  isDark: isDark,
                ),
                const SizedBox(height: 48),
                GlowButton(
                  label: context.tr('complete_transfer'),
                  onTap: _submit,
                  loading: _isSubmitting,
                  icon: Icons.send_rounded,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildWalletSelector({
    required String label,
    required Wallet? selected,
    required List<Wallet> wallets,
    required Function(Wallet?) onChanged,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight.withOpacity(0.5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<Wallet>(
              value: selected,
              isExpanded: true,
              isDense: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              hint: Text(context.tr('select_wallet'), style: AppTextStyles.medium.copyWith(color: AppColors.textMuted)),
              items: wallets.map((w) => DropdownMenuItem(
                value: w,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(w.color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.account_balance_wallet_rounded, color: Color(w.color), size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(w.name, style: AppTextStyles.bold.copyWith(fontSize: 15), overflow: TextOverflow.ellipsis),
                          Text(CurrencyFormatter.formatScaled(w.balance), style: AppTextStyles.medium.copyWith(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: AppTextStyles.semiBold.copyWith(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.medium.copyWith(color: AppColors.textMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.indigo, size: 22),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight.withOpacity(0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.indigo, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.rose)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}
