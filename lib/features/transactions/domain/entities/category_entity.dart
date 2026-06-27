class CategoryEntity {
  final String id;
  final String? userId;
  final String name;
  final String type; // 'income' or 'expense'
  final String icon;
  final String colorHex;
  final bool isDefault;
  final bool isArchived;
  final int sortOrder;

  CategoryEntity({
    required this.id,
    this.userId,
    required this.name,
    required this.type,
    required this.icon,
    required this.colorHex,
    required this.isDefault,
    required this.isArchived,
    required this.sortOrder,
  });

  CategoryEntity copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    String? icon,
    String? colorHex,
    bool? isDefault,
    bool? isArchived,
    int? sortOrder,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault ?? this.isDefault,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
