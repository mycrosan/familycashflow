import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/member.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';

class ReportProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Dados do relatório mensal
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  double _balance = 0.0;
  List<Transaction> _monthlyTransactions = [];
  Map<String, double> _expensesByCategory = {};
  Map<String, double> _incomeByCategory = {};
  Map<String, double> _expensesByMember = {};
  Map<String, double> _incomeByMember = {};

  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get balance => _balance;
  List<Transaction> get monthlyTransactions => _monthlyTransactions;
  Map<String, double> get expensesByCategory => _expensesByCategory;
  Map<String, double> get incomeByCategory => _incomeByCategory;
  Map<String, double> get expensesByMember => _expensesByMember;
  Map<String, double> get incomeByMember => _incomeByMember;

  // Gerar relatório mensal
  Future<void> generateMonthlyReport(DateTime month) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 0);

      // Buscar transações do mês
      _monthlyTransactions = await _databaseService.getTransactions(
        startDate: startDate,
        endDate: endDate,
      );

      // Calcular totais
      _calculateTotals();
      
      // Calcular dados por categoria
      _calculateDataByCategory();
      
      // Calcular dados por membro
      _calculateDataByMember();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao gerar relatório: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Calcular totais
  void _calculateTotals() {
    _totalIncome = 0.0;
    _totalExpense = 0.0;

    for (final transaction in _monthlyTransactions) {
      if (transaction.value > 0) {
        _totalIncome += transaction.value;
      } else {
        _totalExpense += transaction.value.abs();
      }
    }

    _balance = _totalIncome - _totalExpense;
  }

  // Calcular dados por categoria
  void _calculateDataByCategory() {
    _expensesByCategory.clear();
    _incomeByCategory.clear();

    for (final transaction in _monthlyTransactions) {
      final category = transaction.category;
      final value = transaction.value.abs();

      if (transaction.value > 0) {
        _incomeByCategory[category] = (_incomeByCategory[category] ?? 0.0) + value;
      } else {
        _expensesByCategory[category] = (_expensesByCategory[category] ?? 0.0) + value;
      }
    }
  }

  // Calcular dados por membro
  void _calculateDataByMember() {
    _expensesByMember.clear();
    _incomeByMember.clear();

    for (final transaction in _monthlyTransactions) {
      final memberName = transaction.associatedMember.name;
      final value = transaction.value.abs();

      if (transaction.value > 0) {
        _incomeByMember[memberName] = (_incomeByMember[memberName] ?? 0.0) + value;
      } else {
        _expensesByMember[memberName] = (_expensesByMember[memberName] ?? 0.0) + value;
      }
    }
  }

  // Gerar relatório por período personalizado
  Future<Map<String, dynamic>> generateCustomReport({
    required DateTime startDate,
    required DateTime endDate,
    String? category,
    int? memberId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final transactions = await _databaseService.getTransactions(
        startDate: startDate,
        endDate: endDate,
        category: category,
        memberId: memberId,
      );

      double totalIncome = 0.0;
      double totalExpense = 0.0;
      Map<String, double> expensesByCategory = {};
      Map<String, double> incomeByCategory = {};

      for (final transaction in transactions) {
        final categoryName = transaction.category;
        final value = transaction.value.abs();

        if (transaction.value > 0) {
          totalIncome += transaction.value;
          incomeByCategory[categoryName] = (incomeByCategory[categoryName] ?? 0.0) + value;
        } else {
          totalExpense += transaction.value.abs();
          expensesByCategory[categoryName] = (expensesByCategory[categoryName] ?? 0.0) + value;
        }
      }

      _isLoading = false;
      notifyListeners();

      return {
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'balance': totalIncome - totalExpense,
        'transactions': transactions,
        'expensesByCategory': expensesByCategory,
        'incomeByCategory': incomeByCategory,
      };
    } catch (e) {
      _error = 'Erro ao gerar relatório personalizado: $e';
      _isLoading = false;
      notifyListeners();
      return {};
    }
  }

  // Gerar relatório anual
  Future<Map<String, dynamic>> generateAnnualReport(int year) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year, 12, 31);

      final transactions = await _databaseService.getTransactions(
        startDate: startDate,
        endDate: endDate,
      );

      Map<int, double> monthlyIncome = {};
      Map<int, double> monthlyExpense = {};
      Map<int, double> monthlyBalance = {};

      // Inicializar todos os meses
      for (int month = 1; month <= 12; month++) {
        monthlyIncome[month] = 0.0;
        monthlyExpense[month] = 0.0;
        monthlyBalance[month] = 0.0;
      }

      // Calcular dados mensais
      for (final transaction in transactions) {
        final month = transaction.date.month;
        if (transaction.value > 0) {
          monthlyIncome[month] = (monthlyIncome[month] ?? 0.0) + transaction.value;
        } else {
          monthlyExpense[month] = (monthlyExpense[month] ?? 0.0) + transaction.value.abs();
        }
      }

      // Calcular saldo mensal
      for (int month = 1; month <= 12; month++) {
        monthlyBalance[month] = (monthlyIncome[month] ?? 0.0) - (monthlyExpense[month] ?? 0.0);
      }

      _isLoading = false;
      notifyListeners();

      return {
        'year': year,
        'monthlyIncome': monthlyIncome,
        'monthlyExpense': monthlyExpense,
        'monthlyBalance': monthlyBalance,
        'totalIncome': monthlyIncome.values.fold(0.0, (sum, value) => sum + value),
        'totalExpense': monthlyExpense.values.fold(0.0, (sum, value) => sum + value),
        'transactions': transactions,
      };
    } catch (e) {
      _error = 'Erro ao gerar relatório anual: $e';
      _isLoading = false;
      notifyListeners();
      return {};
    }
  }

  // Obter top categorias de despesa
  List<MapEntry<String, double>> getTopExpenseCategories({int limit = 5}) {
    final sortedCategories = _expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedCategories.take(limit).toList();
  }

  // Obter top categorias de receita
  List<MapEntry<String, double>> getTopIncomeCategories({int limit = 5}) {
    final sortedCategories = _incomeByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedCategories.take(limit).toList();
  }

  // Obter top membros por despesa
  List<MapEntry<String, double>> getTopExpenseMembers({int limit = 5}) {
    final sortedMembers = _expensesByMember.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedMembers.take(limit).toList();
  }

  // Obter top membros por receita
  List<MapEntry<String, double>> getTopIncomeMembers({int limit = 5}) {
    final sortedMembers = _incomeByMember.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedMembers.take(limit).toList();
  }

  // Formatar valor monetário
  String formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  // Formatar percentual
  String formatPercentage(double value, double total) {
    if (total == 0) return '0%';
    final percentage = (value / total) * 100;
    return '${percentage.toStringAsFixed(1)}%';
  }

  // Limpar erro
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
