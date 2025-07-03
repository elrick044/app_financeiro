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