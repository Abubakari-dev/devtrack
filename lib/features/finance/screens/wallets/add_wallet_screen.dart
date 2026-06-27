import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/database/app_database.dart';
import '../../providers/finance_providers.dart';
import '../../../../core/utils/currency_formatter.dart';

import '../../../../core/localization/app_localizations.dart';

class AddWalletScreen extends ConsumerStatefulWidget {
  const AddWalletScreen({super.key});

  @override
  ConsumerState<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends ConsumerState<AddWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _accountController = TextEditingController();
  final _balanceController = TextEditingController();
  String _selectedType = 'Bank Account';
  String? _selectedProvider;
  bool _isLoading = false;

  List<String> _getTypes(BuildContext context) => [
    context.tr('bank_account'), 
    context.tr('mobile_money'), 
    context.tr('cash_label'), 
    context.tr('savings_label'), 
    context.tr('investment_label')
  ];
  
  final Map<String, List<String>> _providers = {
    'Bank Account': ['CRDB', 'NMB', 'NBC', 'Equity', 'Standard Chartered', 'Absa', 'Other Bank'],
    'Mobile Money': ['M-Pesa', 'Airtel Money', 'Tigo Pesa', 'Halopesa', 'Azam Pesa'],
  };

  Color _getProviderColor() {
    if (_selectedProvider == null) return AppColors.indigo;
    switch (_selectedProvider) {
      case 'CRDB': return const Color(0xFF006838);
      case 'NMB': return const Color(0xFF005AAB);
      case 'NBC': return const Color(0xFFE31E24);
      case 'Equity': return const Color(0xFF8B2332);
      case 'M-Pesa': return const Color(0xFFE31E24);
      case 'Airtel Money': return const Color(0xFFFF0000);
      case 'Tigo Pesa': return const Color(0xFF003399);
      case 'Halopesa': return const Color(0xFFFF6600);
      case 'Azam Pesa': return const Color(0xFF00ADEF);
      default: return AppColors.indigo;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _saveWallet() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final walletId = const Uuid().v4();
    final balance = (CurrencyInputFormatter.parse(_balanceController.text) * 100).round();

    final wallet = WalletsCompanion.insert(
      id: drift.Value(walletId),
      name: _nameController.text.trim(),
      type: _selectedType,
      provider: drift.Value(_selectedProvider),
      accountNumber: drift.Value(_accountController.text.trim()),
      balance: drift.Value(balance),
      currency: const drift.Value('TSh'),
      icon: _selectedType == 'Bank Account' ? 'account_balance_rounded' : 'phone_android_rounded',
      color: _getProviderColor().value,
    );
    try {
      await ref.read(walletRepositoryProvider).addWallet(wallet);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rose));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawTypes = ['Bank Account', 'Mobile Money', 'Cash', 'Savings', 'Investment'];
    final types = _getTypes(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(context.tr('new_wallet'), style: AppTextStyles.h2),
        centerTitle: true,
        backgroundColor: AppColors.bg,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPreviewCard(context),
              const SizedBox(height: 40),
              Text(context.tr('wallet_identity'), style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.5)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: _buildInputDecoration(context.tr('wallet_type'), Icons.category_rounded),
                items: List.generate(types.length, (i) => DropdownMenuItem(value: rawTypes[i], child: Text(types[i], style: AppTextStyles.medium))),
                onChanged: (v) => setState(() { _selectedType = v!; _selectedProvider = null; }),
              ),
              const SizedBox(height: 20),
              if (_providers.containsKey(_selectedType)) ...[
                DropdownButtonFormField<String>(
                  value: _selectedProvider,
                  decoration: _buildInputDecoration(_selectedType == 'Bank Account' ? context.tr('select_bank') : context.tr('select_provider'), Icons.business_center_rounded),
                  items: _providers[_selectedType]!.map((p) => DropdownMenuItem(value: p, child: Text(p, style: AppTextStyles.medium))).toList(),
                  onChanged: (v) => setState(() => _selectedProvider = v!),
                  validator: (v) => v == null ? context.tr('please_select_provider') : null,
                ),
                const SizedBox(height: 20),
              ],
              TextFormField(
                controller: _nameController,
                style: AppTextStyles.semiBold,
                decoration: _buildInputDecoration(context.tr('display_name_hint'), Icons.badge_rounded),
                validator: (v) => v == null || v.isEmpty ? context.tr('please_enter_name') : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _balanceController,
                style: AppTextStyles.semiBold,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [CurrencyInputFormatter()],
                decoration: _buildInputDecoration(context.tr('current_balance'), Icons.account_balance_wallet_rounded),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              if (_selectedType == 'Bank Account' || _selectedType == 'Mobile Money')
                TextFormField(
                  controller: _accountController,
                  style: AppTextStyles.semiBold,
                  keyboardType: _selectedType == 'Mobile Money' ? TextInputType.phone : TextInputType.number,
                  decoration: _buildInputDecoration(_selectedType == 'Bank Account' ? context.tr('account_number') : context.tr('phone_number'), Icons.numbers_rounded),
                  validator: (v) => v == null || v.isEmpty ? context.tr('field_required') : null,
                  onChanged: (_) => setState(() {}),
                ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity, height: 64,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveWallet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(context.tr('create_wallet_btn'), style: AppTextStyles.semiBold.copyWith(color: Colors.white, letterSpacing: 1.2, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context) {
    final cardColor = _getProviderColor();
    return Container(
      width: double.infinity, height: 220,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: cardColor.withValues(alpha: 0.3), blurRadius: 25, offset: const Offset(0, 12))],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedProvider?.toUpperCase() ?? _getTranslatedType(context, _selectedType).toUpperCase(), 
                          style: AppTextStyles.semiBold.copyWith(color: Colors.white, fontSize: 18, fontStyle: FontStyle.italic)),
                        Text(_getTranslatedType(context, _selectedType).toUpperCase(), style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                      ],
                    ),
                    const Icon(Icons.contactless_outlined, color: Colors.white70, size: 28),
                  ],
                ),
                const Spacer(),
                Text(_formatCardNumber(_accountController.text), style: AppTextStyles.semiBold.copyWith(color: Colors.white, fontSize: 20, letterSpacing: 2)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr('wallet_holder'), style: AppTextStyles.labelSmall.copyWith(color: Colors.white60, fontSize: 8)),
                          Text(_nameController.text.isEmpty ? context.tr('your_name') : _nameController.text.toUpperCase(),
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.medium.copyWith(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(context.tr('balance_label').toUpperCase(), style: AppTextStyles.labelSmall.copyWith(color: Colors.white60, fontSize: 8)),
                        Text(CurrencyFormatter.format(CurrencyInputFormatter.parse(_balanceController.text), symbol: 'TSh '), 
                          style: AppTextStyles.h3.copyWith(color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTranslatedType(BuildContext context, String type) {
    switch (type) {
      case 'Bank Account': return context.tr('bank_account');
      case 'Mobile Money': return context.tr('mobile_money');
      case 'Cash': return context.tr('cash_label');
      case 'Savings': return context.tr('savings_label');
      case 'Investment': return context.tr('investment_label');
      default: return type;
    }
  }

  String _formatCardNumber(String input) {
    if (input.isEmpty) return '**** **** **** ****';
    if (_selectedType == 'Mobile Money') return input;
    String cleaned = input.replaceAll(RegExp(r'\s+\b|\b\s+'), '');
    String formatted = '';
    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) formatted += ' ';
      formatted += cleaned[i];
    }
    return formatted.isEmpty ? '**** **** **** ****' : formatted;
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }
}
