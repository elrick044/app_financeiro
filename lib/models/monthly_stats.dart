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