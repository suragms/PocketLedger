import 'category_entity.dart';

class TransactionEntity {
  final String id;
  final String userId;
  final String type; // 'income' or 'expense'
  final int amount; // in minor units (paise/cents)
  final String categoryId;
  final CategoryEntity? category; // Joined entity
  final String? paymentMethod; // 'cash', 'card', 'upi', 'bank_transfer'
  final String? note;
  final String? receiptUrl;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.categoryId,
    this.category,
    this.paymentMethod,
    this.note,
    this.receiptUrl,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
  });

  TransactionEntity copyWith({
    String? id,
    String? userId,
    String? type,
    int? amount,
    String? categoryId,
    CategoryEntity? category,
    String? paymentMethod,
    String? note,
    String? receiptUrl,
    DateTime? transactionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
