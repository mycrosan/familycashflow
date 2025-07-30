// lib/models/lancamento_model.dart

class Lancamento {
  final int id;
  final String descricao;
  final double valor;
  final String data;
  final String tipo;
  final bool simulado;

  Lancamento({
    required this.id,
    required this.descricao,
    required this.valor,
    required this.data,
    required this.tipo,
    required this.simulado,
  });

  // Factory constructor para criar um Lancamento a partir de um Map (JSON)
  factory Lancamento.fromJson(Map<String, dynamic> json) {
    return Lancamento(
      id: json['id'],
      descricao: json['descricao'] ?? 'Sem descrição',
      valor: (json['valor'] ?? 0.0).toDouble(), // Garante que o valor seja double
      data: json['data'] ?? '',
      tipo: json['tipo'] ?? '',
      simulado: json['simulado'] ?? false,
    );
  }

  // Método para converter um Lancamento de volta para um Map (se precisar enviar para a API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descricao': descricao,
      'valor': valor,
      'data': data,
      'tipo': tipo,
      'simulado': simulado,
    };
  }
}