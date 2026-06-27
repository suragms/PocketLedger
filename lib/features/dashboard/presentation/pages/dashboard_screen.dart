import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../transactions/presentation/widgets/add_transaction_sheet.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _selectCustomRange(BuildContext context, WidgetRef ref) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryEmerald,
              onPrimary: Colors.white,
              onSurface: AppTheme.textInk,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(dashboardCustomRangeProvider.notifier).state = picked;
      ref.read(dashboardPeriodProvider.notifier).state = DashboardPeriod.custom;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userState = ref.watch(authStateProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final period = ref.watch(dashboardPeriodProvider);
    final customRange = ref.watch(dashboardCustomRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'PocketLedger',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.brightness == Brightness.dark ? Colors.white : AppTheme.primaryDark,
              ),
            ),
            if (userState.user != null)
              Text(
                'Welcome, ${userState.user!.fullName}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
      ),
      body: summaryAsync.when(
        data: (summary) {
          final hasData = summary.recentTransactions.isNotEmpty;
          
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardTransactionsProvider);
            },
            color: AppTheme.primaryEmerald,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Period Selector Row
                  _buildPeriodSelector(context, ref, period, customRange),
                  const SizedBox(height: 20),

                  // Metrics Cards (Balance, Income, Expense, Net Savings)
                  _buildMetricsGrid(theme, summary),
                  const SizedBox(height: 24),

                  if (!hasData)
                    _buildEmptyState(context, theme)
                  else ...[
                    // Donut Chart Breakdown
                    if (summary.totalExpense > 0) ...[
                      Text(
                        'Expense Breakdown (Pie Chart)',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildDonutChartCard(theme, summary),
                      const SizedBox(height: 24),
                    ],

                    // Comparative Bar Chart Trend
                    Text(
                      'Cashflow Trend (Bar Chart)',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildBarChartCard(theme, summary),
                    const SizedBox(height: 24),

                    // Top categories ranked list
                    if (summary.categorySpends.isNotEmpty) ...[
                      Text(
                        'Top Expense Categories',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildTopCategoriesCard(theme, summary),
                      const SizedBox(height: 24),
                    ],

                    // Recent Transactions Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Transactions',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            context.go('/history');
                          },
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Recent transactions list
                    _buildRecentTransactionsList(theme, summary),
                    const SizedBox(height: 16),
                  ]
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading dashboard: $err')),
      ),
    );
  }

  Widget _buildPeriodSelector(
    BuildContext context, 
    WidgetRef ref, 
    DashboardPeriod currentPeriod,
    DateTimeRange? customRange,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<DashboardPeriod>(
          segments: const [
            ButtonSegment(value: DashboardPeriod.today, label: Text('Today')),
            ButtonSegment(value: DashboardPeriod.thisWeek, label: Text('Week')),
            ButtonSegment(value: DashboardPeriod.thisMonth, label: Text('Month')),
            ButtonSegment(value: DashboardPeriod.custom, label: Text('Custom')),
          ],
          selected: {currentPeriod},
          onSelectionChanged: (val) {
            if (val.first == DashboardPeriod.custom) {
              _selectCustomRange(context, ref);
            } else {
              ref.read(dashboardPeriodProvider.notifier).state = val.first;
            }
          },
        ),
        if (currentPeriod == DashboardPeriod.custom && customRange != null) ...[
          const SizedBox(height: 8),
          Center(
            child: Chip(
              label: Text(
                '${Formatters.formatDateShort(customRange.start)} - ${Formatters.formatDateShort(customRange.end)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              avatar: const Icon(Icons.date_range, size: 16, color: AppTheme.primaryEmerald),
              onDeleted: () {
                ref.read(dashboardPeriodProvider.notifier).state = DashboardPeriod.thisMonth;
              },
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildMetricsGrid(ThemeData theme, DashboardSummary summary) {
    final balanceColor = summary.balance >= 0 ? AppTheme.primaryEmerald : AppTheme.expenseAlert;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Total Balance Card
        Card(
          color: theme.brightness == Brightness.dark ? AppTheme.surfaceDark : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Text(
                  'TOTAL BALANCE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppTheme.textSlate,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  Formatters.formatCurrency(summary.balance, 'INR'),
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: balanceColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 2. Row of Income & Expense Cards
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppTheme.primaryLight,
                            child: Icon(Icons.arrow_downward, color: AppTheme.primaryDark, size: 14),
                          ),
                          SizedBox(width: 8),
                          Text('INCOME', style: TextStyle(fontSize: 10, color: AppTheme.textSlate, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        Formatters.formatCurrency(summary.totalIncome, 'INR'),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryEmerald),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.red.shade100,
                            child: const Icon(Icons.arrow_upward, color: AppTheme.expenseAlert, size: 14),
                          ),
                          const SizedBox(width: 8),
                          const Text('EXPENSES', style: TextStyle(fontSize: 10, color: AppTheme.textSlate, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        Formatters.formatCurrency(summary.totalExpense, 'INR'),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.expenseAlert),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 3. Net Savings & Savings Rate Card
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.savings_outlined, color: AppTheme.primaryEmerald, size: 20),
                    SizedBox(width: 8),
                    Text('Savings Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                Text(
                  '${summary.savingsRate.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryEmerald),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDonutChartCard(ThemeData theme, DashboardSummary summary) {
    final List<PieChartSectionData> sections = [];
    
    for (int i = 0; i < summary.categorySpends.length; i++) {
      final item = summary.categorySpends[i];
      final color = Color(int.parse(item.categoryColorHex));
      sections.add(
        PieChartSectionData(
          color: color,
          value: item.amount.toDouble(),
          title: '${item.percentage.toStringAsFixed(0)}%',
          radius: 36,
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          showTitle: item.percentage > 5,
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: sections,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Legend
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: summary.categorySpends.take(3).length, // Show top 3 in legend
              itemBuilder: (context, index) {
                final item = summary.categorySpends[index];
                final color = Color(int.parse(item.categoryColorHex));

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Icon(CategoryIcons.getIcon(item.categoryIcon), size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(item.categoryName, style: const TextStyle(fontSize: 12)),
                      const Spacer(),
                      Text(
                        Formatters.formatCurrency(item.amount, 'INR'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${item.percentage.toStringAsFixed(0)}%)',
                        style: const TextStyle(color: AppTheme.textSlate, fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard(ThemeData theme, DashboardSummary summary) {
    final List<BarChartGroupData> groups = [];

    for (int i = 0; i < summary.trendData.length; i++) {
      final point = summary.trendData[i];
      final incDouble = point.income / 100.0;
      final expDouble = point.expense / 100.0;

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: incDouble,
              color: AppTheme.primaryEmerald,
              width: 6,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
            ),
            BarChartRodData(
              toY: expDouble,
              color: AppTheme.expenseAlert,
              width: 6,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        child: Column(
          children: [
            SizedBox(
              height: 150,
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
                          if (idx >= 0 && idx < summary.trendData.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 8,
                              child: Text(
                                summary.trendData[idx].label,
                                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategoriesCard(ThemeData theme, DashboardSummary summary) {
    final list = summary.categorySpends.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (context, index) => const Divider(height: 16),
          itemBuilder: (context, index) {
            final item = list[index];
            final color = Color(int.parse(item.categoryColorHex));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(CategoryIcons.getIcon(item.categoryIcon), color: color, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Text(item.categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const Spacer(),
                    Text(
                      Formatters.formatCurrency(item.amount, 'INR'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.percentage / 100.0,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsList(ThemeData theme, DashboardSummary summary) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: summary.recentTransactions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final tx = summary.recentTransactions[index];
          final isExpense = tx.type == 'expense';
          final amountColor = isExpense ? AppTheme.expenseAlert : AppTheme.primaryEmerald;
          final catColor = tx.category != null ? Color(int.parse(tx.category!.colorHex)) : Colors.grey;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: catColor.withValues(alpha: 0.15),
              child: Icon(
                CategoryIcons.getIcon(tx.category?.icon ?? 'category'),
                color: catColor,
                size: 20,
              ),
            ),
            title: Text(
              tx.category?.name ?? 'Uncategorized',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              tx.note ?? Formatters.formatDateShort(tx.transactionDate),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Text(
              Formatters.formatCurrency(isExpense ? -tx.amount : tx.amount, 'INR', showSign: true),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
            onTap: () => context.push('/transaction/${tx.id}'),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48.0),
      child: Column(
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Track your daily income and expenses.',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Get started by adding your first transaction.',
            style: TextStyle(color: AppTheme.textSlate),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AddTransactionSheet(),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Transaction'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(200, 52),
            ),
          ),
        ],
      ),
    );
  }
}
