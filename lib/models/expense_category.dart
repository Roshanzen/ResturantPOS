class ExpenseCategory {
  final String id;
  final String name;
  final String branchId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.branchId,
    required this.createdAt,
    required this.updatedAt,
  });

  ExpenseCategory copyWith({
    String? id,
    String? name,
    String? branchId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      branchId: branchId ?? this.branchId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'branch_id': branchId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      branchId: (map['branch_id'] as String?) ?? 'branch_001',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }
}

