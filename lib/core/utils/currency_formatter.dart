import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(num amount, {String symbol = 'TSh '}) {
    return NumberFormat.currency(
      symbol: symbol,
      decimalDigits: amount % 1 == 0 ? 0 : 2,
    ).format(amount);
  }

  static String formatScaled(int amountInCents, {String symbol = 'TSh '}) {
    return format(amountInCents / 100.0, symbol: symbol);
  }

  static String compact(num amount, {String symbol = 'TSh '}) {
    return NumberFormat.compactCurrency(
      symbol: symbol,
      decimalDigits: 0,
    ).format(amount);
  }

  static String compactScaled(int amountInCents, {String symbol = 'TSh '}) {
    return compact(amountInCents / 100.0, symbol: symbol);
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###', 'en_US');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    // Remove any non-digit characters
    String cleanString = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanString.isEmpty) {
      return newValue.copyWith(text: '');
    }

    double value = double.parse(cleanString);
    String newText = _formatter.format(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  static double parse(String text) {
    return double.tryParse(text.replaceAll(',', '')) ?? 0;
  }
}
