class Category {
  final String id;
  final String name;
  final String icon;
  final int color;
  final bool isDefault;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'isDefault': isDefault ? 1 : 0,
      };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'],
        name: map['name'],
        icon: map['icon'],
        color: map['color'],
        isDefault: map['isDefault'] == 1,
      );

  static List<Category> get defaults => [
        Category(id: 'food', name: 'Comida', icon: '🍔', color: 0xFFE53935, isDefault: true),
        Category(id: 'transport', name: 'Transporte', icon: '🚗', color: 0xFF1E88E5, isDefault: true),
        Category(id: 'home', name: 'Hogar', icon: '🏠', color: 0xFF43A047, isDefault: true),
        Category(id: 'health', name: 'Salud', icon: '💊', color: 0xFF8E24AA, isDefault: true),
        Category(id: 'entertainment', name: 'Entretenimiento', icon: '🎮', color: 0xFFFB8C00, isDefault: true),
        Category(id: 'education', name: 'Educación', icon: '📚', color: 0xFF00ACC1, isDefault: true),
        Category(id: 'clothing', name: 'Ropa', icon: '👕', color: 0xFFD81B60, isDefault: true),
        Category(id: 'other', name: 'Otros', icon: '📦', color: 0xFF757575, isDefault: true),
      ];
}
