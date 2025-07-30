class Config {
  static const String apiUrl = 'http://localhost:5000';
}

// lib/core/utils.dart
String formatarData(DateTime data) {
  return '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
}

// lib/models/responsavel.dart
class Responsavel {
  final int? id;
  final String nome;
  final String? email;
  final String? telefone;

  Responsavel({this.id, required this.nome, this.email, this.telefone});

  factory Responsavel.fromJson(Map<String, dynamic> json) => Responsavel(
      id: json['id'], nome: json['nome'], email: json['email'], telefone: json['telefone']
  );

  Map<String, dynamic> toJson() => {
    "nome": nome,
    "email": email,
    "telefone": telefone
  };
}