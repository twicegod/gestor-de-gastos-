class Expense {
  final String id;
  final String title;
  final double amount;
  final String categoryId;
  final DateTime date;
  final String paymentMethod;
  final String? note;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.date,
    this.paymentMethod = 'Efectivo',
    this.note,
  });

  static const paymentMethods = ['Efectivo', 'Banco', 'Tarjeta'];

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'categoryId': categoryId,
        'date': date.toIso8601String(),
        'paymentMethod': paymentMethod,
        'note': note,
      };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'],
        title: map['title'],
        amount: (map['amount'] as num).toDouble(),
        categoryId: map['categoryId'],
        date: DateTime.parse(map['date']),
        paymentMethod: map['paymentMethod'] as String? ?? 'Efectivo',
        note: map['note'],
      );
}
