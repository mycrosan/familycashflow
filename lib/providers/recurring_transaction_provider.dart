import 'package:flutter/material.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../models/member.dart';
import '../services/database_service.dart';

class RecurringTransactionProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<RecurringTransaction> _recurringTransactions = [];
  bool _isLoading = false;
  String? _error;

  List<RecurringTransaction> get recurringTransactions => _recurringTransactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Carregar todas as transações recorrentes
  Future<void> loadRecurringTransactions() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _recurringTransactions = await _databaseService.getRecurringTransactions();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar transações recorrentes: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Adicionar nova transação recorrente
  Future<bool> addRecurringTransaction({
    required String frequency,
    required String category,
    required double value,
    required int associatedMemberId,
    required DateTime startDate,
    DateTime? endDate,
    int? maxOccurrences,
    String? notes,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final now = DateTime.now();
      final recurringTransaction = RecurringTransaction(
        frequency: frequency,
        category: category,
        value: value,
        associatedMember: Member(
          id: associatedMemberId,
          name: 'Membro',
          relation: 'Familiar',
          userId: 1,
          createdAt: now,
          updatedAt: now,
        ),
        startDate: startDate,
        endDate: endDate,
        maxOccurrences: maxOccurrences,
        isActive: 1,
        notes: notes,
        userId: 1, // TODO: Pegar do usuário logado
        createdAt: now,
        updatedAt: now,
      );

      final recurringTransactionId = await _databaseService.insertRecurringTransaction(recurringTransaction);
      if (recurringTransactionId > 0) {
        final newRecurringTransaction = recurringTransaction.copyWith(id: recurringTransactionId);
        _recurringTransactions.add(newRecurringTransaction);
        _recurringTransactions.sort((a, b) => a.startDate.compareTo(b.startDate));
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erro ao adicionar transação recorrente';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erro ao adicionar transação recorrente: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Atualizar transação recorrente
  Future<bool> updateRecurringTransaction(RecurringTransaction recurringTransaction) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedRecurringTransaction = recurringTransaction.copyWith(updatedAt: DateTime.now());
      final result = await _databaseService.updateRecurringTransaction(updatedRecurringTransaction);
      
      if (result > 0) {
        final index = _recurringTransactions.indexWhere((rt) => rt.id == recurringTransaction.id);
        if (index != -1) {
          _recurringTransactions[index] = updatedRecurringTransaction;
          _recurringTransactions.sort((a, b) => a.startDate.compareTo(b.startDate));
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erro ao atualizar transação recorrente';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erro ao atualizar transação recorrente: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Deletar transação recorrente
  Future<bool> deleteRecurringTransaction(int id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _databaseService.deleteRecurringTransaction(id);
      if (result > 0) {
        _recurringTransactions.removeWhere((rt) => rt.id == id);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erro ao deletar transação recorrente';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erro ao deletar transação recorrente: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Ativar/desativar transação recorrente
  Future<bool> toggleRecurringTransaction(int id, int isActive) async {
    try {
      final recurringTransaction = _recurringTransactions.firstWhere((rt) => rt.id == id);
      final updatedRecurringTransaction = recurringTransaction.copyWith(
        isActive: isActive,
        updatedAt: DateTime.now(),
      );

      return await updateRecurringTransaction(updatedRecurringTransaction);
    } catch (e) {
      _error = 'Erro ao alterar status da transação recorrente: $e';
      notifyListeners();
      return false;
    }
  }

  // Gerar transações baseadas nas recorrentes
  Future<List<Transaction>> generateTransactionsFromRecurring({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final transactions = <Transaction>[];
    
    for (final recurringTransaction in _recurringTransactions) {
      if (recurringTransaction.isActive != 1) continue;
      
      final dates = _getRecurringDates(
        recurringTransaction.startDate,
        endDate,
        recurringTransaction.frequency,
        recurringTransaction.maxOccurrences,
        recurringTransaction.endDate,
      );

      for (final date in dates) {
        if (date.isAfter(startDate.subtract(const Duration(days: 1)))) {
          final transaction = Transaction(
            value: recurringTransaction.value,
            date: date,
            category: recurringTransaction.category,
            associatedMember: recurringTransaction.associatedMember,
            notes: recurringTransaction.notes ?? 'Transação recorrente',
            recurringTransactionId: recurringTransaction.id,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          transactions.add(transaction);
        }
      }
    }

    return transactions;
  }

  // Calcular datas recorrentes
  List<DateTime> _getRecurringDates(
    DateTime startDate,
    DateTime endDate,
    String frequency,
    int? maxOccurrences,
    DateTime? endDateLimit,
  ) {
    final dates = <DateTime>[];
    DateTime currentDate = startDate;
    int occurrences = 0;

    while (currentDate.isBefore(endDate) && 
           (maxOccurrences == null || occurrences < maxOccurrences) &&
           (endDateLimit == null || currentDate.isBefore(endDateLimit))) {
      
      dates.add(currentDate);
      occurrences++;

      switch (frequency) {
        case 'daily':
          currentDate = currentDate.add(const Duration(days: 1));
          break;
        case 'weekly':
          currentDate = currentDate.add(const Duration(days: 7));
          break;
        case 'monthly':
          currentDate = DateTime(
            currentDate.year,
            currentDate.month + 1,
            currentDate.day,
          );
          break;
        case 'yearly':
          currentDate = DateTime(
            currentDate.year + 1,
            currentDate.month,
            currentDate.day,
          );
          break;
      }
    }

    return dates;
  }

  // Buscar transações recorrentes por frequência
  List<RecurringTransaction> getRecurringTransactionsByFrequency(String frequency) {
    return _recurringTransactions.where((rt) => rt.frequency == frequency).toList();
  }

  // Buscar transações recorrentes ativas
  List<RecurringTransaction> get activeRecurringTransactions => 
      _recurringTransactions.where((rt) => rt.isActive == 1).toList();

  // Buscar transações recorrentes por membro
  List<RecurringTransaction> getRecurringTransactionsByMember(int memberId) {
    return _recurringTransactions.where((rt) => rt.associatedMember.id == memberId).toList();
  }

  // Limpar erro
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
