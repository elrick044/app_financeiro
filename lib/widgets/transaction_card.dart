import 'dart:io';

import 'package:flutter/material.dart';
import '../../models/data_schema.dart';
// Importa as classes de internacionalização
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart'; // Para formatação de moeda e datas

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final List<CategoryModel> categories;
  final Function(TransactionModel)? onEdit;
  final Function(TransactionModel)? onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.categories,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Obtenha a instância de AppLocalizations no método build
    final l10n = AppLocalizations.of(context)!;

    final category = categories.firstWhere(
          (cat) => cat.name == transaction.category,
      orElse: () => CategoryModel(
        id: '',
        name: transaction.category,
        icon: 'more_horiz',
        color: '0xFF607D8B', // Cor padrão
        type: transaction.type,
      ),
    );

    final isIncome = transaction.type == TransactionType.income;
    final amountColor = isIncome
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.error;

    // Use a função de formatação de moeda
    final formattedAmount = _formatCurrency(transaction.amount, l10n, context);
    final prefix = isIncome ? '+' : '-';

    return Semantics(
      label: l10n.transactionCardSemanticLabel( // String localizada com placeholders
        category.name,
        transaction.description.isNotEmpty ? transaction.description : '',
        _formatDate(transaction.date, l10n, context), // Passa l10n
        isIncome ? l10n.incomeTypeLabel : l10n.expenseTypeLabel, // Strings localizadas
        '$prefix$formattedAmount',
      ),
      button: onEdit != null,
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: InkWell(
          onTap: onEdit != null ? () => onEdit!(transaction) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildCategoryIcon(category),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTransactionInfo(context, category, l10n), // Passa l10n
                ),
                _buildAmount(context, amountColor, l10n), // Passa l10n
                if (onEdit != null || onDelete != null) ...[
                  const SizedBox(width: 8),
                  _buildActionsMenu(context, l10n), // Passa l10n
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper para formatação de moeda
  String _formatCurrency(double amount, AppLocalizations l10n, BuildContext context) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    final format = NumberFormat.currency(
      locale: currentLocale,
      symbol: l10n.currencySymbol, // Usa o símbolo da moeda do ARB
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  // Helper para formatar a data
  String _formatDate(DateTime date, AppLocalizations l10n, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.year, date.day); // Corrigido para date.year

    if (transactionDate == today) {
      return l10n.today; // String localizada
    } else if (transactionDate == yesterday) {
      return l10n.yesterday; // String localizada
    } else {
      // Formata a data para a localidade atual
      final currentLocale = Localizations.localeOf(context).languageCode;
      return DateFormat.yMd(currentLocale).format(date); // Ex: 03/07/2025 ou 7/3/2025
    }
  }

  Widget _buildCategoryIcon(CategoryModel category) {
    return ExcludeSemantics(
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Color(int.parse(category.color)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _getIconData(category.icon),
          color: Color(int.parse(category.color)),
          size: 24,
        ),
      ),
    );
  }

  // Recebe l10n
  Widget _buildTransactionInfo(BuildContext context, CategoryModel category, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.name, // Nome da categoria não é traduzido via ARB, vem do modelo
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        if (transaction.description.isNotEmpty) ...[
          Text(
            transaction.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
        ],
        Text(
          _formatDate(transaction.date, l10n, context), // Usa helper de formatação de data
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  // Recebe l10n
  Widget _buildAmount(BuildContext context, Color amountColor, AppLocalizations l10n) {
    final formattedAmount = _formatCurrency(transaction.amount, l10n, context); // Formatação de moeda
    final prefix = transaction.type == TransactionType.income ? '+' : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$prefix$formattedAmount',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: amountColor,
          ),
        ),
        const SizedBox(height: 4),
        ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: amountColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              transaction.type == TransactionType.income ? l10n.incomeTypeLabel : l10n.expenseTypeLabel, // Strings localizadas
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: amountColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Recebe l10n
  Widget _buildActionsMenu(BuildContext context, AppLocalizations l10n) {
    return Semantics(
      label: l10n.moreOptions, // String localizada para acessibilidade (adicione ao ARB se não tiver)
      button: true,
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          size: 20,
        ),
        itemBuilder: (context) => [
          if (onEdit != null)
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.editAction), // String localizada
                ],
              ),
            ),
          if (onDelete != null)
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.deleteAction, // String localizada
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
        ],
        onSelected: (value) {
          switch (value) {
            case 'edit':
              onEdit?.call(transaction);
              break;
            case 'delete':
              onDelete?.call(transaction);
              break;
          }
        },
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
}