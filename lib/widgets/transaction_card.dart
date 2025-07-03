import 'package:flutter/material.dart';
import '../../models/data_schema.dart';

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
    final category = categories.firstWhere(
          (cat) => cat.name == transaction.category,
      orElse: () => CategoryModel(
        id: '',
        name: transaction.category,
        icon: 'more_horiz',
        color: '0xFF607D8B',
        type: transaction.type,
      ),
    );

    final isIncome = transaction.type == TransactionType.income;
    final amountColor = isIncome
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.error;

    return Card(
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
                child: _buildTransactionInfo(context, category),
              ),
              _buildAmount(context, amountColor),
              if (onEdit != null || onDelete != null) ...[
                const SizedBox(width: 8),
                _buildActionsMenu(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(CategoryModel category) {
    return Container(
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
    );
  }

  Widget _buildTransactionInfo(BuildContext context, CategoryModel category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        if (transaction.description.isNotEmpty) ...[
          Text(
            transaction.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
        ],
        Text(
          _formatDate(transaction.date),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildAmount(BuildContext context, Color amountColor) {
    final formattedAmount = 'R\$ ${transaction.amount.toStringAsFixed(2).replaceAll('.', ',')}';
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: amountColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            transaction.type == TransactionType.income ? 'Receita' : 'Despesa',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: amountColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsMenu(BuildContext context) {
    return PopupMenuButton<String>(
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
                const Text('Editar'),
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
                  'Excluir',
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
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Hoje';
    } else if (transactionDate == yesterday) {
      return 'Ontem';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
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
}