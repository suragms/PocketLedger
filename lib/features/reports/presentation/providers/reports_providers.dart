import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

enum ReportsPeriodType { weekly, monthly, yearly }

final reportsPeriodTypeProvider = StateProvider<ReportsPeriodType>((ref) => ReportsPeriodType.monthly);

class PeriodData {
  final String label;
  final int income;
  final int expense;

  PeriodData({
    required this.label,
    required this.income,
    required this.expense,
  });
}

class ReportsData {
  final int totalIncome;
  final int totalExpense;
  final int netSavings;
  final double savingsRate;
  final List<PeriodData> trendData;
  final List<CategorySpendReport> categoryRankings;

  ReportsData({
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.savingsRate,
    required this.trendData,
    required this.categoryRankings,
  });
}

class CategorySpendReport {
  final String id;
  final String name;
  final String icon;
  final String colorHex;
  final int amount;
  final double percentage;

  CategorySpendReport({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.amount,
    required this.percentage,
  });
}

final reportsDataProvider = FutureProvider<ReportsData>((ref) async {
  final periodType = ref.watch(reportsPeriodTypeProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  ref.watch(transactionUpdateTriggerProvider); // Refresh when database updates

  if (authState.user == null) {
    return ReportsData(
      totalIncome: 0,
      totalExpense: 0,
      netSavings: 0,
      savingsRate: 0,
      trendData: [],
      categoryRankings: [],
    );
  }

  final now = DateTime.now();
  DateTime startDate;

  // Determine query range based on how far back we need trend data
  switch (periodType) {
    case ReportsPeriodType.weekly:
      // Last 4 weeks
      startDate = now.subtract(const Duration(days: 28));
      break;
    case ReportsPeriodType.monthly:
      // Last 6 months
      startDate = DateTime(now.year, now.month - 5, 1);
      break;
    case ReportsPeriodType.yearly:
      // Last 3 years
      startDate = DateTime(now.year - 2, 1, 1);
      break;
  }

  final transactions = await repo.getTransactions(
    userId: authState.user!.id,
    startDate: startDate,
    endDate: now,
  );

  // Compute totals
  int totalIncome = 0;
  int totalExpense = 0;
  final Map<String, CategorySpendReport> categoryMap = {};

  for (var tx in transactions) {
    if (tx.type == 'income') {
      totalIncome += tx.amount;
    } else {
      totalExpense += tx.amount;
      if (tx.category != null) {
        final cat = tx.category!;
        final existing = categoryMap[cat.id];
        final currentAmount = (existing?.amount ?? 0) + tx.amount;
        categoryMap[cat.id] = CategorySpendReport(
          id: cat.id,
          name: cat.name,
          icon: cat.icon,
          colorHex: cat.colorHex,
          amount: currentAmount,
          percentage: 0.0,
        );
      }
    }
  }

  // Update percentages
  final rankings = categoryMap.values.map((item) {
    final pct = totalExpense > 0 ? (item.amount / totalExpense) * 100 : 0.0;
    return CategorySpendReport(
      id: item.id,
      name: item.name,
      icon: item.icon,
      colorHex: item.colorHex,
      amount: item.amount,
      percentage: pct,
    );
  }).toList();
  rankings.sort((a, b) => b.amount.compareTo(a.amount));

  // Compute Trend data points
  final List<PeriodData> trend = [];

  if (periodType == ReportsPeriodType.weekly) {
    // Group by week (4 buckets)
    for (int i = 3; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: (i + 1) * 7));
      final weekEnd = now.subtract(Duration(days: i * 7));
      
      int inc = 0;
      int exp = 0;

      for (var tx in transactions) {
        if (tx.transactionDate.isAfter(weekStart) && tx.transactionDate.isBefore(weekEnd)) {
          if (tx.type == 'income') {
            inc += tx.amount;
          } else {
            exp += tx.amount;
          }
        }
      }

      trend.add(PeriodData(
        label: 'Wk ${4 - i}',
        income: inc,
        expense: exp,
      ));
    }
  } else if (periodType == ReportsPeriodType.monthly) {
    // Group by month (6 buckets)
    for (int i = 5; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month - i, 1);
      final monthLabel = DateFormat('MMM').format(targetDate);
      
      int inc = 0;
      int exp = 0;

      for (var tx in transactions) {
        if (tx.transactionDate.year == targetDate.year && tx.transactionDate.month == targetDate.month) {
          if (tx.type == 'income') {
            inc += tx.amount;
          } else {
            exp += tx.amount;
          }
        }
      }

      trend.add(PeriodData(
        label: monthLabel,
        income: inc,
        expense: exp,
      ));
    }
  } else {
    // Group by year (3 buckets)
    for (int i = 2; i >= 0; i--) {
      final targetYear = now.year - i;
      final yearLabel = targetYear.toString();

      int inc = 0;
      int exp = 0;

      for (var tx in transactions) {
        if (tx.transactionDate.year == targetYear) {
          if (tx.type == 'income') {
            inc += tx.amount;
          } else {
            exp += tx.amount;
          }
        }
      }

      trend.add(PeriodData(
        label: yearLabel,
        income: inc,
        expense: exp,
      ));
    }
  }

  final netSavings = totalIncome - totalExpense;
  final savingsRate = totalIncome > 0 ? (netSavings / totalIncome) * 100 : 0.0;

  return ReportsData(
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    netSavings: netSavings,
    savingsRate: savingsRate,
    trendData: trend,
    categoryRankings: rankings,
  );
});
