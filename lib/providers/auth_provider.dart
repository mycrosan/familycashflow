import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Hash da senha para segurança
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Login do usuário
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final hashedPassword = _hashPassword(password);
      final user = await _databaseService.getUserByEmail(email);

      if (user != null && user.password == hashedPassword) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Email ou senha incorretos';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erro ao fazer login: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Registro de novo usuário
  Future<bool> register(String name, String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Verificar se o email já existe
      final existingUser = await _databaseService.getUserByEmail(email);
      if (existingUser != null) {
        _error = 'Email já cadastrado';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final hashedPassword = _hashPassword(password);
      final now = DateTime.now();
      
      final user = User(
        name: name,
        email: email,
        password: hashedPassword,
        createdAt: now,
        updatedAt: now,
      );

      final userId = await _databaseService.insertUser(user);
      if (userId > 0) {
        _currentUser = user.copyWith(id: userId);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erro ao criar usuário';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erro ao registrar: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  void logout() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  // Atualizar perfil do usuário
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? profilePicture,
  }) async {
    try {
      if (_currentUser == null) return false;

      final updatedUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        email: email ?? _currentUser!.email,
        profilePicture: profilePicture ?? _currentUser!.profilePicture,
        updatedAt: DateTime.now(),
      );

      final result = await _databaseService.updateUser(updatedUser);
      if (result > 0) {
        _currentUser = updatedUser;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Erro ao atualizar perfil: $e';
      notifyListeners();
      return false;
    }
  }

  // Alterar senha
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      if (_currentUser == null) return false;

      final currentHashedPassword = _hashPassword(currentPassword);
      if (_currentUser!.password != currentHashedPassword) {
        _error = 'Senha atual incorreta';
        notifyListeners();
        return false;
      }

      final newHashedPassword = _hashPassword(newPassword);
      final updatedUser = _currentUser!.copyWith(
        password: newHashedPassword,
        updatedAt: DateTime.now(),
      );

      final result = await _databaseService.updateUser(updatedUser);
      if (result > 0) {
        _currentUser = updatedUser;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Erro ao alterar senha: $e';
      notifyListeners();
      return false;
    }
  }

  // Limpar erro
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
