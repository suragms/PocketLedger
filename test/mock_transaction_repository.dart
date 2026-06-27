import 'package:pocket_ledger/features/transactions/domain/entities/category_entity.dart';
import 'package:pocket_ledger/features/transactions/domain/entities/transaction_entity.dart';
import 'package:pocket_ledger/features/transactions/domain/repositories/transaction_repository.dart';

class MockTransactionRepository implements TransactionRepository {
  final List<TransactionEntity> transactions = [];
  final List<CategoryEntity> categories = [];

  @override
  Future<void> addTransaction(TransactionEntity transaction) async {
    transactions.add(transaction);
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    final idx = transactions.indexWhere((t) => t.id == transaction.id);
    if (idx != -1) {
      transactions[idx] = transaction;
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    transactions.removeWhere((t) => t.id == id);
  }

  @override
  Future<List<TransactionEntity>> getTransactions({
    required String userId,
    String? type,
    List<String>? categoryIds,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) async {
    return transactions.where((t) {
      if (t.userId != userId) return false;
      if (type != null && t.type != type) return false;
      if (categoryIds != null && categoryIds.isNotEmpty && !categoryIds.contains(t.categoryId)) return false;
      if (startDate != null && t.transactionDate.isBefore(startDate)) return false;
      if (endDate != null && t.transactionDate.isAfter(endDate)) return false;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final note = t.note?.toLowerCase() ?? '';
        final catName = t.category?.name.toLowerCase() ?? '';
        if (!note.contains(searchQuery.toLowerCase()) && !catName.contains(searchQuery.toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Future<TransactionEntity?> getTransactionById(String id) async {
    final list = transactions.where((t) => t.id == id).toList();
    return list.isNotEmpty ? list.first : null;
  }

  @override
  Future<List<CategoryEntity>> getCategories({required String userId, String? type}) async {
    return categories.where((c) {
      if (c.userId != userId && c.userId != null) return false;
      if (type != null && c.type != type) return false;
      return true;
    }).toList();
  }

  @override
  Future<void> addCategory(CategoryEntity category) async {
    categories.add(category);
  }

  @override
  Future<void> updateCategory(CategoryEntity category) async {
    final idx = categories.indexWhere((c) => c.id == category.id);
    if (idx != -1) {
      categories[idx] = category;
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    categories.removeWhere((c) => c.id == id);
  }
}
