import 'transaction_type.dart'; // Importe o enum

class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final TransactionType type;
  final String category;
  final String description;
  final DateTime date;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.category,
    this.description = '',
    required this.date,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json, String id) {
    return TransactionModel(
      id: id,
      userId: json['userId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      type: TransactionType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      date: json['date'].toDate(),
      createdAt: json['createdAt'].toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'amount': amount,
      'type': type.name,
      'category': category,
      'description': description,
      'date': date,
      'createdAt': createdAt,
    };
  }

  TransactionModel copyWith({
    String? userId,
    double? amount,
    TransactionType? type,
    String? category,
    String? description,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}