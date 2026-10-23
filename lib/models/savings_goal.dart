class SavingsGoal {
  final int? id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime? deadline;
  final DateTime createdAt;

  const SavingsGoal({
    this.id,
    required this.name,
    required this.targetAmount,
    this.savedAmount = 0,
    this.deadline,
    required this.createdAt,
  });

  // Chuyển mục tiêu tiết kiệm thành Map để lưu vào SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'target_amount': targetAmount,
      'saved_amount': savedAmount,
      'deadline': deadline?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Tạo mục tiêu tiết kiệm từ dữ liệu đọc được trong SQLite.
  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'] as int?,
      name: map['name'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      savedAmount: (map['saved_amount'] as num).toDouble(),
      deadline: map['deadline'] == null
          ? null
          : DateTime.parse(map['deadline'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Tiến độ tiết kiệm, giới hạn trong khoảng 0 đến 1.
  double get progress {
    if (targetAmount <= 0) return 0;
    return (savedAmount / targetAmount).clamp(0.0, 1.0);
  }

  // Số tiền còn thiếu để hoàn thành mục tiêu.
  double get remainingAmount {
    return (targetAmount - savedAmount).clamp(0.0, double.infinity);
  }

  bool get isCompleted => savedAmount >= targetAmount;
}
