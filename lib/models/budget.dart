class Budget {
  final String id;
  final String categoryId;
  final double limit;
  final int month;
  final int year;

  Budget({
    required this.id,
    required this.categoryId,
    required this.limit,
    required this.month,
    required this.year,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'categoryId': categoryId,
        'limit': limit,
        'month': month,
        'year': year,
      };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
        id: map['id'],
        categoryId: map['categoryId'],
        limit: map['limit'],
        month: map['month'],
        year: map['year'],
      );
}
