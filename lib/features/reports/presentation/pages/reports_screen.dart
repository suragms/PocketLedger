import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../providers/reports_providers.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  Future<void> _exportCSV(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(transactionRepositoryProvider);
    final user = ref.read(authStateProvider).user;
    if (user == null) return;

    // Show Progress Indicator
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryEmerald),
      ),
    );

    try {
      final transactions = await repo.getTransactions(userId: user.id);
      
      final buffer = StringBuffer();
      buffer.writeln('ID,Type,Amount (INR),Category,Payment Method,Note,Date');
      
      for (var tx in transactions) {
        final type = tx.type;
        final amount = (tx.amount / 100.0).toStringAsFixed(2);
        final category = tx.category?.name ?? 'Uncategorized';
        final payment = tx.paymentMethod ?? '';
        final note = tx.note != null ? '"${tx.note!.replaceAll('"', '""')}"' : '';
        final date = tx.transactionDate.toIso8601String().split('T')[0];
        
        buffer.writeln('${tx.id},$type,$amount,$category,$payment,$note,$date');
      }
      
      final csvContent = buffer.toString();
      
      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: csvContent));
      
      // Save locally
      final folder = await getApplicationDocumentsDirectory();
      final file = File('${folder.path}/pocket_ledger_export.csv');
      await file.writeAsString(csvContent);
      
      // Dismiss Progress Indicator
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Trigger Native System Share
      await Share.shareXFiles([XFile(file.path)], text: 'PocketLedger CSV Ledger Export');
      
    } catch (e) {
      // Dismiss Progress Indicator
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV Export failed: $e'), backgroundColor: AppTheme.expenseAlert),
        );
      }
    }
  }

  Future<void> _exportPDF(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(transactionRepositoryProvider);
    final user = ref.read(authStateProvider).user;
    if (user == null) return;

    // Show Progress Indicator
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryEmerald),
      ),
    );

    try {
      final transactions = await repo.getTransactions(userId: user.id);
      final reportsData = await ref.read(reportsDataProvider.future);

      final buffer = StringBuffer();
      buffer.writeln('==================================================');
      buffer.writeln('             POCKETLEDGER LEDGER REPORT           ');
      buffer.writeln('==================================================');
      buffer.writeln('Generated: ${DateTime.now().toIso8601String().split('T')[0]}');
      buffer.writeln('User: ${user.fullName}');
      buffer.writeln('Email: ${user.email}');
      buffer.writeln('--------------------------------------------------');
      buffer.writeln('SUMMARY:');
      buffer.writeln('  Total Income:  ₹${(reportsData.totalIncome / 100.0).toStringAsFixed(2)}');
      buffer.writeln('  Total Expense:   ₹${(reportsData.totalExpense / 100.0).toStringAsFixed(2)}');
      buffer.writeln('  Net Savings:     ₹${(reportsData.netSavings / 100.0).toStringAsFixed(2)}');
      buffer.writeln('  Savings Rate:    ${reportsData.savingsRate.toStringAsFixed(1)}%');
      buffer.writeln('--------------------------------------------------');
      buffer.writeln('CATEGORY BREAKDOWN:');
      for (var rank in reportsData.categoryRankings) {
        buffer.writeln('  - ${rank.name.padRight(15)}: ₹${(rank.amount / 100.0).toStringAsFixed(2).padLeft(9)} (${rank.percentage.toStringAsFixed(1)}%)');
      }
      buffer.writeln('--------------------------------------------------');
      buffer.writeln('TRANSACTIONS LIST:');
      buffer.writeln('Date       | Type    | Category        | Amount (INR)');
      buffer.writeln('-----------|---------|-----------------|-------------');
      for (var tx in transactions) {
        final date = tx.transactionDate.toIso8601String().split('T')[0];
        final type = tx.type.padRight(7);
        final cat = (tx.category?.name ?? 'Uncategorized').padRight(15);
        final amt = (tx.amount / 100.0).toStringAsFixed(2).padLeft(11);
        buffer.writeln('$date | $type | $cat | ₹$amt');
      }
      buffer.writeln('==================================================');

      final reportText = buffer.toString();

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: reportText));

      // Save locally (simulated PDF export file)
      final folder = await getApplicationDocumentsDirectory();
      final file = File('${folder.path}/pocket_ledger_report.pdf');
      await file.writeAsString(reportText);

      // Dismiss Progress Indicator
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Trigger Native System Share
      await Share.shareXFiles([XFile(file.path)], text: 'PocketLedger PDF Ledger Report');

    } catch (e) {
      // Dismiss Progress Indicator
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF Export failed: $e'), backgroundColor: AppTheme.expenseAlert),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final periodType = ref.watch(reportsPeriodTypeProvider);
    final reportsAsync = ref.watch(reportsDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF Report',
            onPressed: () => _exportPDF(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: () => _exportCSV(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Period Selector
            SegmentedButton<ReportsPeriodType>(
              segments: const [
                ButtonSegment(value: ReportsPeriodType.weekly, label: Text('Weekly')),
                ButtonSegment(value: ReportsPeriodType.monthly, label: Text('Monthly')),
                ButtonSegment(value: ReportsPeriodType.yearly, label: Text('Yearly')),
              ],
              selected: {periodType},
              onSelectionChanged: (val) {
                ref.read(reportsPeriodTypeProvider.notifier).state = val.first;
              },
            ),
            const SizedBox(height: 20),

            reportsAsync.when(
              data: (data) {
                if (data.trendData.isEmpty) {
                  return _buildNoDataState(theme);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Savings rate summary card
                    _buildSavingsSummaryCard(theme, data),
                    const SizedBox(height: 24),

                    // Income vs Expense comparative chart
                    Text(
                      'Income vs Expense Trend (Bar Chart)',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildBarChartCard(theme, data),
                    const SizedBox(height: 24),

                    if (data.categoryRankings.isNotEmpty) ...[
                      // Category breakdown Pie Chart
                      Text(
                        'Expense Breakdown (Pie Chart)',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildCategoryPieChartCard(theme, data),
                      const SizedBox(height: 24),

                      // Categorized ranks list
                      Text(
                        'Spending by Category',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildCategoryRankingsCard(theme, data),
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading report: $err')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsSummaryCard(ThemeData theme, ReportsData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'NET SAVINGS FOR PERIOD',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSlate, letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),
            Text(
              Formatters.formatCurrency(data.netSavings, 'INR'),
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: data.netSavings >= 0 ? AppTheme.primaryEmerald : AppTheme.expenseAlert,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Total Savings Rate', style: TextStyle(fontSize: 10, color: AppTheme.textSlate)),
                    const SizedBox(height: 4),
                    Text(
                      '${data.savingsRate.toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryEmerald),
                    ),
                  ],
                ),
                Container(width: 1, height: 28, color: Colors.grey.shade300),
                Column(
                  children: [
                    const Text('Total Expense', style: TextStyle(fontSize: 10, color: AppTheme.textSlate)),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatCurrency(data.totalExpense, 'INR'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.expenseAlert),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard(ThemeData theme, ReportsData data) {
    final List<BarChartGroupData> groups = [];

    for (int i = 0; i < data.trendData.length; i++) {
      final point = data.trendData[i];
      final incDouble = point.income / 100.0;
      final expDouble = point.expense / 100.0;

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: incDouble,
              color: AppTheme.primaryEmerald,
              width: 8,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            BarChartRodData(
              toY: expDouble,
              color: AppTheme.expenseAlert,
              width: 8,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: groups,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < data.trendData.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 8,
                              child: Text(
                                data.trendData[idx].label,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(width: 12, height: 12, color: AppTheme.primaryEmerald),
                    const SizedBox(width: 6),
                    const Text('Income', style: TextStyle(fontSize: 11)),
                  ],
                ),
                const SizedBox(width: 24),
                Row(
                  children: [
                    Container(width: 12, height: 12, color: AppTheme.expenseAlert),
                    const SizedBox(width: 6),
                    const Text('Expenses', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPieChartCard(ThemeData theme, ReportsData data) {
    final List<PieChartSectionData> sections = [];
    for (int i = 0; i < data.categoryRankings.length; i++) {
      final rank = data.categoryRankings[i];
      final color = Color(int.parse(rank.colorHex));
      sections.add(
        PieChartSectionData(
          color: color,
          value: rank.amount.toDouble(),
          title: '${rank.percentage.toStringAsFixed(0)}%',
          radius: 40,
          titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          showTitle: rank.percentage > 5,
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 45,
              sections: sections,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRankingsCard(ThemeData theme, ReportsData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.categoryRankings.length,
          separatorBuilder: (context, index) => const Divider(height: 16),
          itemBuilder: (context, index) {
            final rank = data.categoryRankings[index];
            final color = Color(int.parse(rank.colorHex));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(
                        CategoryIcons.getIcon(rank.icon),
                        color: color,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rank.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.formatCurrency(rank.amount, 'INR'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${rank.percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSlate),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: rank.percentage / 100.0,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoDataState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64.0),
      child: Column(
        children: [
          const Icon(Icons.bar_chart, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Not enough transactions',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add some transactions to see visual analytics reports.',
            style: TextStyle(color: AppTheme.textSlate),
          ),
        ],
      ),
    );
  }
}
