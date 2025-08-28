import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';
import '../models/member.dart';
import '../models/category.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.0.109:5000'; // Ajuste conforme seu backend
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // Método para adicionar token de autenticação
  static void setAuthToken(String token) {
    _headers['Authorization'] = 'Bearer $token';
  }

  // Tratamento de erros
  static void _handleError(http.Response response) {
    if (response.statusCode >= 400) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Erro na requisição');
    }
  }

  // === TRANSACTIONS ===
  
  // Sincronizar transações
  static Future<void> syncTransactions(List<Transaction> transactions) async {
    final uri = Uri.parse('$baseUrl/transactions/sync');
    final response = await http.post(
      uri,
      headers: _headers,
      body: json.encode({
        'transactions': transactions.map((t) => t.toJson()).toList(),
      }),
    );
    _handleError(response);
  }

  // Obter transações
  static Future<List<Transaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    int? memberId,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
    if (category != null) queryParams['category'] = category;
    if (memberId != null) queryParams['member_id'] = memberId.toString();

    final uri = Uri.parse('$baseUrl/transactions').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    _handleError(response);

    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => Transaction.fromJson(json)).toList();
  }

  // Criar transação
  static Future<Transaction> createTransaction(Transaction transaction) async {
    final uri = Uri.parse('$baseUrl/transactions');
    final response = await http.post(
      uri,
      headers: _headers,
      body: json.encode(transaction.toJson()),
    );
    _handleError(response);

    return Transaction.fromJson(json.decode(response.body));
  }

  // Atualizar transação
  static Future<Transaction> updateTransaction(int id, Transaction transaction) async {
    final uri = Uri.parse('$baseUrl/transactions/$id');
    final response = await http.put(
      uri,
      headers: _headers,
      body: json.encode(transaction.toJson()),
    );
    _handleError(response);

    return Transaction.fromJson(json.decode(response.body));
  }

  // Deletar transação
  static Future<void> deleteTransaction(int id) async {
    final uri = Uri.parse('$baseUrl/transactions/$id');
    final response = await http.delete(uri, headers: _headers);
    _handleError(response);
  }

  // === MEMBERS ===

  // Obter membros
  static Future<List<Member>> getMembers() async {
    final uri = Uri.parse('$baseUrl/members');
    final response = await http.get(uri, headers: _headers);
    _handleError(response);

    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => Member.fromJson(json)).toList();
  }

  // Criar membro
  static Future<Member> createMember(Member member) async {
    final uri = Uri.parse('$baseUrl/members');
    final response = await http.post(
      uri,
      headers: _headers,
      body: json.encode(member.toJson()),
    );
    _handleError(response);

    return Member.fromJson(json.decode(response.body));
  }

  // Atualizar membro
  static Future<Member> updateMember(int id, Member member) async {
    final uri = Uri.parse('$baseUrl/members/$id');
    final response = await http.put(
      uri,
      headers: _headers,
      body: json.encode(member.toJson()),
    );
    _handleError(response);

    return Member.fromJson(json.decode(response.body));
  }

  // Deletar membro
  static Future<void> deleteMember(int id) async {
    final uri = Uri.parse('$baseUrl/members/$id');
    final response = await http.delete(uri, headers: _headers);
    _handleError(response);
  }

  // === CATEGORIES ===

  // Obter categorias
  static Future<List<Category>> getCategories() async {
    final uri = Uri.parse('$baseUrl/categories');
    final response = await http.get(uri, headers: _headers);
    _handleError(response);

    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => Category.fromJson(json)).toList();
  }

  // Criar categoria
  static Future<Category> createCategory(Category category) async {
    final uri = Uri.parse('$baseUrl/categories');
    final response = await http.post(
      uri,
      headers: _headers,
      body: json.encode(category.toJson()),
    );
    _handleError(response);

    return Category.fromJson(json.decode(response.body));
  }

  // Atualizar categoria
  static Future<Category> updateCategory(int id, Category category) async {
    final uri = Uri.parse('$baseUrl/categories/$id');
    final response = await http.put(
      uri,
      headers: _headers,
      body: json.encode(category.toJson()),
    );
    _handleError(response);

    return Category.fromJson(json.decode(response.body));
  }

  // Deletar categoria
  static Future<void> deleteCategory(int id) async {
    final uri = Uri.parse('$baseUrl/categories/$id');
    final response = await http.delete(uri, headers: _headers);
    _handleError(response);
  }

  // === AUTH ===

  // Login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      uri,
      headers: _headers,
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );
    _handleError(response);

    return json.decode(response.body);
  }

  // Registro
  static Future<User> register(User user) async {
    final uri = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(
      uri,
      headers: _headers,
      body: json.encode(user.toJson()),
    );
    _handleError(response);

    return User.fromJson(json.decode(response.body));
  }

  // === REPORTS ===

  // Relatório mensal
  static Future<Map<String, dynamic>> getMonthlyReport(int year, int month) async {
    final uri = Uri.parse('$baseUrl/reports/monthly/$year/$month');
    final response = await http.get(uri, headers: _headers);
    _handleError(response);

    return json.decode(response.body);
  }

  // Relatório por categoria
  static Future<Map<String, dynamic>> getCategoryReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

    final uri = Uri.parse('$baseUrl/reports/categories').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    _handleError(response);

    return json.decode(response.body);
  }

  // === SYNC STATUS ===

  // Verificar status de sincronização
  static Future<Map<String, dynamic>> getSyncStatus() async {
    final uri = Uri.parse('$baseUrl/sync/status');
    final response = await http.get(uri, headers: _headers);
    _handleError(response);

    return json.decode(response.body);
  }
}
