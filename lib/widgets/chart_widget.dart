import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/data_schema.dart';
// Importa as classes de internacionalização
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart'; // Para formatação de moeda

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
    // Obtenha a instância de AppLocalizations no método build
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Semantics(
          label: l10n.chartsTab, // Usando string localizada
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
              tabs: [
                Tab(text: l10n.expensesTab), // String localizada
                Tab(text: l10n.incomeTab),    // String localizada
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
              _buildExpenseChart(l10n), // Passa l10n
              _buildIncomeChart(l10n),  // Passa l10n
            ],
          ),
        ),
      ],
    );
  }

  // Helper para formatação de moeda (reutilizável)
  String _formatCurrency(double amount, AppLocalizations l10n) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    final format = NumberFormat.currency(
      locale: currentLocale,
      symbol: l10n.currencySymbol, // Usa o símbolo da moeda do ARB
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  // Recebe l10n
  Widget _buildExpenseChart(AppLocalizations l10n) {
    final expenseData = widget.monthlyStats.expensesByCategory;

    if (expenseData.isEmpty) {
      return _buildEmptyState(l10n.noExpensesFound, Icons.money_off, l10n); // String localizada
    }

    return Semantics(
      label: l10n.chartsTab, // Gráfico de pizza das despesas por categoria
      child: _buildPieChart(expenseData, TransactionType.expense, l10n), // Passa l10n
    );
  }

  // Recebe l10n
  Widget _buildIncomeChart(AppLocalizations l10n) {
    final incomeData = widget.monthlyStats.incomeByCategory;

    if (incomeData.isEmpty) {
      return _buildEmptyState(l10n.noIncomeFound, Icons.attach_money, l10n); // String localizada
    }

    return Semantics(
      label: l10n.chartsTab, // Gráfico de pizza das receitas por categoria
      child: _buildPieChart(incomeData, TransactionType.income, l10n), // Passa l10n
    );
  }

  // Recebe l10n
  Widget _buildEmptyState(String message, IconData icon, AppLocalizations l10n) {
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

  // Recebe l10n
  Widget _buildPieChart(Map<String, double> data, TransactionType type, AppLocalizations l10n) {
    final sections = _createPieChartSections(data, type, l10n); // Passa l10n

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
          child: _buildLegend(data, type, l10n), // Passa l10n
        ),
      ],
    );
  }

  // Recebe l10n
  List<PieChartSectionData> _createPieChartSections(Map<String, double> data, TransactionType type, AppLocalizations l10n) {
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
          color: '0xFF607D8B', // Cor padrão
          type: type,
          //createdAt: DateTime.now(), // Adicionei createdAt para CategoryModel
        ),
      );

      final color = Color(int.parse(category.color));
      final isTouched = index == _touchedIndex;

      return PieChartSectionData(
        color: color,
        value: amount,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: isTouched ? 70 : 60,
        titleStyle: const TextStyle( // Definindo TextStyle como const
          fontSize: 12, // Tamanho padrão
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ).copyWith( // Usando copyWith para alterar se isTouched
          fontSize: isTouched ? 14 : 12,
        ),
        badgeWidget: isTouched
            ? Semantics(
          label: '${l10n.category}: $categoryName, ${percentage.toStringAsFixed(1)}%', // String localizada
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

  // Recebe l10n
  Widget _buildLegend(Map<String, double> data, TransactionType type, AppLocalizations l10n) {
    final total = data.values.fold(0.0, (sum, value) => sum + value);

    return Semantics(
      container: true,
      label: l10n.chartsTab, // Legenda do gráfico com categorias e valores
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.totalAmount(l10n.currencySymbol, _formatCurrency(total, l10n)), // String localizada com placeholder
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: type == TransactionType.income
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          // Adiciona SingleChildScrollView para a legenda rolar se for muito longa
          Expanded( // Envolver o ListView.builder em Expanded para dar altura limitada
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: data.entries.length,
              itemBuilder: (context, index) {
                final entry = data.entries.elementAt(index);
                final categoryName = entry.key;
                final amount = entry.value;
                final percentage = (amount / total) * 100;

                final category = widget.categories.firstWhere(
                      (cat) => cat.name == categoryName && cat.type == type,
                  orElse: () => CategoryModel(
                    id: '',
                    name: categoryName,
                    icon: 'more_horiz',
                    color: '0xFF607D8B', // Cor padrão
                    type: type,
                    //createdAt: DateTime.now(), // Adicionei createdAt para CategoryModel
                  ),
                );

                return Semantics(
                  label:
                  '${categoryName}: ${_formatCurrency(amount, l10n)} (${percentage.toStringAsFixed(1)}%)', // Usando string localizada
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
                                  '${_formatCurrency(amount, l10n)} (${percentage.toStringAsFixed(1)}%)', // Formatação de moeda
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
              },
            ),
          ),
        ],
      ),
    );
  }

  // Este método não precisa de l10n, pois ele apenas mapeia ícones
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
      // Adicione outros ícones que você usa em suas categorias
      'shopping_cart': Icons.shopping_cart,
      'flight': Icons.flight,
      'pets': Icons.pets,
      'fitness_center': Icons.fitness_center,
      'book': Icons.book,
      'build': Icons.build,
      'emoji_events': Icons.emoji_events,
      'fastfood': Icons.fastfood,
      'games': Icons.games,
      'medical_services': Icons.medical_services,
      'public': Icons.public,
      'receipt_long': Icons.receipt_long,
      'redeem': Icons.redeem,
      'savings': Icons.savings,
      'stars': Icons.stars,
      'toys': Icons.toys,
      'videogame_asset': Icons.videogame_asset,
      'wallet': Icons.wallet,
      'add_box': Icons.add_box,
      'auto_stories': Icons.auto_stories,
      'bed': Icons.bed,
      'celebration': Icons.celebration,
      'computer': Icons.computer,
      'diamond': Icons.diamond,
      'dry_cleaning': Icons.dry_cleaning,
      'factory': Icons.factory,
      'festival': Icons.festival,
      'garden': Icons.yard,
      'hardware': Icons.hardware,
      'health_and_safety': Icons.health_and_safety,
      'library_books': Icons.library_books,
      'mail': Icons.mail,
      'menu_book': Icons.menu_book,
      'military_tech': Icons.military_tech,
      'park': Icons.park,
      'payments': Icons.payments,
      'person_pin_circle': Icons.person_pin_circle,
      'pie_chart': Icons.pie_chart,
      'precision_manufacturing': Icons.precision_manufacturing,
      'qr_code': Icons.qr_code,
      'request_quote': Icons.request_quote,
      'rocket_launch': Icons.rocket_launch,
      'roller_skating': Icons.roller_skating,
      'shield': Icons.shield,
      'stadium': Icons.stadium,
      'store': Icons.store,
      'theater_comedy': Icons.theater_comedy,
      'travel_explore': Icons.travel_explore,
      'wallet_giftcard': Icons.wallet_giftcard,
      'waves': Icons.waves,
      'weekend': Icons.weekend,
    };
    return iconMap[iconName] ?? Icons.category;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}