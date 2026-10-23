class ReceiptData {
  final String description;
  final String? recipientName;
  final double amount;
  final DateTime? date;
  final String rawText;

  const ReceiptData({
    required this.description,
    this.recipientName,
    required this.amount,
    this.date,
    required this.rawText,
  });

  ReceiptData copyWith({
    String? description,
    String? recipientName,
    double? amount,
    DateTime? date,
    String? rawText,
  }) {
    return ReceiptData(
      description: description ?? this.description,
      recipientName: recipientName ?? this.recipientName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      rawText: rawText ?? this.rawText,
    );
  }
}
