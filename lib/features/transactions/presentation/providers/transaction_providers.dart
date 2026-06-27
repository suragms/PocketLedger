import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../data/repositories/transaction_repository_impl.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TransactionRepositoryImpl(db);
});

class TransactionsFilter {
  final String? type; // 'income', 'expense' or null (All)
  final List<String> categoryIds;
  final DateTime? startDate;
  final DateTime? endDate;
  final String searchQuery;
  final double? minAmount;
  final double? maxAmount;

  const TransactionsFilter({
    this.type,
    this.categoryIds = const [],
    this.startDate,
    this.endDate,
    this.searchQuery = '',
    this.minAmount,
    this.maxAmount,
  });

  TransactionsFilter copyWith({
    String? type,
    List<String>? categoryIds,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    double? minAmount,
    double? maxAmount,
    bool clearType = false,
    bool clearDates = false,
    bool clearAmounts = false,
  }) {
    return TransactionsFilter(
      type: clearType ? null : (type ?? this.type),
      categoryIds: categoryIds ?? this.categoryIds,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      searchQuery: searchQuery ?? this.searchQuery,
      minAmount: clearAmounts ? null : (minAmount ?? this.minAmount),
      maxAmount: clearAmounts ? null : (maxAmount ?? this.maxAmount),
    );
  }
}

final transactionsFilterProvider = StateProvider<TransactionsFilter>((ref) {
  return const TransactionsFilter();
});

// A trigger notifier to force refresh futures when database modifications occur
final transactionUpdateTriggerProvider = StateNotifierProvider<TransactionUpdateTrigger, int>((ref) {
  return TransactionUpdateTrigger();
});

class TransactionUpdateTrigger extends StateNotifier<int> {
  TransactionUpdateTrigger() : super(0);
  
  void triggerUpdate() {
    state = state + 1;
  }
}

final transactionsListProvider = FutureProvider<List<TransactionEntity>>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final filter = ref.watch(transactionsFilterProvider);
  ref.watch(transactionUpdateTriggerProvider); // Re-run when incremented

  if (authState.user == null) return [];

  final list = await repo.getTransactions(
    userId: authState.user!.id,
    type: filter.type,
    categoryIds: filter.categoryIds,
    startDate: filter.startDate,
    endDate: filter.endDate,
    searchQuery: filter.searchQuery,
  );

  // Apply amount range filters in-memory
  if (filter.minAmount != null || filter.maxAmount != null) {
    return list.where((tx) {
      final val = tx.amount / 100.0;
      if (filter.minAmount != null && val < filter.minAmount!) return false;
      if (filter.maxAmount != null && val > filter.maxAmount!) return false;
      return true;
    }).toList();
  }

  return list;
});

final categoriesProvider = FutureProvider.family<List<CategoryEntity>, String?>((ref, type) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  ref.watch(transactionUpdateTriggerProvider); // Re-run when custom category is added

  if (authState.user == null) return [];

  return await repo.getCategories(userId: authState.user!.id, type: type);
});

final singleTransactionProvider = FutureProvider.family<TransactionEntity?, String>((ref, id) async {
  final repo = ref.watch(transactionRepositoryProvider);
  ref.watch(transactionUpdateTriggerProvider);
  return await repo.getTransactionById(id);
});
