import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../providers/finance_providers.dart';
import '../../../projects/providers/projects_providers.dart';

import '../../../../core/localization/app_localizations.dart';

class AddDebtScreen extends ConsumerStatefulWidget {
  const AddDebtScreen({super.key});

  @override
  ConsumerState<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends ConsumerState<AddDebtScreen> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _paidCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _type = 'lent'; // 'lent' or 'borrowed'
  DateTime _selectedDate = DateTime.now();
  DateTime? _dueDate;
  String? _selectedWalletId;
  String? _selectedProjectId;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _paidCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _type == 'lent' ? AppColors.indigo : Colors.amber;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('new_debt_record').toUpperCase(), 
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w900, 
            fontSize: 14, 
            letterSpacing: 1
          )
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeSelector(isDark),
            const SizedBox(height: 32),
            _ModernInput(
              controller: _nameCtrl, 
              hint: context.tr('person_name'), 
              icon: Icons.person_outline_rounded, 
              accentColor: accentColor
            ),
            const SizedBox(height: 16),
            _ModernInput(
              controller: _amountCtrl, 
              hint: context.tr('principal_amount'), 
              icon: Icons.payments_outlined, 
              accentColor: accentColor,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
            ),
            const SizedBox(height: 16),
            _buildSectionLabel(context.tr('wallet_label').toUpperCase(), accentColor),
            const SizedBox(height: 12),
            walletsAsync.when(
              data: (wallets) => DropdownButtonFormField<String>(
                value: _selectedWalletId,
                isDense: true,
                dropdownColor: isDark ? const Color(0xFF161B22) : Colors.white,
                hint: Text(context.tr('select_wallet'), style: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : Colors.grey)),
                items: wallets.map((w) => DropdownMenuItem(
                  value: w.id, 
                  child: Text(w.name, style: TextStyle(color: isDark ? Colors.white : Colors.black))
                )).toList(),
                onChanged: (val) => setState(() => _selectedWalletId = val),
                decoration: _inputDecoration(isDark, accentColor),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            _buildSectionLabel(context.tr('project_label').toUpperCase(), accentColor),
            const SizedBox(height: 12),
            ref.watch(allProjectsStreamProvider).when(
              data: (projects) => DropdownButtonFormField<String?>(
                value: _selectedProjectId,
                isDense: true,
                dropdownColor: isDark ? const Color(0xFF161B22) : Colors.white,
                hint: Text(context.tr('select_project'), style: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : Colors.grey)),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(context.tr('none'), style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
                  ),
                  ...projects.map((p) => DropdownMenuItem(
                    value: p.id, 
                    child: Text(p.name, style: TextStyle(color: isDark ? Colors.white : Colors.black))
                  )),
                ],
                onChanged: (val) => setState(() => _selectedProjectId = val),
                decoration: _inputDecoration(isDark, accentColor),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            _ModernInput(
              controller: _paidCtrl, 
              hint: '${context.tr('paid_amount')} (${context.tr('optional')})', 
              icon: Icons.check_circle_outline_rounded, 
              accentColor: AppColors.emerald,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDateTile(isDark, accentColor, isDueDate: false)),
                const SizedBox(width: 12),
                Expanded(child: _buildDateTile(isDark, accentColor, isDueDate: true)),
              ],
            ),
            const SizedBox(height: 16),
            _ModernInput(
              controller: _notesCtrl, 
              hint: context.tr('notes_optional'), 
              icon: Icons.notes_rounded, 
              accentColor: accentColor,
              maxLines: 3,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveDebt,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: Text(
                context.tr('save_debt_record').toUpperCase(), 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: color)),
    );
  }

  InputDecoration _inputDecoration(bool isDark, Color accentColor) {
    return InputDecoration(
      filled: true,
      fillColor: isDark ? const Color(0xFF161B22) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withValues(alpha: 0.5))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withValues(alpha: 0.5))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: accentColor, width: 2)),
    );
  }

  Widget _buildTypeSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          _TypeBtn(
            label: context.tr('lent_money'), 
            isSelected: _type == 'lent', 
            color: AppColors.indigo, 
            onTap: () => setState(() => _type = 'lent'),
            isDark: isDark,
          ),
          _TypeBtn(
            label: context.tr('borrowed').toUpperCase(), 
            isSelected: _type == 'borrowed', 
            color: Colors.amber,
            onTap: () => setState(() => _type = 'borrowed'),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildDateTile(bool isDark, Color accentColor, {required bool isDueDate}) {
    final title = isDueDate ? context.tr('deadline') : context.tr('date_given');
    final date = isDueDate ? _dueDate : _selectedDate;

    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context, 
          initialDate: date ?? DateTime.now(), 
          firstDate: DateTime(2020), 
          lastDate: DateTime(2030)
        );
        if (d != null) {
          setState(() {
            if (isDueDate) {
              _dueDate = d;
            } else {
              _selectedDate = d;
            }
          });
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title, 
              style: TextStyle(fontSize: 8, color: accentColor, fontWeight: FontWeight.w900, letterSpacing: 1)
            ),
            const SizedBox(height: 4),
            Text(
              date == null ? 'Set Date' : DateFormat('dd MMM, yyyy').format(date), 
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)
            ),
          ],
        ),
      ),
    );
  }

  void _saveDebt() async {
    if (_nameCtrl.text.isEmpty || _amountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('fill_required_fields'))),
      );
      return;
    }

    final repo = ref.read(debtRepositoryProvider);
    final amount = CurrencyInputFormatter.parse(_amountCtrl.text).toInt();
    final paidAmount = _paidCtrl.text.isEmpty ? 0 : CurrencyInputFormatter.parse(_paidCtrl.text).toInt();

    String status = 'pending';
    if (paidAmount >= amount) {
      status = 'paid';
    } else if (paidAmount > 0) {
      status = 'partial';
    }

    final debtId = const Uuid().v4();
    final companion = DebtsCompanion.insert(
      id: drift.Value(debtId),
      contactName: _nameCtrl.text,
      type: _type,
      principalAmount: amount,
      amountPaid: drift.Value(paidAmount),
      dateGiven: _selectedDate,
      dueDate: drift.Value(_dueDate),
      status: status,
      notes: drift.Value(_notesCtrl.text.isEmpty ? null : _notesCtrl.text),
      walletId: drift.Value(_selectedWalletId),
      projectId: drift.Value(_selectedProjectId),
    );

    try {
      await repo.addDebt(companion);
      
      // If there was an initial payment, record it in history
      if (paidAmount > 0) {
        await repo.recordPayment(DebtPaymentsCompanion.insert(
          id: drift.Value(const Uuid().v4()),
          debtId: debtId,
          amount: paidAmount,
          date: _selectedDate,
          walletId: drift.Value(_selectedWalletId),
        ), updateDebt: false); // Already updated amountPaid in addDebt
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _TypeBtn({
    required this.label, 
    required this.isSelected, 
    required this.color, 
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : (isDark ? Colors.white38 : AppColors.textMuted),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color accentColor;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  const _ModernInput({
    required this.controller, 
    required this.hint, 
    required this.icon, 
    required this.accentColor,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: accentColor, size: 20),
        filled: true,
        fillColor: isDark ? const Color(0xFF161B22) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), 
          borderSide: BorderSide(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withValues(alpha: 0.5))
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), 
          borderSide: BorderSide(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withValues(alpha: 0.5))
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), 
          borderSide: BorderSide(color: accentColor, width: 2)
        ),
      ),
    );
  }
}
