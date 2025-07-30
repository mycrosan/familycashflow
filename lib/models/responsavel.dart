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