class UserModel {
  final String id;
  final String name;
  final String email;
  final int points;
  final double monthlyGoal;
  final String currentMonth;
  final DateTime createdAt;
  final List<String> achievements;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.points = 0,
    this.monthlyGoal = 0.0,
    required this.currentMonth,
    required this.createdAt,
    this.achievements = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      id: id,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      points: json['points'] ?? 0,
      monthlyGoal: (json['monthlyGoal'] ?? 0).toDouble(),
      currentMonth: json['currentMonth'] ?? '',
      createdAt: (json['createdAt']).toDate(),
      achievements: List<String>.from(json['achievements'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'points': points,
      'monthlyGoal': monthlyGoal,
      'currentMonth': currentMonth,
      'createdAt': createdAt,
      'achievements': achievements,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    int? points,
    double? monthlyGoal,
    String? currentMonth,
    DateTime? createdAt,
    List<String>? achievements,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      points: points ?? this.points,
      monthlyGoal: monthlyGoal ?? this.monthlyGoal,
      currentMonth: currentMonth ?? this.currentMonth,
      createdAt: createdAt ?? this.createdAt,
      achievements: achievements ?? this.achievements,
    );
  }
}

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
      date: (json['date']).toDate(),
      createdAt: (json['createdAt']).toDate(),
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

enum TransactionType {
  income,
  expense,
}

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

class MonthlyStats {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final Map<String, double> expensesByCategory;
  final Map<String, double> incomeByCategory;

  MonthlyStats({
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
    this.balance = 0.0,
    this.expensesByCategory = const {},
    this.incomeByCategory = const {},
  });

  MonthlyStats copyWith({
    double? totalIncome,
    double? totalExpense,
    double? balance,
    Map<String, double>? expensesByCategory,
    Map<String, double>? incomeByCategory,
  }) {
    return MonthlyStats(
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      balance: balance ?? this.balance,
      expensesByCategory: expensesByCategory ?? this.expensesByCategory,
      incomeByCategory: incomeByCategory ?? this.incomeByCategory,
    );
  }
}