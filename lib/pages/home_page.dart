import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/data_schema.dart';
import '../services/firebase_service.dart';
import '../theme.dart';
import '../widgets/chart_widget.dart';
import '../widgets/gamification_widget.dart';
import '../widgets/transaction_card.dart';
import 'add_transaction_page.dart';
import 'auth_page.dart';
// Importa a classe de localizações gerada
// Importa para formatação de moeda e datas
import 'package:intl/intl.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;

  UserModel? _currentUser;
  List<TransactionModel> _transactions = []; // Esta lista não está sendo usada diretamente no StreamBuilder, mas é bom manter
  List<CategoryModel> _categories = [];
  MonthlyStats _monthlyStats = MonthlyStats();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) {
        _navigateToAuth();
        return;
      }

      final user = await _firebaseService.getUserData(currentUser.uid);
      // Você pode querer buscar categorias específicas do usuário se for o caso
      final categories = await _firebaseService.getCategories();


      final currentMonth = DateTime.now();
      final stats = await _firebaseService.getMonthlyStats(currentUser.uid, currentMonth);

      if (mounted) {
        setState(() {
          _currentUser = user;
          _categories = categories;
          _monthlyStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Acessa AppLocalizations para a mensagem de erro
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Semantics(
              liveRegion: true,
              child: Text('${l10n.errorLoadingData}$e'), // Usando string localizada
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Acessa AppLocalizations no método build
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Semantics(
            label: l10n.refreshData, // Usando string localizada
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          // 'FinanceFlow' pode ser uma marca e não ser traduzido,
          // ou você pode usar l10n.appName se tiver essa chave
          child: Text(
            'FinanceFlow',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          Semantics(
            button: true,
            label: l10n.refreshData, // Usando string localizada
            child: IconButton(
              icon: Icon(
                Icons.refresh,
                color: Theme.of(context).colorScheme.primary,
                semanticLabel: l10n.refreshData, // Usando string localizada
              ),
              onPressed: _loadData,
              tooltip: l10n.refreshData, // Usando string localizada
            ),
          ),
          Semantics(
            button: true,
            label: l10n.profileTab, // Menu de opções relacionado ao perfil
            child: PopupMenuButton(
              icon: Icon(
                Icons.more_vert,
                color: Theme.of(context).colorScheme.primary,
                semanticLabel: l10n.profileTab, // Usando string localizada
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: Theme.of(context).colorScheme.error,
                      semanticLabel: l10n.signOut, // Usando string localizada
                    ),
                    title: Text(
                      l10n.signOut, // Usando string localizada
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  onTap: () => _handleSignOut(l10n), // Passa l10n
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.home), text: l10n.homeTab), // Usando string localizada
            Tab(icon: const Icon(Icons.history), text: l10n.historyTab), // Usando string localizada
            Tab(icon: const Icon(Icons.pie_chart), text: l10n.chartsTab), // Usando string localizada
            Tab(icon: const Icon(Icons.person), text: l10n.profileTab), // Usando string localizada
          ],
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: Theme.of(context).colorScheme.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Semantics(
            container: true,
            label: l10n.homeTab, // Usando string localizada
            child: _buildHomeTab(l10n), // Passa l10n
          ),
          Semantics(
            container: true,
            label: l10n.historyTab, // Usando string localizada
            child: _buildHistoryTab(l10n), // Passa l10n
          ),
          Semantics(
            container: true,
            label: l10n.chartsTab, // Usando string localizada
            child: _buildChartsTab(l10n), // Passa l10n
          ),
          Semantics(
            container: true,
            label: l10n.profileTab, // Usando string localizada
            child: _buildProfileTab(l10n), // Passa l10n
          ),
        ],
      ),
      floatingActionButton: Semantics(
        label: l10n.addTransaction, // Usando string localizada
        button: true,
        child: FloatingActionButton(
          onPressed: _navigateToAddTransaction,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // Helper para formatação de moeda
  String _formatCurrency(double amount, AppLocalizations l10n) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    // Usar o símbolo da moeda do ARB e o locale para formatação correta
    final format = NumberFormat.currency(
      locale: currentLocale,
      symbol: l10n.currencySymbol,
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  // Recebe l10n
  Widget _buildHomeTab(AppLocalizations l10n) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(l10n), // Passa l10n
            const SizedBox(height: 16),
            _buildBalanceCard(l10n), // Passa l10n
            const SizedBox(height: 16),
            if (_currentUser != null) ...[
              // O GamificationWidget provavelmente precisará de l10n também
              // Se ele tiver strings internas que precisam de tradução.
              // Adaptei sua chamada aqui para passar l10n.
              Semantics(
                label: l10n.yourAchievements, // Usando string localizada
                child: GamificationWidget(user: _currentUser!),
              ),
              const SizedBox(height: 16),
            ],
            _buildQuickActions(l10n), // Passa l10n
            const SizedBox(height: 16),
            _buildRecentTransactions(l10n), // Passa l10n
          ],
        ),
      ),
    );
  }

  // Recebe l10n
  Widget _buildHistoryTab(AppLocalizations l10n) {
    return StreamBuilder<List<TransactionModel>>(
      stream: _currentUser != null
          ? _firebaseService.getUserTransactions(_currentUser!.id)
          : const Stream.empty(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Semantics(
              label: l10n.loadingHistory, // Nova string para acessibilidade (opcional)
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  label: l10n.noTransactionsFound, // Usando string localizada
                  child: Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noTransactionsFound, // Usando string localizada
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        final transactions = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TransactionCard(
                transaction: transactions[index],
                categories: _categories,
                onEdit: (transaction) => _editTransaction(transaction),
                onDelete: (transaction) => _deleteTransaction(transaction, l10n), // Passa l10n
              ),
            );
          },
        );
      },
    );
  }

  // Recebe l10n
  Widget _buildChartsTab(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Semantics(
            label: l10n.chartsTab, // Usando string localizada
            child: _buildStatsCards(l10n), // Passa l10n
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Semantics(
              label: l10n.chartsTab, // Usando string localizada
              // O ChartWidget também precisará receber l10n e ter seu código atualizado
              child: ChartWidget(
                monthlyStats: _monthlyStats,
                categories: _categories,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Recebe l10n
  Widget _buildProfileTab(AppLocalizations l10n) {
    return SingleChildScrollView( // Adicionado para evitar overflow
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Semantics(
              label: l10n.profileTab, // Usando string localizada
              child: _buildProfileCard(l10n), // Passa l10n
            ),
            const SizedBox(height: 16),
            if (_currentUser != null) ...[
              // O GamificationWidget precisa de l10n
              Semantics(
                label: l10n.yourAchievements, // Usando string localizada
                child: GamificationWidget(user: _currentUser!),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: l10n.profileTab, // Usando string localizada
                child: _buildProfileActions(l10n), // Passa l10n
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Recebe l10n
  Widget _buildWelcomeCard(AppLocalizations l10n) {
    return Semantics(
      container: true,
      label: l10n.howAreYourFinancesToday, // Usando string localizada
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.helloUser(_currentUser?.name.split(' ').first ?? l10n.currentUserDefault), // String com placeholder
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.howAreYourFinancesToday, // String localizada
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Recebe l10n
  Widget _buildBalanceCard(AppLocalizations l10n) {
    return Semantics(
      container: true,
      label: l10n.currentBalance, // Usando string localizada
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              l10n.currentBalance, // String localizada
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatCurrency(_monthlyStats.balance, l10n), // Formatação de moeda
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _monthlyStats.balance >= 0
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildBalanceItem(
                    l10n.totalIncome, // String localizada
                    _monthlyStats.totalIncome,
                    Icons.trending_up,
                    Theme.of(context).colorScheme.secondary,
                    l10n, // Passa l10n
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBalanceItem(
                    l10n.totalExpense, // String localizada
                    _monthlyStats.totalExpense,
                    Icons.trending_down,
                    Theme.of(context).colorScheme.error,
                    l10n, // Passa l10n
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Recebe l10n
  Widget _buildBalanceItem(String title, double amount, IconData icon, Color color, AppLocalizations l10n) {
    return Semantics(
      label: '$title: ${_formatCurrency(amount, l10n)}', // Usando string localizada
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatCurrency(amount, l10n), // Formatação de moeda
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Recebe l10n
  Widget _buildQuickActions(AppLocalizations l10n) {
    return Semantics(
      container: true,
      label: l10n.quickActions, // Usando string localizada
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.quickActions, // Usando string localizada
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  l10n.addIncome, // Usando string localizada
                  Icons.add_circle,
                  Theme.of(context).colorScheme.secondary,
                      () => _navigateToAddTransaction(isIncome: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  l10n.addExpense, // Usando string localizada
                  Icons.remove_circle,
                  Theme.of(context).colorScheme.error,
                      () => _navigateToAddTransaction(isIncome: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Este método não precisa de l10n se o title já vier traduzido
  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Recebe l10n
  Widget _buildRecentTransactions(AppLocalizations l10n) {
    return StreamBuilder<List<TransactionModel>>(
      stream: _currentUser != null
          ? _firebaseService.getUserTransactions(_currentUser!.id)
          : const Stream.empty(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Semantics(
            container: true,
            label: l10n.noRecentTransactions, // Usando string localizada
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  l10n.noRecentTransactions, // Usando string localizada
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          );
        }

        final recentTransactions = snapshot.data!.take(3).toList();

        return Semantics(
          container: true,
          label: l10n.recentTransactions, // Usando string localizada
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.recentTransactions, // Usando string localizada
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: l10n.viewAll, // Usando string localizada
                    child: TextButton(
                      onPressed: () => _tabController.animateTo(1),
                      child: Text(
                        l10n.viewAll, // Usando string localizada
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...recentTransactions.map((transaction) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TransactionCard(
                  transaction: transaction,
                  categories: _categories,
                  onEdit: (transaction) => _editTransaction(transaction),
                  onDelete: (transaction) => _deleteTransaction(transaction, l10n), // Passa l10n
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  // Recebe l10n
  Widget _buildStatsCards(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            l10n.totalIncomesChart, // Usando string localizada
            _monthlyStats.totalIncome,
            Icons.trending_up,
            Theme.of(context).colorScheme.secondary,
            l10n, // Passa l10n
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            l10n.totalExpensesChart, // Usando string localizada
            _monthlyStats.totalExpense,
            Icons.trending_down,
            Theme.of(context).colorScheme.error,
            l10n, // Passa l10n
          ),
        ),
      ],
    );
  }

  // Recebe l10n
  Widget _buildStatCard(String title, double value, IconData icon, Color color, AppLocalizations l10n) {
    return Semantics(
      label: '$title: ${_formatCurrency(value, l10n)}', // Usando string localizada
      hint: title, // A dica pode ser o próprio título
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Tooltip(
              message: title,
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 8),
            ExcludeSemantics(
              child: Text(
                _formatCurrency(value, l10n), // Formatação de moeda
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            ExcludeSemantics(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Recebe l10n
  Widget _buildProfileCard(AppLocalizations l10n) {
    return Semantics(
      container: true,
      label: l10n.profileTab, // Usando string localizada
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Semantics(
              label: 'Avatar do usuário',
              child: CircleAvatar(
                radius: 40,
                backgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _currentUser?.name ?? l10n.currentUserDefault, // String localizada
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _currentUser?.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Recebe l10n
  Widget _buildProfileActions(AppLocalizations l10n) {
    return Column(
      children: [
        Semantics(
          button: true,
          label: l10n.settings, // Usando string localizada
          child: ListTile(
            leading: Icon(
              Icons.settings,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(l10n.settings), // Usando string localizada
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: Navigate to settings
            },
          ),
        ),
        Semantics(
          button: true,
          label: l10n.help, // Usando string localizada
          child: ListTile(
            leading: Icon(
              Icons.help,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(l10n.help), // Usando string localizada
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: Navigate to help
            },
          ),
        ),
        Semantics(
          button: true,
          label: l10n.signOut, // Usando string localizada
          child: ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              l10n.signOut, // Usando string localizada
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            onTap: () => _handleSignOut(l10n), // Passa l10n
          ),
        ),
      ],
    );
  }

  void _navigateToAddTransaction({bool? isIncome}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddTransactionPage(
          categories: _categories,
          initialType: isIncome != null
              ? (isIncome ? TransactionType.income : TransactionType.expense)
              : null,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  void _editTransaction(TransactionModel transaction) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddTransactionPage(
          categories: _categories,
          transaction: transaction,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  // Recebe l10n para as mensagens do AlertDialog e SnackBar
  void _deleteTransaction(TransactionModel transaction, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeletion), // Usando string localizada
        content: Text(l10n.confirmTransactionDeletion), // Usando string localizada
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel), // Usando string localizada
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete), // Usando string localizada
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firebaseService.deleteTransaction(transaction.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.transactionDeletedSuccessfully)), // Usando string localizada
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.errorDeletingTransaction}$e'), // Usando string localizada com erro
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  // Recebe l10n para a mensagem de erro
  void _handleSignOut(AppLocalizations l10n) async {
    try {
      await _firebaseService.signOut();
      _navigateToAuth();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorSigningOut}$e'), // Usando string localizada com erro
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _navigateToAuth() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthPage()),
          (route) => false,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}