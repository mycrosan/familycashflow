import 'package:flutter/material.dart';
import '../models/member.dart';
import '../services/database_service.dart';

class MemberProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Member> _members = [];
  bool _isLoading = false;
  String? _error;

  List<Member> get members => _members;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Carregar todos os membros
  Future<void> loadMembers() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _members = await _databaseService.getMembers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar membros: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Adicionar novo membro
  Future<bool> addMember(String name, String relation, String? profilePicture) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final now = DateTime.now();
      final member = Member(
        name: name,
        relation: relation,
        profilePicture: profilePicture,
        userId: 1, // TODO: Pegar do usuário logado
        createdAt: now,
        updatedAt: now,
      );

      final memberId = await _databaseService.insertMember(member);
      if (memberId > 0) {
        final newMember = member.copyWith(id: memberId);
        _members.add(newMember);
        _members.sort((a, b) => a.name.compareTo(b.name));
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erro ao adicionar membro';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erro ao adicionar membro: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Atualizar membro
  Future<bool> updateMember(Member member) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedMember = member.copyWith(updatedAt: DateTime.now());
      final result = await _databaseService.updateMember(updatedMember);
      
      if (result > 0) {
        final index = _members.indexWhere((m) => m.id == member.id);
        if (index != -1) {
          _members[index] = updatedMember;
          _members.sort((a, b) => a.name.compareTo(b.name));
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erro ao atualizar membro';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erro ao atualizar membro: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Deletar membro
  Future<bool> deleteMember(int id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _databaseService.deleteMember(id);
      if (result > 0) {
        _members.removeWhere((member) => member.id == id);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erro ao deletar membro';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erro ao deletar membro: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Buscar membro por ID
  Member? getMemberById(int id) {
    try {
      return _members.firstWhere((member) => member.id == id);
    } catch (e) {
      return null;
    }
  }

  // Buscar membros por relação
  List<Member> getMembersByRelation(String relation) {
    return _members.where((member) => member.relation == relation).toList();
  }

  // Limpar erro
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
