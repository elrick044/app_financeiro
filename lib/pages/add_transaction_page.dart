import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/firebase_service.dart';
import '../../models/data_schema.dart';

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
    print(widget.categories);
  }

  void _initializeForm() {
    if (widget.transaction != null) {
      final transaction = widget.transaction!;
      _amountController.text = transaction.amount.toStringAsFixed(2).replaceAll('.', ',');
      _descriptionController.text = transaction.description;
      _selectedType = transaction.type;
      _selectedDate = transaction.date;
      _selectedCategory = widget.categories.firstWhere(
            (category) => category.name == transaction.category,
        orElse: () => widget.categories.first,
      );
    } else if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(
            isEditing ? 'Editar Transação' : 'Nova Transação',
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
          label: 'Voltar',
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: Theme.of(context).colorScheme.onSurface,
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
                _buildTypeSelector(),
                const SizedBox(height: 24),
                _buildAmountField(),
                const SizedBox(height: 24),
                _buildCategorySelector(),
                const SizedBox(height: 24),
                _buildDateSelector(),
                const SizedBox(height: 24),
                _buildDescriptionField(),
                const SizedBox(height: 32),
                _buildSaveButton(isEditing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Transação',
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
                'Receita',
                Icons.trending_up,
                Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeButton(
                TransactionType.expense,
                'Despesa',
                Icons.trending_down,
                Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeButton(TransactionType type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;

    return Semantics(
      selected: isSelected,
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            _selectedCategory = null;
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

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Valor',
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
            labelText: 'Valor',
            prefixText: 'R\$ ',
            prefixStyle: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            hintText: '0,00',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Valor é obrigatório';
            final amount = double.tryParse(value.replaceAll(',', '.'));
            if (amount == null || amount <= 0) return 'Digite um valor válido';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    final filteredCategories = widget.categories
        .where((category) => category.type == _selectedType)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoria',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<CategoryModel>(
          value: _selectedCategory?.type == _selectedType ? _selectedCategory : null,
          decoration: InputDecoration(
            labelText: 'Selecione uma categoria',
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
                  Text(category.name),
                ],
              ),
            );
          }).toList(),
          onChanged: (category) {
            setState(() {
              _selectedCategory = category;
            });
          },
          validator: (value) => value == null ? 'Selecione uma categoria' : null,
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          button: true,
          label: 'Selecionar data',
          child: GestureDetector(
            onTap: _selectDate,
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
                    '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
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

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descrição (Opcional)',
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
            hintText: 'Digite uma descrição para esta transação...',
            labelText: 'Descrição',
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(bool isEditing) {
    return Semantics(
      button: true,
      label: isEditing ? 'Atualizar transação' : 'Salvar transação',
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
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
            isEditing ? 'Atualizar Transação' : 'Salvar Transação',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) throw 'Usuário não encontrado';

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
                ? 'Transação atualizada com sucesso!'
                : 'Transação adicionada com sucesso!'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar transação: $e'),
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
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
