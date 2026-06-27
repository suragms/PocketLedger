import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final AppDatabase _db;

  TransactionRepositoryImpl(this._db);

  @override
  Future<List<TransactionEntity>> getTransactions({
    required String userId,
    String? type,
    List<String>? categoryIds,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) async {
    final query = _db.select(_db.transactions).join([
      leftOuterJoin(_db.categories, _db.categories.id.equalsExp(_db.transactions.categoryId)),
    ]);

    query.where(_db.transactions.userId.equals(userId));

    if (type != null) {
      query.where(_db.transactions.type.equals(type));
    }

    if (categoryIds != null && categoryIds.isNotEmpty) {
      query.where(_db.transactions.categoryId.isIn(categoryIds));
    }

    if (startDate != null) {
      query.where(_db.transactions.transactionDate.isBiggerOrEqualValue(startDate));
    }

    if (endDate != null) {
      query.where(_db.transactions.transactionDate.isSmallerOrEqualValue(endDate));
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      query.where(_db.transactions.note.like('%${searchQuery.trim()}%'));
    }

    query.orderBy([OrderingTerm.desc(_db.transactions.transactionDate)]);

    final rows = await query.get();

    return rows.map((row) {
      final transaction = row.readTable(_db.transactions);
      final category = row.readTableOrNull(_db.categories);

      CategoryEntity? catEntity;
      if (category != null) {
        catEntity = CategoryEntity(
          id: category.id,
          userId: category.userId,
          name: category.name,
          type: category.type,
          icon: category.icon,
          colorHex: category.colorHex,
          isDefault: category.isDefault,
          isArchived: category.isArchived,
          sortOrder: category.sortOrder,
        );
      }

      return TransactionEntity(
        id: transaction.id,
        userId: transaction.userId,
        type: transaction.type,
        amount: transaction.amount,
        categoryId: transaction.categoryId,
        category: catEntity,
        paymentMethod: transaction.paymentMethod,
        note: transaction.note,
        receiptUrl: transaction.receiptUrl,
        transactionDate: transaction.transactionDate,
        createdAt: transaction.createdAt,
        updatedAt: transaction.updatedAt,
      );
    }).toList();
  }

  @override
  Future<TransactionEntity?> getTransactionById(String id) async {
    final query = _db.select(_db.transactions).join([
      leftOuterJoin(_db.categories, _db.categories.id.equalsExp(_db.transactions.categoryId)),
    ]);
    query.where(_db.transactions.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    final transaction = row.readTable(_db.transactions);
    final category = row.readTableOrNull(_db.categories);

    CategoryEntity? catEntity;
    if (category != null) {
      catEntity = CategoryEntity(
        id: category.id,
        userId: category.userId,
        name: category.name,
        type: category.type,
        icon: category.icon,
        colorHex: category.colorHex,
        isDefault: category.isDefault,
        isArchived: category.isArchived,
        sortOrder: category.sortOrder,
      );
    }

    return TransactionEntity(
      id: transaction.id,
      userId: transaction.userId,
      type: transaction.type,
      amount: transaction.amount,
      categoryId: transaction.categoryId,
      category: catEntity,
      paymentMethod: transaction.paymentMethod,
      note: transaction.note,
      receiptUrl: transaction.receiptUrl,
      transactionDate: transaction.transactionDate,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
    );
  }

  @override
  Future<void> addTransaction(TransactionEntity transaction) async {
    final companion = TransactionsCompanion.insert(
      id: transaction.id,
      userId: transaction.userId,
      type: transaction.type,
      amount: transaction.amount,
      categoryId: transaction.categoryId,
      paymentMethod: Value(transaction.paymentMethod),
      note: Value(transaction.note),
      receiptUrl: Value(transaction.receiptUrl),
      transactionDate: transaction.transactionDate,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
    );
    await _db.into(_db.transactions).insert(companion);

    // Queue operation for offline sync
    await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion.insert(
        entityType: 'transaction',
        entityId: transaction.id,
        operation: 'create',
      ),
    );
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    final companion = TransactionsCompanion(
      type: Value(transaction.type),
      amount: Value(transaction.amount),
      categoryId: Value(transaction.categoryId),
      paymentMethod: Value(transaction.paymentMethod),
      note: Value(transaction.note),
      receiptUrl: Value(transaction.receiptUrl),
      transactionDate: Value(transaction.transactionDate),
      updatedAt: Value(DateTime.now()),
    );
    await (_db.update(_db.transactions)..where((t) => t.id.equals(transaction.id)))
        .write(companion);

    // Queue operation for offline sync
    await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion.insert(
        entityType: 'transaction',
        entityId: transaction.id,
        operation: 'update',
      ),
    );
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();

    // Queue operation for offline sync
    await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion.insert(
        entityType: 'transaction',
        entityId: id,
        operation: 'delete',
      ),
    );
  }

  @override
  Future<List<CategoryEntity>> getCategories({required String userId, String? type}) async {
    final query = _db.select(_db.categories)
      ..where((t) => t.userId.equals(userId) | t.userId.isNull())
      ..where((t) => t.isArchived.equals(false));

    if (type != null) {
      query.where((t) => t.type.equals(type));
    }

    query.orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.name)]);

    final rows = await query.get();

    return rows.map((row) => CategoryEntity(
      id: row.id,
      userId: row.userId,
      name: row.name,
      type: row.type,
      icon: row.icon,
      colorHex: row.colorHex,
      isDefault: row.isDefault,
      isArchived: row.isArchived,
      sortOrder: row.sortOrder,
    )).toList();
  }

  @override
  Future<void> addCategory(CategoryEntity category) async {
    final companion = CategoriesCompanion.insert(
      id: category.id,
      userId: Value(category.userId),
      name: category.name,
      type: category.type,
      icon: category.icon,
      colorHex: category.colorHex,
      isDefault: Value(category.isDefault),
      isArchived: Value(category.isArchived),
      sortOrder: Value(category.sortOrder),
    );
    await _db.into(_db.categories).insert(companion);

    // Queue operation for offline sync
    await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion.insert(
        entityType: 'category',
        entityId: category.id,
        operation: 'create',
      ),
    );
  }

  @override
  Future<void> updateCategory(CategoryEntity category) async {
    final companion = CategoriesCompanion(
      name: Value(category.name),
      icon: Value(category.icon),
      colorHex: Value(category.colorHex),
      isArchived: Value(category.isArchived),
      sortOrder: Value(category.sortOrder),
    );
    await (_db.update(_db.categories)..where((t) => t.id.equals(category.id)))
        .write(companion);

    // Queue operation for offline sync
    await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion.insert(
        entityType: 'category',
        entityId: category.id,
        operation: 'update',
      ),
    );
  }

  @override
  Future<void> deleteCategory(String id) async {
    // Soft delete category as required in Section 6.6.2 (FR-SET-04)
    await (_db.update(_db.categories)..where((t) => t.id.equals(id)))
        .write(const CategoriesCompanion(isArchived: Value(true)));

    // Queue operation for offline sync
    await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion.insert(
        entityType: 'category',
        entityId: id,
        operation: 'delete',
      ),
    );
  }
}
