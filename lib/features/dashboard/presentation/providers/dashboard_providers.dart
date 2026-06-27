import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

enum DashboardPeriod { today, thisWeek, thisMonth, custom }

final dashboardPeriodProvider = StateProvider<DashboardPeriod>((ref) => DashboardPeriod.thisMonth);

final dashboardCustomRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

final dashboardTransactionsProvider = FutureProvider<List<TransactionEntity>>((ref) async {
  final period = ref.watch(dashboardPeriodProvider);
  final customRange = ref.watch(dashboardCustomRangeProvider);
  final repo = ref.watch(transactionRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  ref.watch(transactionUpdateTriggerProvider); // Refresh when transaction updates

  if (authState.user == null) return [];

  final now = DateTime.now();
  DateTime startDate;
  DateTime endDate = now;

  switch (period) {
    case DashboardPeriod.today:
      startDate = DateTime(now.year, now.month, now.day);
      break;
    case DashboardPeriod.thisWeek:
      final daysToSubtract = now.weekday - 1;
      startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));
      break;
    case DashboardPeriod.thisMonth:
      startDate = DateTime(now.year, now.month, 1);
      break;
    case DashboardPeriod.custom:
      if (customRange != null) {
        startDate = customRange.start;
        endDate = customRange.end;
      } else {
        startDate = DateTime(now.year, now.month, 1); // Fallback to this month
      }
      break;
  }

  return await repo.getTransactions(
    userId: authState.user!.id,
    startDate: startDate,
    endDate: endDate,
  );
});

class CategorySpend {
  final String categoryName;
  final String categoryColorHex;
  final String categoryIcon;
  final int amount;
  final double percentage;

  CategorySpend({
    required this.categoryName,
    required this.categoryColorHex,
    required this.categoryIcon,
    required this.amount,
    required this.percentage,
  });
}

class DashboardPeriodData {
  final String label;
  final int income;
  final int expense;

  DashboardPeriodData({
    required this.label,
    required this.income,
    required this.expense,
  });
}

class DashboardSummary {
  final int totalIncome;
  final int totalExpense;
  final int balance;
  final int netSavings;
  final double savingsRate;
  final List<CategorySpend> categorySpends;
  final List<TransactionEntity> recentTransactions;
  final List<DashboardPeriodData> trendData;

  DashboardSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.netSavings,
    required this.savingsRate,
    required this.categorySpends,
    required this.recentTransactions,
    required this.trendData,
  });
}

final dashboardSummaryProvider = Provider<AsyncValue<DashboardSummary>>((ref) {
  final txsAsync = ref.watch(dashboardTransactionsProvider);
  final period = ref.watch(dashboardPeriodProvider);
  final customRange = ref.watch(dashboardCustomRangeProvider);

  return txsAsync.whenData((list) {
    int income = 0;
    int expense = 0;
    final Map<String, (String, String, String, int)> categoryMap = {};

    for (var tx in list) {
      if (tx.type == 'income') {
        income += tx.amount;
      } else {
        expense += tx.amount;
        if (tx.category != null) {
          final cat = tx.category!;
          final current = categoryMap[cat.id] ?? (cat.name, cat.colorHex, cat.icon, 0);
          categoryMap[cat.id] = (cat.name, cat.colorHex, cat.icon, current.$4 + tx.amount);
        }
      }
    }

    final categorySpends = categoryMap.entries.map((entry) {
      final val = entry.value;
      final pct = expense > 0 ? (val.$4 / expense) * 100 : 0.0;
      return CategorySpend(
        categoryName: val.$1,
        categoryColorHex: val.$2,
        categoryIcon: val.$3,
        amount: val.$4,
        percentage: pct,
      );
    }).toList();

    // Sort by amount descending
    categorySpends.sort((a, b) => b.amount.compareTo(a.amount));

    // Get 5 most recent transactions
    final recent = list.take(5).toList();

    // Compute trend points for dashboard bar chart
    final List<DashboardPeriodData> trend = [];
    final now = DateTime.now();
    
    DateTime startDate;
    DateTime endDate = now;

    switch (period) {
      case DashboardPeriod.today:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case DashboardPeriod.thisWeek:
        final daysToSubtract = now.weekday - 1;
        startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));
        break;
      case DashboardPeriod.thisMonth:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case DashboardPeriod.custom:
        if (customRange != null) {
          startDate = customRange.start;
          endDate = customRange.end;
        } else {
          startDate = DateTime(now.year, now.month, 1);
        }
        break;
    }

    if (period == DashboardPeriod.today) {
      trend.add(DashboardPeriodData(label: 'Today', income: income, expense: expense));
    } else if (period == DashboardPeriod.thisWeek) {
      for (int i = 6; i >= 0; i--) {
        final targetDate = now.subtract(Duration(days: i));
        final dayLabel = DateFormat('E').format(targetDate);
        int inc = 0;
        int exp = 0;
        for (var tx in list) {
          if (tx.transactionDate.year == targetDate.year &&
              tx.transactionDate.month == targetDate.month &&
              tx.transactionDate.day == targetDate.day) {
            if (tx.type == 'income') {
              inc += tx.amount;
            } else {
              exp += tx.amount;
            }
          }
        }
        trend.add(DashboardPeriodData(label: dayLabel, income: inc, expense: exp));
      }
    } else {
      // Group into 4 intervals
      final duration = endDate.difference(startDate);
      final intervalDays = (duration.inDays / 4).ceil();
      for (int i = 0; i < 4; i++) {
        final intervalStart = startDate.add(Duration(days: i * intervalDays));
        final intervalEnd = startDate.add(Duration(days: (i + 1) * intervalDays));
        final label = DateFormat('Md').format(intervalStart);
        int inc = 0;
        int exp = 0;
        for (var tx in list) {
          if (tx.transactionDate.isAfter(intervalStart.subtract(const Duration(seconds: 1))) &&
              tx.transactionDate.isBefore(intervalEnd.add(const Duration(seconds: 1)))) {
            if (tx.type == 'income') {
              inc += tx.amount;
            } else {
              exp += tx.amount;
            }
          }
        }
        trend.add(DashboardPeriodData(label: label, income: inc, expense: exp));
      }
    }

    final netSavings = income - expense;
    final savingsRate = income > 0 ? (netSavings / income) * 100 : 0.0;

    return DashboardSummary(
      totalIncome: income,
      totalExpense: expense,
      balance: netSavings, // Balance is netSavings (Income - Expense)
      netSavings: netSavings,
      savingsRate: savingsRate,
      categorySpends: categorySpends,
      recentTransactions: recent,
      trendData: trend,
    );
  });
});
