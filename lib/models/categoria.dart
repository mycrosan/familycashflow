// lib/models/categoria.dart
class Categoria {
  final int? id;
  final String nome;
  final String tipo;

  Categoria({this.id, required this.nome, required this.tipo});

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
      id: json['id'], nome: json['nome'], tipo: json['tipo']
  );

  Map<String, dynamic> toJson() => {"nome": nome, "tipo": tipo};
}