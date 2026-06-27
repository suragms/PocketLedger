import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/formatters.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(transactionsFilterProvider.notifier).update((state) {
      return state.copyWith(searchQuery: value);
    });
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const FilterBottomSheet(),
    );
  }

  Map<DateTime, List<TransactionEntity>> _groupTransactions(List<TransactionEntity> list) {
    final Map<DateTime, List<TransactionEntity>> grouped = {};
    for (var tx in list) {
      final dateOnly = DateTime(tx.transactionDate.year, tx.transactionDate.month, tx.transactionDate.day);
      if (!grouped.containsKey(dateOnly)) {
        grouped[dateOnly] = [];
      }
      grouped[dateOnly]!.add(tx);
    }
    return grouped;
  }

  int _calculateDailyTotal(List<TransactionEntity> transactions) {
    int total = 0;
    for (var tx in transactions) {
      if (tx.type == 'income') {
        total += tx.amount;
      } else {
        total -= tx.amount;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsListProvider);
    final filter = ref.watch(transactionsFilterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: filter.type != null || 
                  filter.categoryIds.isNotEmpty || 
                  filter.startDate != null ||
                  filter.minAmount != null ||
                  filter.maxAmount != null,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _openFilterSheet(context),
          )
        ],
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search note or category...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Active filter chips row
          _buildActiveFiltersRow(),

          // Transactions List
          Expanded(
            child: transactionsAsync.when(
              data: (transactionsList) {
                if (transactionsList.isEmpty) {
                  return _buildEmptyState(theme);
                }

                final grouped = _groupTransactions(transactionsList);
                final dates = grouped.keys.toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    final dayTxList = grouped[date]!;
                    final dailySubtotal = _calculateDailyTotal(dayTxList);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Date header with subtotal
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                Formatters.formatDateHeader(date),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                Formatters.formatCurrency(dailySubtotal, 'INR', showSign: true),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: dailySubtotal >= 0 
                                      ? AppTheme.primaryEmerald 
                                      : AppTheme.expenseAlert,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // List card containing that day's transactions
                        Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: dayTxList.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final tx = dayTxList[idx];
                              final isExpense = tx.type == 'expense';
                              final amountColor = isExpense ? AppTheme.expenseAlert : AppTheme.primaryEmerald;
                              final catColor = tx.category != null 
                                  ? Color(int.parse(tx.category!.colorHex)) 
                                  : Colors.grey;

                              return Dismissible(
                                key: Key(tx.id),
                                background: Container(
                                  color: AppTheme.primaryEmerald,
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 20),
                                  child: const Icon(Icons.edit, color: Colors.white),
                                ),
                                secondaryBackground: Container(
                                  color: AppTheme.expenseAlert,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                confirmDismiss: (direction) async {
                                  if (direction == DismissDirection.startToEnd) {
                                    // Swipe Right: Edit -> Navigate to detail
                                    await context.push('/transaction/${tx.id}');
                                    return false; // Prevent sliding out
                                  }
                                  return true; // Slide out on delete
                                },
                                onDismissed: (direction) async {
                                  if (direction == DismissDirection.endToStart) {
                                    // Swipe Left: Delete
                                    final backupTx = tx;
                                    try {
                                      await ref.read(transactionRepositoryProvider).deleteTransaction(tx.id);
                                      ref.read(transactionUpdateTriggerProvider.notifier).triggerUpdate();

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).clearSnackBars();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Transaction deleted'),
                                            action: SnackBarAction(
                                              label: 'UNDO',
                                              textColor: Colors.white,
                                              onPressed: () async {
                                                await ref.read(transactionRepositoryProvider).addTransaction(backupTx);
                                                ref.read(transactionUpdateTriggerProvider.notifier).triggerUpdate();
                                              },
                                            ),
                                            backgroundColor: Colors.black87,
                                          ),
                                        );
                                      }
                                    } catch (_) {}
                                  }
                                },
                                child: ListTile(
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
                                  subtitle: tx.note != null
                                      ? Text(
                                          tx.note!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12),
                                        )
                                      : null,
                                  trailing: Text(
                                    Formatters.formatCurrency(
                                      isExpense ? -tx.amount : tx.amount, 
                                      'INR', 
                                      showSign: true,
                                    ),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: amountColor,
                                    ),
                                  ),
                                  onTap: () => context.push('/transaction/${tx.id}'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading history: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Try clearing your filters or adding a new record.',
            style: TextStyle(color: AppTheme.textSlate),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersRow() {
    final filter = ref.watch(transactionsFilterProvider);
    final hasTypeFilter = filter.type != null;
    final hasCategoryFilter = filter.categoryIds.isNotEmpty;
    final hasDateFilter = filter.startDate != null;
    final hasMinAmtFilter = filter.minAmount != null;
    final hasMaxAmtFilter = filter.maxAmount != null;

    if (!hasTypeFilter && !hasCategoryFilter && !hasDateFilter && !hasMinAmtFilter && !hasMaxAmtFilter) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: [
          if (hasTypeFilter)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                label: Text(filter.type!.toUpperCase()),
                onDeleted: () {
                  ref.read(transactionsFilterProvider.notifier).update((state) {
                    return state.copyWith(clearType: true);
                  });
                },
              ),
            ),
          if (hasDateFilter)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                label: const Text('Filtered Date'),
                onDeleted: () {
                  ref.read(transactionsFilterProvider.notifier).update((state) {
                    return state.copyWith(clearDates: true);
                  });
                },
              ),
            ),
          if (hasCategoryFilter)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                label: Text('${filter.categoryIds.length} Categories'),
                onDeleted: () {
                  ref.read(transactionsFilterProvider.notifier).update((state) {
                    return state.copyWith(categoryIds: []);
                  });
                },
              ),
            ),
          if (hasMinAmtFilter || hasMaxAmtFilter)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                label: Text(
                  filter.minAmount != null && filter.maxAmount != null
                      ? '₹${filter.minAmount!.toStringAsFixed(0)} - ₹${filter.maxAmount!.toStringAsFixed(0)}'
                      : filter.minAmount != null
                          ? '≥ ₹${filter.minAmount!.toStringAsFixed(0)}'
                          : '≤ ₹${filter.maxAmount!.toStringAsFixed(0)}',
                ),
                onDeleted: () {
                  ref.read(transactionsFilterProvider.notifier).update((state) {
                    return state.copyWith(clearAmounts: true);
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  String? _tempType;
  final List<String> _tempCategoryIds = [];
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final currentFilter = ref.read(transactionsFilterProvider);
    _tempType = currentFilter.type;
    _tempCategoryIds.addAll(currentFilter.categoryIds);
    _tempStartDate = currentFilter.startDate;
    _tempEndDate = currentFilter.endDate;
    if (currentFilter.minAmount != null) {
      _minAmountController.text = currentFilter.minAmount!.toStringAsFixed(0);
    }
    if (currentFilter.maxAmount != null) {
      _maxAmountController.text = currentFilter.maxAmount!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _tempStartDate != null && _tempEndDate != null
          ? DateTimeRange(start: _tempStartDate!, end: _tempEndDate!)
          : null,
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
      setState(() {
        _tempStartDate = picked.start;
        _tempEndDate = picked.end;
      });
    }
  }

  void _applyFilters() {
    final minVal = double.tryParse(_minAmountController.text.trim());
    final maxVal = double.tryParse(_maxAmountController.text.trim());

    ref.read(transactionsFilterProvider.notifier).update((state) {
      return state.copyWith(
        type: _tempType,
        categoryIds: _tempCategoryIds,
        startDate: _tempStartDate,
        endDate: _tempEndDate,
        minAmount: minVal,
        maxAmount: maxVal,
        clearType: _tempType == null,
        clearDates: _tempStartDate == null,
        clearAmounts: minVal == null && maxVal == null,
      );
    });
    Navigator.pop(context);
  }

  void _clearFilters() {
    ref.read(transactionsFilterProvider.notifier).update((state) {
      return const TransactionsFilter();
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider(null));

    return Container(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filters', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const Divider(height: 24),

            // Date Range selection
            const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _selectDateRange,
              icon: const Icon(Icons.date_range, color: AppTheme.primaryEmerald),
              label: Text(
                _tempStartDate != null && _tempEndDate != null
                    ? '${Formatters.formatDateShort(_tempStartDate!)} - ${Formatters.formatDateShort(_tempEndDate!)}'
                    : 'Select Date Range',
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              ),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              ),
            ),
            const SizedBox(height: 20),

            // Transaction Type
            const Text('Transaction Type', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<String?>(
              segments: const [
                ButtonSegment(value: null, label: Text('All')),
                ButtonSegment(value: 'expense', label: Text('Expense')),
                ButtonSegment(value: 'income', label: Text('Income')),
              ],
              selected: {_tempType},
              onSelectionChanged: (val) {
                setState(() {
                  _tempType = val.first;
                });
              },
            ),
            const SizedBox(height: 20),

            // Amount Range selection
            const Text('Amount Range (₹)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minAmountController,
                    decoration: const InputDecoration(
                      hintText: 'Min (e.g. 100)',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxAmountController,
                    decoration: const InputDecoration(
                      hintText: 'Max (e.g. 5000)',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Category Multi-select
            const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            categoriesAsync.when(
              data: (categories) {
                return SizedBox(
                  height: 100,
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: categories.map((cat) {
                        final isSelected = _tempCategoryIds.contains(cat.id);
                        final color = Color(int.parse(cat.colorHex));
                        return FilterChip(
                          label: Text(cat.name),
                          selected: isSelected,
                          selectedColor: color.withValues(alpha: 0.2),
                          checkmarkColor: color,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _tempCategoryIds.add(cat.id);
                              } else {
                                _tempCategoryIds.remove(cat.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error categories: $err'),
            ),
            const SizedBox(height: 24),

            // CTA Action Buttons
            ElevatedButton(
              onPressed: _applyFilters,
              child: const Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
