import 'package:intl/intl.dart';

class Formatters {
  /// Format database minor units (e.g. Paise/Cents) into a currency string
  static String formatCurrency(int amountInMinorUnits, String currencyCode, {bool showSign = false}) {
    final double amount = amountInMinorUnits / 100.0;
    final format = NumberFormat.currency(
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: 2,
    );
    
    final formatted = format.format(amount.abs());
    
    if (showSign) {
      if (amountInMinorUnits > 0) {
        return '+$formatted';
      } else if (amountInMinorUnits < 0) {
        return '-$formatted';
      }
    }
    
    // Add negative sign if standard positive representation but amount is negative
    if (amountInMinorUnits < 0 && !showSign) {
      return '-$formatted';
    }
    
    return formatted;
  }

  /// Format Date for headers (e.g., Today, Yesterday, or June 27, 2026)
  static String formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final compareDate = DateTime(date.year, date.month, date.day);

    if (compareDate == today) {
      return 'Today';
    } else if (compareDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }

  /// Simple standard date representation
  static String formatDateShort(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  static String _getCurrencySymbol(String code) {
    switch (code.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'AED':
        return 'د.إ';
      default:
        return '$code ';
    }
  }
}
