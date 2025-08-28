import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/database_service.dart';

class CategoryProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Categorias padrão para receitas
  static const List<Map<String, dynamic>> defaultIncomeCategories = [
    {'nome': 'Salário', 'tipo': 'income', 'icone': '💰', 'cor': '#4CAF50'},
    {'nome': 'Freelance', 'tipo': 'income', 'icone': '💼', 'cor': '#2196F3'},
    {'nome': 'Investimentos', 'tipo': 'income', 'icone': '📈', 'cor': '#FF9800'},
    {'nome': 'Presentes', 'tipo': 'income', 'icone': '🎁', 'cor': '#E91E63'},
    {'nome': 'Outros', 'tipo': 'income', 'icone': '➕', 'cor': '#9C27B0'},
  ];

  // Categorias padrão para despesas
  static const List<Map<String, dynamic>> defaultExpenseCategories = [
    {'nome': 'Alimentação', 'tipo': 'expense', 'icone': '🍽️', 'cor': '#F44336'},
    {'nome': 'Transporte', 'tipo': 'expense', 'icone': '🚗', 'cor': '#607D8B'},
    {'nome': 'Moradia', 'tipo': 'expense', 'icone': '🏠', 'cor': '#795548'},
    {'nome': 'Saúde', 'tipo': 'expense', 'icone': '🏥', 'cor': '#E91E63'},
    {'nome': 'Educação', 'tipo': 'expense', 'icone': '📚', 'cor': '#3F51B5'},
    {'nome': 'Lazer', 'tipo': 'expense', 'icone': '🎮', 'cor': '#FF5722'},
    {'nome': 'Vestuário', 'tipo': 'expense', 'icone': '👕', 'cor': '#9C27B0'},
    {'nome': 'Contas', 'tipo': 'expense', 'icone': '📱', 'cor': '#607D8B'},
    {'nome': 'Outros', 'tipo': 'expense', 'icone': '💸', 'cor': '#757575'},
  ];

  // Carregar todas as categorias
  Future<void> loadCategories() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _categories = await _databaseService.getCategories();
      
      // Se não há categorias, criar as padrão
      if (_categories.isEmpty) {
        await _createDefaultCategories();
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar categorias: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Criar categorias padrão
  Future<void> _createDefaultCategories() async {
    try {
      final now = DateTime.now();
      
      // Criar categorias de receita
      for (final categoryData in defaultIncomeCategories) {
        final category = Category(
          name: categoryData['nome'],
          type: categoryData['tipo'],
          icon: categoryData['icone'],
          color: categoryData['cor'],
          userId: 1, // TODO: Pegar do usuário logado
          createdAt: now,
          updatedAt: now,
        );
        await _databaseService.insertCategory(category);
      }

      // Criar categorias de despesa
      for (final categoryData in defaultExpenseCategories) {
        final category = Category(
          name: categoryData['nome'],
          type: categoryData['tipo'],
          icon: categoryData['icone'],
          color: categoryData['cor'],
          userId: 1, // TODO: Pegar do usuário logado
          createdAt: now,
          updatedAt: now,
        );
        await _databaseService.insertCategory(category);
      }

      // Recarregar categorias
      _categories = await _databaseService.getCategories();
    } catch (e) {
      _error = 'Erro ao criar categorias padrão: $e';
    }
  }

  // Adicionar nova categoria
  Future<bool> addCategory(String name, String type, String? icon, String? color) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final now = DateTime.now();
      final category = Category(
        name: name,
        type: type,
        icon: icon ?? '📁',
        color: color ?? '#757575',
        userId: 1, // TODO: Pegar do usuário logado
        createdAt: now,
        updatedAt: now,
      );

      final categoryId = await _databaseService.insertCategory(category);
      if (categoryId > 0) {
        final newCategory = category.copyWith(id: categoryId);
        _categories.add(newCategory);
        _categories.sort((a, b) => a.name.compareTo(b.name));
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erro ao adicionar categoria';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erro ao adicionar categoria: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Atualizar categoria
  Future<bool> updateCategory(Category category) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedCategory = category.copyWith(updatedAt: DateTime.now());
      final result = await _databaseService.updateCategory(updatedCategory);
      
      if (result > 0) {
        final index = _categories.indexWhere((c) => c.id == category.id);
        if (index != -1) {
          _categories[index] = updatedCategory;
          _categories.sort((a, b) => a.name.compareTo(b.name));
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erro ao atualizar categoria';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erro ao atualizar categoria: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Deletar categoria
  Future<bool> deleteCategory(int id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _databaseService.deleteCategory(id);
      if (result > 0) {
        _categories.removeWhere((category) => category.id == id);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erro ao deletar categoria';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erro ao deletar categoria: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Buscar categoria por ID
  Category? getCategoryById(int id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  // Buscar categorias por tipo
  List<Category> getCategoriesByType(String type) {
    return _categories.where((category) => category.type == type).toList();
  }

  // Buscar categorias de receita
  List<Category> get incomeCategories => getCategoriesByType('income');

  // Buscar categorias de despesa
  List<Category> get expenseCategories => getCategoriesByType('expense');

  // Limpar erro
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
