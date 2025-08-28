import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/member.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';

class QuickEntryProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final Uuid _uuid = Uuid();
  
  bool _isLoading = false;
  String? _error;
  List<Transaction> _recentTransactions = [];
  List<Category> _favoriteCategories = [];
  List<Member> _favoriteMembers = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Transaction> get recentTransactions => _recentTransactions;
  List<Category> get favoriteCategories => _favoriteCategories;
  List<Member> get favoriteMembers => _favoriteMembers;

  // Adicionar transação rápida
  Future<bool> addQuickTransaction({
    required double value,
    required String category,
    required int memberId,
    String? notes,
    String? receiptImage,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final now = DateTime.now();
      final transaction = Transaction(
        value: value,
        date: now,
        category: category,
        associatedMember: Member(
          id: memberId,
          name: 'Membro',
          relation: 'Familiar',
          userId: 1,
          createdAt: now,
          updatedAt: now,
        ),
        notes: notes,
        receiptImage: receiptImage,
        createdAt: now,
        updatedAt: now,
      );

      final transactionId = await _databaseService.insertTransaction(transaction);
      if (transactionId > 0) {
        final newTransaction = transaction.copyWith(id: transactionId);
        _recentTransactions.insert(0, newTransaction);
        
        // Manter apenas as últimas 10 transações
        if (_recentTransactions.length > 10) {
          _recentTransactions = _recentTransactions.take(10).toList();
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erro ao adicionar transação';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erro ao adicionar transação: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Adicionar receita rápida
  Future<bool> addQuickIncome({
    required double value,
    required String category,
    required int memberId,
    String? notes,
  }) async {
    return await addQuickTransaction(
      value: value.abs(),
      category: category,
      memberId: memberId,
      notes: notes,
    );
  }

  // Adicionar despesa rápida
  Future<bool> addQuickExpense({
    required double value,
    required String category,
    required int memberId,
    String? notes,
  }) async {
    return await addQuickTransaction(
      value: -value.abs(),
      category: category,
      memberId: memberId,
      notes: notes,
    );
  }

  // Carregar transações recentes
  Future<void> loadRecentTransactions({int limit = 10}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 30)); // Últimos 30 dias
      
      final transactions = await _databaseService.getTransactions(
        startDate: startDate,
        endDate: now,
      );

      _recentTransactions = transactions.take(limit).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar transações recentes: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Carregar categorias favoritas
  Future<void> loadFavoriteCategories() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Por enquanto, usar as categorias mais usadas
      final allCategories = await _databaseService.getCategories();
      
      // Simular categorias favoritas baseadas no uso
      _favoriteCategories = allCategories.take(5).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar categorias favoritas: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Carregar membros favoritos
  Future<void> loadFavoriteMembers() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final allMembers = await _databaseService.getMembers();
      
      // Por enquanto, usar os primeiros membros
      _favoriteMembers = allMembers.take(3).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar membros favoritos: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Adicionar categoria aos favoritos
  Future<void> addFavoriteCategory(Category category) async {
    if (!_favoriteCategories.contains(category)) {
      _favoriteCategories.add(category);
      notifyListeners();
    }
  }

  // Remover categoria dos favoritos
  Future<void> removeFavoriteCategory(Category category) async {
    _favoriteCategories.remove(category);
    notifyListeners();
  }

  // Adicionar membro aos favoritos
  Future<void> addFavoriteMember(Member member) async {
    if (!_favoriteMembers.contains(member)) {
      _favoriteMembers.add(member);
      notifyListeners();
    }
  }

  // Remover membro dos favoritos
  Future<void> removeFavoriteMember(Member member) async {
    _favoriteMembers.remove(member);
    notifyListeners();
  }

  // Buscar transações por texto
  Future<List<Transaction>> searchTransactions(String query) async {
    try {
      if (query.isEmpty) return [];

      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 90)); // Últimos 90 dias
      
      final transactions = await _databaseService.getTransactions(
        startDate: startDate,
        endDate: now,
      );

      return transactions.where((transaction) {
        final searchText = query.toLowerCase();
        return transaction.category.toLowerCase().contains(searchText) ||
               (transaction.notes?.toLowerCase().contains(searchText) ?? false) ||
               (transaction.associatedMember.name.toLowerCase().contains(searchText) ?? false);
      }).toList();
    } catch (e) {
      _error = 'Erro ao buscar transações: $e';
      notifyListeners();
      return [];
    }
  }

  // Obter estatísticas rápidas
  Map<String, dynamic> getQuickStats() {
    if (_recentTransactions.isEmpty) {
      return {
        'totalIncome': 0.0,
        'totalExpense': 0.0,
        'balance': 0.0,
        'transactionCount': 0,
      };
    }

    double totalIncome = 0.0;
    double totalExpense = 0.0;

    for (final transaction in _recentTransactions) {
      if (transaction.value > 0) {
        totalIncome += transaction.value;
      } else {
        totalExpense += transaction.value.abs();
      }
    }

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'balance': totalIncome - totalExpense,
      'transactionCount': _recentTransactions.length,
    };
  }

  // Formatar valor para exibição
  String formatValue(double value) {
    final isPositive = value >= 0;
    final absValue = value.abs();
    final formattedValue = absValue.toStringAsFixed(2);
    
    return isPositive ? '+R\$ $formattedValue' : '-R\$ $formattedValue';
  }

  // Limpar erro
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Limpar transações recentes
  void clearRecentTransactions() {
    _recentTransactions.clear();
    notifyListeners();
  }
}
