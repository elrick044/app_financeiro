import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/data_schema.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  //final GoogleSignIn _googleSignIn = GoogleSignIn(); // Disabled for demo

  // Authentication Methods
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return await getUserData(credential.user!.uid);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserModel?> createUserWithEmailAndPassword(
      String email,
      String password,
      String name,
      ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);

        final user = UserModel(
          id: credential.user!.uid,
          name: name,
          email: email,
          currentMonth: _getCurrentMonth(),
          createdAt: DateTime.now(),
        );

        await _createUserDocument(user);
        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      // Google Sign In is disabled for demo purposes
      // In production, implement proper Google Sign In integration
      throw 'Google Sign In não está disponível na versão demo';
    } catch (e) {
      throw 'Erro ao fazer login com Google: $e';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    // await _googleSignIn.signOut(); // Disabled for demo
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // User Data Methods
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!, userId);
      }
      return null;
    } catch (e) {
      throw 'Erro ao buscar dados do usuário: $e';
    }
  }

  Future<void> _createUserDocument(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toJson());
  }

  Future<void> updateUserData(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toJson());
    } catch (e) {
      throw 'Erro ao atualizar dados do usuário: $e';
    }
  }

  // Transaction Methods
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await _firestore.collection('transactions').add(transaction.toJson());

      // Award points for adding transaction
      await _awardPoints(transaction.userId, 10);
    } catch (e) {
      throw 'Erro ao adicionar transação: $e';
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _firestore
          .collection('transactions')
          .doc(transaction.id)
          .update(transaction.toJson());
    } catch (e) {
      throw 'Erro ao atualizar transação: $e';
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).delete();
    } catch (e) {
      throw 'Erro ao deletar transação: $e';
    }
  }

  Stream<List<TransactionModel>> getUserTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => TransactionModel.fromJson(doc.data(), doc.id))
        .toList());
  }

  Future<List<TransactionModel>> getTransactionsByMonth(
      String userId,
      DateTime month,
      ) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 1);

      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TransactionModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw 'Erro ao buscar transações do mês: $e';
    }
  }

  // Category Methods
  Future<List<CategoryModel>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      return snapshot.docs
          .map((doc) => CategoryModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw 'Erro ao buscar categorias: $e';
    }
  }

  // Statistics Methods
  Future<MonthlyStats> getMonthlyStats(String userId, DateTime month) async {
    try {
      final transactions = await getTransactionsByMonth(userId, month);

      double totalIncome = 0;
      double totalExpense = 0;
      Map<String, double> expensesByCategory = {};
      Map<String, double> incomeByCategory = {};

      for (final transaction in transactions) {
        if (transaction.type == TransactionType.income) {
          totalIncome += transaction.amount;
          incomeByCategory[transaction.category] =
              (incomeByCategory[transaction.category] ?? 0) + transaction.amount;
        } else {
          totalExpense += transaction.amount;
          expensesByCategory[transaction.category] =
              (expensesByCategory[transaction.category] ?? 0) + transaction.amount;
        }
      }

      return MonthlyStats(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: totalIncome - totalExpense,
        expensesByCategory: expensesByCategory,
        incomeByCategory: incomeByCategory,
      );
    } catch (e) {
      throw 'Erro ao calcular estatísticas mensais: $e';
    }
  }

  // Gamification Methods
  Future<void> _awardPoints(String userId, int points) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.update({
        'points': FieldValue.increment(points),
      });
    } catch (e) {
      // Silent fail for points - non-critical feature
    }
  }

  Future<void> checkAndAwardAchievements(String userId) async {
    try {
      final user = await getUserData(userId);
      if (user == null) return;

      final currentMonth = DateTime.now();
      final stats = await getMonthlyStats(userId, currentMonth);

      List<String> newAchievements = List.from(user.achievements);
      bool hasNewAchievement = false;

      // First transaction achievement
      if (!newAchievements.contains('first_transaction') &&
          (stats.totalIncome > 0 || stats.totalExpense > 0)) {
        newAchievements.add('first_transaction');
        hasNewAchievement = true;
      }

      // Budget keeper achievement (didn\\'t exceed monthly goal)
      if (!newAchievements.contains('budget_keeper') &&
          user.monthlyGoal > 0 &&
          stats.totalExpense <= user.monthlyGoal) {
        newAchievements.add('budget_keeper');
        hasNewAchievement = true;
      }

      if (hasNewAchievement) {
        await updateUserData(user.copyWith(
          achievements: newAchievements,
          points: user.points + 50, // Bonus points for achievements
        ));
      }
    } catch (e) {
      // Silent fail for achievements - non-critical feature
    }
  }

  // Helper Methods
  String _getCurrentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Nenhum usuário encontrado com este email.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Este email já está sendo usado.';
      case 'weak-password':
        return 'A senha é muito fraca.';
      case 'invalid-email':
        return 'Email inválido.';
      case 'user-disabled':
        return 'Este usuário foi desabilitado.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      default:
        return 'Erro de autenticação: ${e.message}';
    }
  }
}