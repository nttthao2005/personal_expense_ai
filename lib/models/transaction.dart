enum TransactionType { income, expense }

class ExpenseTransaction {
  final int? id;
  final String title;
  final String? recipientName;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String? note;
  final String? rawOcrText;

  const ExpenseTransaction({
    this.id,
    required this.title,
    this.recipientName,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note,
    this.rawOcrText,
  });

  // Chuyển giao dịch thành Map để lưu vào SQLite.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'recipient_name': recipientName,
      'amount': amount,
      'type': type.name,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
      'raw_ocr_text': rawOcrText,
    };
  }

  // Chuyển dữ liệu đọc từ SQLite thành đối tượng giao dịch.
  factory ExpenseTransaction.fromMap(Map<String, Object?> map) {
    return ExpenseTransaction(
      id: map['id'] as int?,
      title: map['title'] as String,
      recipientName: map['recipient_name'] as String?,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.byName(map['type'] as String),
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      rawOcrText: map['raw_ocr_text'] as String?,
    );
  }
}
