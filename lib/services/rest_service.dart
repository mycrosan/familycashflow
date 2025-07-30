import 'dart:convert';
import 'package:http/http.dart' as http;

class LancamentoService {
  static const String baseUrl = 'http://192.168.0.109:5000/lancamento';

  // GET /lancamento/mes/yyyy-MM
  Future<List<dynamic>> getMes(String anoMes) async {
    final response = await http.get(Uri.parse('$baseUrl/mes/$anoMes'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : [];
    } else {
      throw Exception('Erro ao carregar lançamentos do mês $anoMes');
    }
  }

  // GET /lancamento/{id}
  Future<Map<String, dynamic>> getById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao carregar lançamento $id');
    }
  }

  // POST /lancamento
  Future<void> post(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Erro ao salvar lançamento');
    }
  }

  // PUT /lancamento/{id}
  Future<void> put(int id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar lançamento');
    }
  }

  // DELETE /lancamento/{id}
  Future<void> delete(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 200) {
      throw Exception('Erro ao excluir lançamento');
    }
  }
}
