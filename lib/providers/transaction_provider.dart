import 'package:flutter/foundation.dart' hide Category;
import '../models/transaction.dart';
import '../models/member.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  List<Transaction> _transactions = [];
  List<Member> _members = [];
  List<Category> _categories = [];
  
  bool _isLoading = false;
  String? _error;
  DateTime _selectedMonth = DateTime.now();
  
  // Getters
  List<Transaction> get transactions => _transactions;
  List<Member> get members => _members;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedMonth => _selectedMonth;
  
  // Cálculos financeiros
  double get totalIncome {
    return _transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.absoluteValue);
  }
  
  double get totalExpenses {
    return _transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.absoluteValue);
  }
  
  double get balance => totalIncome - totalExpenses;
  
  // Transações do mês selecionado
  List<Transaction> get monthlyTransactions {
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    
    return _transactions.where((t) {
      return t.date.isAfter(startOfMonth.subtract(Duration(days: 1))) &&
             t.date.isBefore(endOfMonth.add(Duration(days: 1)));
    }).toList();
  }
  
  // Transações agrupadas por data
  Map<String, List<Transaction>> get transactionsByDate {
    final grouped = <String, List<Transaction>>{};
    
    for (final transaction in monthlyTransactions) {
      final dateKey = _formatDateKey(transaction.date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }
    
    // Ordenar por data (mais recente primeiro)
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));
    
    final sortedMap = <String, List<Transaction>>{};
    for (final key in sortedKeys) {
      sortedMap[key] = grouped[key]!;
    }
    
    return sortedMap;
  }
  
  // Transações agrupadas por categoria
  Map<String, List<Transaction>> get transactionsByCategory {
    final grouped = <String, List<Transaction>>{};
    
    for (final transaction in monthlyTransactions) {
      if (!grouped.containsKey(transaction.category)) {
        grouped[transaction.category] = [];
      }
      grouped[transaction.category]!.add(transaction);
    }
    
    return grouped;
  }
  
  // Transações agrupadas por membro
  Map<String, List<Transaction>> get transactionsByMember {
    final grouped = <String, List<Transaction>>{};
    
    for (final transaction in monthlyTransactions) {
      final memberName = transaction.associatedMember.name;
      if (!grouped.containsKey(memberName)) {
        grouped[memberName] = [];
      }
      grouped[memberName]!.add(transaction);
    }
    
    return grouped;
  }

  // === MÉTODOS PRINCIPAIS ===

  // Carregar transações do mês selecionado
  Future<void> loadMonthlyTransactions() async {
    _setLoading(true);
    _clearError();
    
    try {
      final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
      
      _transactions = await _databaseService.getTransactions(
        startDate: startOfMonth,
        endDate: endOfMonth,
      );
      
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar transações: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Carregar transações para um mês específico
  Future<void> loadTransactionsForMonth(DateTime month) async {
    _selectedMonth = month;
    await loadMonthlyTransactions();
  }

  // Obter transações para um mês específico
  List<Transaction> getTransactionsForMonth(DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    
    return _transactions.where((t) {
      return t.date.isAfter(startOfMonth.subtract(Duration(days: 1))) &&
             t.date.isBefore(endOfMonth.add(Duration(days: 1)));
    }).toList();
  }

  // Carregar todas as transações
  Future<void> loadAllTransactions() async {
    _setLoading(true);
    _clearError();
    
    try {
      _transactions = await _databaseService.getTransactions();
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar transações: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Carregar membros
  Future<void> loadMembers() async {
    try {
      _members = await _databaseService.getMembers();
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar membros: $e');
    }
  }

  // Carregar categorias
  Future<void> loadCategories() async {
    try {
      _categories = await _databaseService.getCategories();
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar categorias: $e');
    }
  }

  // Adicionar transação
  Future<void> addTransaction(Transaction transaction) async {
    _setLoading(true);
    _clearError();
    
    try {
      final id = await _databaseService.insertTransaction(transaction);
      final newTransaction = transaction.copyWith(id: id);
      
      // Log para sincronização
      await _databaseService.logSyncAction('lancamentos', id, 'create');
      
      // Atualizar lista de forma inteligente
      await updateAfterAddTransaction(newTransaction);
      
    } catch (e) {
      _setError('Erro ao adicionar transação: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Atualizar transação
  Future<bool> updateTransaction(Transaction transaction) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _databaseService.updateTransaction(transaction);
      
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
        _sortTransactions();
      }
      
      // Log para sincronização
      if (transaction.id != null) {
        await _databaseService.logSyncAction('lancamentos', transaction.id!, 'update');
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao atualizar transação: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Deletar transação
  Future<bool> deleteTransaction(int id) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _databaseService.deleteTransaction(id);
      
      _transactions.removeWhere((t) => t.id == id);
      
      // Log para sincronização
      await _databaseService.logSyncAction('lancamentos', id, 'delete');
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao deletar transação: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Alterar mês selecionado
  void changeMonth(DateTime month) {
    _selectedMonth = month;
    loadMonthlyTransactions();
  }

  // Filtrar transações
  List<Transaction> filterTransactions({
    String? category,
    int? memberId,
    bool? isIncome,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _transactions.where((transaction) {
      if (category != null && transaction.category != category) return false;
      if (memberId != null && transaction.associatedMember.id != memberId) return false;
      if (isIncome != null && transaction.isIncome != isIncome) return false;
      if (startDate != null && transaction.date.isBefore(startDate)) return false;
      if (endDate != null && transaction.date.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  // Buscar transação por ID
  Transaction? getTransactionById(int id) {
    try {
      return _transactions.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  // Sincronizar com o servidor
  Future<void> syncWithServer() async {
    _setLoading(true);
    _clearError();
    
    try {
      // Obter ações pendentes
      final pendingActions = await _databaseService.getPendingSyncActions();
      
      if (pendingActions.isEmpty) {
        return; // Nada para sincronizar
      }
      
      // Fazer upload das transações pendentes
      final pendingTransactions = _transactions.where((t) => !t.isSynced).toList();
      
      if (pendingTransactions.isNotEmpty) {
        await ApiService.syncTransactions(pendingTransactions);
        
        // Marcar como sincronizadas
        for (final transaction in pendingTransactions) {
          if (transaction.id != null) {
            await _databaseService.markSyncActionAsSynced(transaction.id!);
          }
        }
      }
      
      // Fazer download de novas transações do servidor
      final serverTransactions = await ApiService.getTransactions();
      
      // Mesclar com transações locais
      for (final serverTransaction in serverTransactions) {
        final localIndex = _transactions.indexWhere((t) => t.id == serverTransaction.id);
        
        if (localIndex == -1) {
          // Nova transação do servidor
          _transactions.add(serverTransaction);
        } else {
          // Atualizar transação existente
          _transactions[localIndex] = serverTransaction;
        }
      }
      
      _sortTransactions();
      notifyListeners();
      
    } catch (e) {
      _setError('Erro na sincronização: $e');
    } finally {
      _setLoading(false);
    }
  }

  // === MÉTODOS AUXILIARES ===

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _sortTransactions() {
    _transactions.sort((a, b) => b.date.compareTo(a.date));
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Limpar erros
  void clearError() {
    _clearError();
  }

  // Refresh dos dados
  Future<void> refresh() async {
    await Future.wait([
      loadMonthlyTransactions(),
      loadMembers(),
      loadCategories(),
    ]);
  }

  // Atualizar lista após adicionar transação
  Future<void> updateAfterAddTransaction(Transaction transaction) async {
    try {
      // Se a transação é do mês atual, recarregar transações do mês
      final currentMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final transactionMonth = DateTime(transaction.date.year, transaction.date.month, 1);
      
      if (currentMonth.isAtSameMomentAs(transactionMonth)) {
        // Recarregar transações do mês para garantir que a nova transação apareça
        await loadMonthlyTransactions();
      } else {
        // Se não é do mês atual, apenas adicionar à lista geral
        _transactions.add(transaction);
        _sortTransactions();
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao atualizar lista após adicionar transação: $e');
    }
  }

  // Inicialização
  Future<void> initialize() async {
    await Future.wait([
      loadMembers(),
      loadCategories(),
      loadMonthlyTransactions(),
    ]);
  }
}
