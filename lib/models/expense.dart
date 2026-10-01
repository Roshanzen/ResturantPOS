class Expense {
  final String id;
  final String branchId;
  final String categoryId;
  final String categoryName;
  final String title;
  final double amount;
  final DateTime expenseDate;
  final String paymentMethod;
  final String? referenceNumber;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  Expense({
    required this.id,
    required this.branchId,
    required this.categoryId,
    required this.categoryName,
    required this.title,
    required this.amount,
    required this.expenseDate,
    required this.paymentMethod,
    this.referenceNumber,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  Expense copyWith({
    String? id,
    String? branchId,
    String? categoryId,
    String? categoryName,
    String? title,
    double? amount,
    DateTime? expenseDate,
    String? paymentMethod,
    String? referenceNumber,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Expense(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'branch_id': branchId,
      'category_id': categoryId,
      'category_name': categoryName,
      'title': title,
      'amount_minor': (amount * 100).round(),
      'expense_date': expenseDate.toIso8601String(),
      'payment_method': paymentMethod,
      'reference_number': referenceNumber,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      branchId: (map['branch_id'] as String?) ?? 'branch_001',
      categoryId: map['category_id'] as String,
      categoryName: map['category_name'] as String,
      title: map['title'] as String,
      amount: ((map['amount_minor'] as int?) ?? 0) / 100.0,
      expenseDate: map['expense_date'] != null
          ? DateTime.parse(map['expense_date'] as String)
          : DateTime.now(),
      paymentMethod: (map['payment_method'] as String?) ?? 'cash',
      referenceNumber: map['reference_number'] as String?,
      notes: map['notes'] as String?,
      createdBy: (map['created_by'] as String?) ?? 'system',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }
}

