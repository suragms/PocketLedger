import '../entities/transaction_entity.dart';
import '../entities/category_entity.dart';

abstract class TransactionRepository {
  Future<List<TransactionEntity>> getTransactions({
    required String userId,
    String? type,
    List<String>? categoryIds,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  });

  Future<TransactionEntity?> getTransactionById(String id);

  Future<void> addTransaction(TransactionEntity transaction);

  Future<void> updateTransaction(TransactionEntity transaction);

  Future<void> deleteTransaction(String id);

  Future<List<CategoryEntity>> getCategories({required String userId, String? type});

  Future<void> addCategory(CategoryEntity category);

  Future<void> updateCategory(CategoryEntity category);

  Future<void> deleteCategory(String id);
}
