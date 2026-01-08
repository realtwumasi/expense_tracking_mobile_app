class Expense {
  final String id;
  final double amount;
  final String categoryId;
  final DateTime date;
  final String? description;
  final DateTime timestamp;

  Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'description': description,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: map['amount'],
      categoryId: map['categoryId'],
      date: DateTime.parse(map['date']),
      description: map['description'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
