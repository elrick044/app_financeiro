import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/firebase_service.dart';
import '../../models/data_schema.dart';
// Importa as classes de internacionalização
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart'; // Para formatação de moeda e datas

class AddTransactionPage extends StatefulWidget {
  final List<CategoryModel> categories;
  final TransactionModel? transaction;
  final TransactionType? initialType;

  const AddTransactionPage({
    super.key,
    required this.categories,
    this.transaction,
    this.initialType,
  });

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    // print(widget.categories); // Comentado para ambiente de produção, útil para depuração
  }

  void _initializeForm() {
    if (widget.transaction != null) {
      // Editing existing transaction
      final transaction = widget.transaction!;
      // A formatação aqui é apenas para display inicial, o validator lida com a entrada
      _amountController.text = transaction.amount.toStringAsFixed(2).replaceAll('.', ',');
      _descriptionController.text = transaction.description;
      _selectedType = transaction.type;
      _selectedDate = transaction.date;

      // Find the category
      _selectedCategory = widget.categories.firstWhere(
            (category) => category.name == transaction.category,
        orElse: () => widget.categories.first,
      );
    } else if (widget.initialType != null) {
      // Initial type provided
      _selectedType = widget.initialType!;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenha a instância de AppLocalizations no método build
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.transaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(
            isEditing ? l10n.editTransaction : l10n.newTransaction, // Strings localizadas
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: Semantics(
          button: true,
          label: l10n.backButtonLabel, // String localizada para acessibilidade (certifique-se de adicioná-la aos ARBs)
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: FocusTraversalGroup(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTypeSelector(l10n), // Passa l10n
                const SizedBox(height: 24),
                _buildAmountField(l10n), // Passa l10n
                const SizedBox(height: 24),
                _buildCategorySelector(l10n), // Passa l10n
                const SizedBox(height: 24),
                _buildDateSelector(l10n), // Passa l10n
                const SizedBox(height: 24),
                _buildDescriptionField(l10n), // Passa l10n
                const SizedBox(height: 32),
                _buildSaveButton(isEditing, l10n), // Passa l10n
              ],
            ),
          ),
        ),
      ),
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

  // Helper para formatar a data (reutilizável)
  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

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

  // Recebe l10n
  Widget _buildTypeSelector(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.transactionType, // String localizada
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeButton(
                TransactionType.income,
                l10n.income, // String localizada
                Icons.trending_up,
                Theme.of(context).colorScheme.secondary,
                l10n, // Passa l10n
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeButton(
                TransactionType.expense,
                l10n.expense, // String localizada
                Icons.trending_down,
                Theme.of(context).colorScheme.error,
                l10n, // Passa l10n
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Recebe l10n
  Widget _buildTypeButton(TransactionType type, String label, IconData icon, Color color, AppLocalizations l10n) {
    final isSelected = _selectedType == type;

    return Semantics(
      selected: isSelected,
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            _selectedCategory = null; // Reset category when type changes
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Theme.of(context).colorScheme.outline.withOpacity(0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Recebe l10n
  Widget _buildAmountField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.amount, // String localizada
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
          ],
          decoration: InputDecoration(
            labelText: l10n.amount, // String localizada
            prefixText: '${l10n.currencySymbol} ', // Símbolo da moeda localizada
            prefixStyle: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            hintText: '0,00', // Hint pode ser genérico ou localizado se precisar
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return l10n.amountRequired; // String localizada
            final amount = double.tryParse(value.replaceAll(',', '.'));
            if (amount == null || amount <= 0) return l10n.enterValidAmount; // String localizada
            return null;
          },
        ),
      ],
    );
  }

  // Recebe l10n
  Widget _buildCategorySelector(AppLocalizations l10n) {
    final filteredCategories = widget.categories
        .where((category) => category.type == _selectedType)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.category, // String localizada
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<CategoryModel>(
          value: _selectedCategory?.type == _selectedType ? _selectedCategory : null,
          decoration: InputDecoration(
            labelText: l10n.selectCategory, // String localizada
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: filteredCategories.map((category) {
            return DropdownMenuItem<CategoryModel>(
              value: category,
              child: Row(
                children: [
                  Icon(_getIconData(category.icon), color: Color(int.parse(category.color)), size: 20),
                  const SizedBox(width: 12),
                  Text(category.name), // Nome da categoria não é traduzido via ARB, vem do modelo
                ],
              ),
            );
          }).toList(),
          onChanged: (category) {
            setState(() {
              _selectedCategory = category;
            });
          },
          validator: (value) => value == null ? l10n.categoryRequired : null, // String localizada
        ),
      ],
    );
  }

  // Recebe l10n
  Widget _buildDateSelector(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.date, // String localizada
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          button: true,
          label: l10n.selectDate, // String localizada para acessibilidade (adicione ao ARB)
          child: GestureDetector(
            onTap: () => _selectDate(l10n), // Passa l10n
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    _formatDate(_selectedDate, l10n), // Usa helper de formatação de data
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Recebe l10n
  Widget _buildDescriptionField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.descriptionOptional, // String localizada
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: l10n.enterTransactionDescriptionHint, // String localizada
            labelText: l10n.descriptionOptional, // String localizada
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // Recebe l10n
  Widget _buildSaveButton(bool isEditing, AppLocalizations l10n) {
    return Semantics(
      button: true,
      label: isEditing ? l10n.updateTransaction : l10n.saveTransaction, // Strings localizadas
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : () => _handleSave(l10n), // Passa l10n para _handleSave
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: _isLoading
              ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          )
              : Text(
            isEditing ? l10n.updateTransaction : l10n.saveTransaction, // Strings localizadas
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
      ),
    );
  }

  // Recebe l10n para o builder do DatePicker
  Future<void> _selectDate(AppLocalizations l10n) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  // Recebe l10n para as mensagens de erro/sucesso
  Future<void> _handleSave(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) throw l10n.userNotFound; // String localizada

      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      final description = _descriptionController.text.trim();

      if (widget.transaction != null) {
        final updatedTransaction = widget.transaction!.copyWith(
          amount: amount,
          type: _selectedType,
          category: _selectedCategory!.name,
          description: description,
          date: _selectedDate,
        );

        await _firebaseService.updateTransaction(updatedTransaction);
      } else {
        final transaction = TransactionModel(
          id: '',
          userId: currentUser.uid,
          amount: amount,
          type: _selectedType,
          category: _selectedCategory!.name,
          description: description,
          date: _selectedDate,
          createdAt: DateTime.now(),
        );

        await _firebaseService.addTransaction(transaction);
      }

      await _firebaseService.checkAndAwardAchievements(currentUser.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.transaction != null
                ? l10n.transactionUpdatedSuccessfully // String localizada
                : l10n.transactionAddedSuccessfully), // String localizada
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorSavingTransaction}$e'), // String localizada com erro
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}