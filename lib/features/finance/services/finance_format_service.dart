import 'package:intl/intl.dart';

class FinanceFormatService {
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
  final NumberFormat _compactFormat = NumberFormat.compactCurrency(symbol: r'$');

  String formatCurrency(int amountInCents) {
    return _currencyFormat.format(amountInCents / 100);
  }

  String formatCompactCurrency(int amountInCents) {
    return _compactFormat.format(amountInCents / 100);
  }

  String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  String formatTransactionType(String type) {
    return type.toUpperCase();
  }
}
