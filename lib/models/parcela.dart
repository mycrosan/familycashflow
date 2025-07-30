// lib/models/parcela.dart
class Parcela {
  final int? id;
  final int numero;
  final double valor;
  final String vencimento;
  final bool paga;

  Parcela({this.id, required this.numero, required this.valor, required this.vencimento, this.paga = false});

  factory Parcela.fromJson(Map<String, dynamic> json) => Parcela(
      id: json['id'], numero: json['numero'], valor: json['valor'].toDouble(), vencimento: json['vencimento'], paga: json['paga'] ?? false
  );

  Map<String, dynamic> toJson() => {
    "numero": numero,
    "valor": valor,
    "vencimento": vencimento,
    "paga": paga
  };
}