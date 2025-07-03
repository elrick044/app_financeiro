import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/data_schema.dart';

class ChartWidget extends StatefulWidget {
  final MonthlyStats monthlyStats;
  final List<CategoryModel> categories;

  const ChartWidget({
    super.key,
    required this.monthlyStats,
    required this.categories,
  });

  @override
  State<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          label: 'Aba de gráficos de despesas e receitas',
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Despesas'),
                Tab(text: 'Receitas'),
              ],
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              indicatorColor: Theme.of(context).colorScheme.primary,
              dividerColor: Colors.transparent,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildExpenseChart(),
              _buildIncomeChart(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseChart() {
    final expenseData = widget.monthlyStats.expensesByCategory;

    if (expenseData.isEmpty) {
      return _buildEmptyState('Nenhuma despesa encontrada', Icons.money_off);
    }

    return Semantics(
      label: 'Gráfico de pizza das despesas por categoria',
      child: _buildPieChart(expenseData, TransactionType.expense),
    );
  }

  Widget _buildIncomeChart() {
    final incomeData = widget.monthlyStats.incomeByCategory;

    if (incomeData.isEmpty) {
      return _buildEmptyState('Nenhuma receita encontrada', Icons.attach_money);
    }

    return Semantics(
      label: 'Gráfico de pizza das receitas por categoria',
      child: _buildPieChart(incomeData, TransactionType.income),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Semantics(
        label: message,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> data, TransactionType type) {
    final sections = _createPieChartSections(data, type);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: AspectRatio(
            aspectRatio: 1,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: sections,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildLegend(data, type),
        ),
      ],
    );
  }

  List<PieChartSectionData> _createPieChartSections(Map<String, double> data, TransactionType type) {
    final total = data.values.fold(0.0, (sum, value) => sum + value);
    final entries = data.entries.toList();

    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final categoryName = entry.value.key;
      final amount = entry.value.value;
      final percentage = (amount / total) * 100;

      final category = widget.categories.firstWhere(
            (cat) => cat.name == categoryName && cat.type == type,
        orElse: () => CategoryModel(
          id: '',
          name: categoryName,
          icon: 'more_horiz',
          color: '0xFF607D8B',
          type: type,
        ),
      );

      final color = Color(int.parse(category.color));
      final isTouched = index == _touchedIndex;

      return PieChartSectionData(
        color: color,
        value: amount,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: isTouched ? 70 : 60,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: isTouched
            ? Semantics(
          label: 'Categoria: $categoryName, ${percentage.toStringAsFixed(1)}%',
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(
              _getIconData(category.icon),
              color: color,
              size: 16,
            ),
          ),
        )
            : null,
      );
    }).toList();
  }

  Widget _buildLegend(Map<String, double> data, TransactionType type) {
    final total = data.values.fold(0.0, (sum, value) => sum + value);

    return Semantics(
      container: true,
      label: 'Legenda do gráfico com categorias e valores',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total: R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: type == TransactionType.income
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          ...data.entries.map((entry) {
            final categoryName = entry.key;
            final amount = entry.value;
            final percentage = (amount / total) * 100;

            final category = widget.categories.firstWhere(
                  (cat) => cat.name == categoryName && cat.type == type,
              orElse: () => CategoryModel(
                id: '',
                name: categoryName,
                icon: 'more_horiz',
                color: '0xFF607D8B',
                type: type,
              ),
            );

            return Semantics(
              label:
              '$categoryName: R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')} (${percentage.toStringAsFixed(1)}%)',
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(int.parse(category.color)),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExcludeSemantics(
                            child: Text(
                              categoryName,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ExcludeSemantics(
                            child: Text(
                              'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')} (${percentage.toStringAsFixed(1)}%)',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    final iconMap = {
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'sports_esports': Icons.sports_esports,
      'home': Icons.home,
      'checkroom': Icons.checkroom,
      'work': Icons.work,
      'laptop_mac': Icons.laptop_mac,
      'trending_up': Icons.trending_up,
      'monetization_on': Icons.monetization_on,
      'account_balance_wallet': Icons.account_balance_wallet,
      'more_horiz': Icons.more_horiz,
    };

    return iconMap[iconName] ?? Icons.category;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
