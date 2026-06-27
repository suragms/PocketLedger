import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ledger/core/utils/formatters.dart';

void main() {
  group('Formatters Tests', () {
    test('Currency Formatter should format minor units to decimals with correct symbol', () {
      // 1000 paise = 10.00 INR
      expect(Formatters.formatCurrency(1000, 'INR'), '₹10.00');
      // Negative balance
      expect(Formatters.formatCurrency(-2500, 'INR'), '-₹25.00');
      // Show sign positive balance
      expect(Formatters.formatCurrency(1575, 'INR', showSign: true), '+₹15.75');
      // Other currency codes
      expect(Formatters.formatCurrency(500, 'USD'), '\$5.00');
      expect(Formatters.formatCurrency(1200, 'EUR'), '€12.00');
    });

    test('Date Header Formatter should return calendar descriptors', () {
      final now = DateTime.now();
      
      final today = DateTime(now.year, now.month, now.day, 14, 30);
      expect(Formatters.formatDateHeader(today), 'Today');

      final yesterday = today.subtract(const Duration(days: 1));
      expect(Formatters.formatDateHeader(yesterday), 'Yesterday');
    });
  });
}
