class Budget {
  final int? id;
  final String category;
  final double amount;
  final String month;
  final DateTime createdAt;

  const Budget({
    this.id,
    required this.category,
    required this.amount,
    required this.month,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'month': month,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      month: map['month'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
