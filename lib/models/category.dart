import 'transaction_type.dart'; // Importe o enum

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String color;
  final TransactionType type;
  final bool isDefault;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isDefault = false,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json, String id) {
    return CategoryModel(
      id: id,
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      color: json['color'] ?? '',
      type: TransactionType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'color': color,
      'type': type.name,
      'isDefault': isDefault,
    };
  }
}