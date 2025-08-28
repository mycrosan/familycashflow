import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class Lancamento {
  final int? id;
  final String descricao;
  final double valor;
  final DateTime data;
  final String tipo; // 'entrada' ou 'saida'
  final int categoriaId;
  final int responsavelId;
  final String? observacoes;
  final bool recorrente;
  final int? recorrenciaId;
  final String? receiptImage;
  final String syncStatus; // 'synced', 'pending', 'conflict'
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Relacionamentos
  final Categoria? categoria;
  final Responsavel? responsavel;
  final Recorrencia? recorrencia;

  Lancamento({
    this.id,
    required this.descricao,
    required this.valor,
    required this.data,
    required this.tipo,
    required this.categoriaId,
    required this.responsavelId,
    this.observacoes,
    this.recorrente = false,
    this.recorrenciaId,
    this.receiptImage,
    this.syncStatus = 'synced',
    required this.createdAt,
    required this.updatedAt,
    this.categoria,
    this.responsavel,
    this.recorrencia,
  });

  // Factory constructor para criar um Lancamento a partir de um Map (JSON)
  factory Lancamento.fromJson(Map<String, dynamic> json) {
    return Lancamento(
      id: json['id'] as int?,
      descricao: json['descricao'] ?? 'Sem descrição',
      valor: (json['valor'] ?? 0.0).toDouble(),
      data: json['data'] is String 
        ? DateTime.parse(json['data'])
        : DateTime.now(),
      tipo: json['tipo'] ?? '',
      categoriaId: json['categoria_id'] ?? 0,
      responsavelId: json['responsavel_id'] ?? 0,
      observacoes: json['observacoes'],
      recorrente: json['recorrente'] ?? false,
      recorrenciaId: json['recorrencia_id'],
      receiptImage: json['receipt_image'],
      syncStatus: json['sync_status'] ?? 'synced',
      createdAt: json['created_at'] is String 
        ? DateTime.parse(json['created_at'])
        : DateTime.now(),
      updatedAt: json['updated_at'] is String 
        ? DateTime.parse(json['updated_at'])
        : DateTime.now(),
      categoria: json['categoria'] != null 
        ? Categoria.fromJson(json['categoria'])
        : null,
      responsavel: json['responsavel'] != null 
        ? Responsavel.fromJson(json['responsavel'])
        : null,
      recorrencia: json['recorrencia'] != null 
        ? Recorrencia.fromJson(json['recorrencia'])
        : null,
    );
  }

  // Método para converter um Lancamento de volta para um Map (se precisar enviar para a API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descricao': descricao,
      'valor': valor,
      'data': data.toIso8601String(),
      'tipo': tipo,
      'categoria_id': categoriaId,
      'responsavel_id': responsavelId,
      'observacoes': observacoes,
      'recorrente': recorrente,
      'recorrencia_id': recorrenciaId,
      'receipt_image': receiptImage,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Criar cópia do lançamento com campos modificados
  Lancamento copyWith({
    int? id,
    String? descricao,
    double? valor,
    DateTime? data,
    String? tipo,
    int? categoriaId,
    int? responsavelId,
    String? observacoes,
    bool? recorrente,
    int? recorrenciaId,
    String? receiptImage,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    Categoria? categoria,
    Responsavel? responsavel,
    Recorrencia? recorrencia,
  }) {
    return Lancamento(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      valor: valor ?? this.valor,
      data: data ?? this.data,
      tipo: tipo ?? this.tipo,
      categoriaId: categoriaId ?? this.categoriaId,
      responsavelId: responsavelId ?? this.responsavelId,
      observacoes: observacoes ?? this.observacoes,
      recorrente: recorrente ?? this.recorrente,
      recorrenciaId: recorrenciaId ?? this.recorrenciaId,
      receiptImage: receiptImage ?? this.receiptImage,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoria: categoria ?? this.categoria,
      responsavel: responsavel ?? this.responsavel,
      recorrencia: recorrencia ?? this.recorrencia,
    );
  }

  // Verificar se dois lançamentos são iguais
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Lancamento && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // String representation
  @override
  String toString() {
    return 'Lancamento(id: $id, descricao: $descricao, valor: $valor, tipo: $tipo)';
  }

  // Verificar se é entrada
  bool get isEntrada => tipo == 'entrada';

  // Verificar se é saída
  bool get isSaida => tipo == 'saida';

  // Valor absoluto (sempre positivo)
  double get valorAbsoluto => valor.abs();

  // Valor formatado como moeda brasileira
  String get valorFormatado {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$ ',
      decimalDigits: 2,
    );
    final prefix = isEntrada ? '+' : '-';
    return '$prefix${formatter.format(valorAbsoluto)}';
  }

  // Data formatada
  String get dataFormatada {
    return DateFormat('dd/MM/yyyy').format(data);
  }

  // Data formatada para exibição
  String get dataExibicao {
    final hoje = DateTime.now();
    final ontem = hoje.subtract(Duration(days: 1));
    
    if (data.year == hoje.year && data.month == hoje.month && data.day == hoje.day) {
      return 'Hoje';
    } else if (data.year == ontem.year && data.month == ontem.month && data.day == ontem.day) {
      return 'Ontem';
    } else if (data.year == hoje.year) {
      return DateFormat('dd/MM').format(data);
    } else {
      return DateFormat('dd/MM/yyyy').format(data);
    }
  }

  // Verificar se tem recibo
  bool get temRecibo => receiptImage != null && receiptImage!.isNotEmpty;

  // Verificar se está sincronizada
  bool get estaSincronizada => syncStatus == 'synced';

  // Verificar se está pendente
  bool get estaPendente => syncStatus == 'pending';

  // Verificar se tem conflito
  bool get temConflito => syncStatus == 'conflict';

  // Verificar se é simulado (para compatibilidade)
  bool get simulado => false;

  // Cor baseada no tipo
  Color get cor {
    return isEntrada ? Colors.green : Colors.red;
  }

  // Ícone baseado no tipo
  IconData get icone {
    return isEntrada ? Icons.trending_up : Icons.trending_down;
  }
}

// Modelo de categoria
class Categoria {
  final int id;
  final String nome;
  final String tipo; // 'entrada' ou 'saida'
  final String? icone;
  final String? cor;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Categoria({
    required this.id,
    required this.nome,
    required this.tipo,
    this.icone,
    this.cor,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] as int,
      nome: json['nome'] as String,
      tipo: json['tipo'] as String,
      icone: json['icone'] as String?,
      cor: json['cor'] as String?,
      userId: json['user_id'] ?? 0,
      createdAt: json['created_at'] is String 
        ? DateTime.parse(json['created_at'])
        : DateTime.now(),
      updatedAt: json['updated_at'] is String 
        ? DateTime.parse(json['updated_at'])
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'tipo': tipo,
      'icone': icone,
      'cor': cor,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isEntrada => tipo == 'entrada';
  bool get isSaida => tipo == 'saida';
  
  // Cor padrão se não for definida
  Color get corPadrao {
    if (cor != null && cor!.isNotEmpty) {
      try {
        return Color(int.parse(cor!.replaceAll('#', '0xFF')));
      } catch (e) {
        // Se falhar, usar cor padrão
      }
    }
    return isEntrada ? Colors.green : Colors.red;
  }
}

// Modelo de responsável
class Responsavel {
  final int id;
  final String nome;
  final String? email;
  final String? telefone;
  final String? profilePicture;
  final String? relacao;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Responsavel({
    required this.id,
    required this.nome,
    this.email,
    this.telefone,
    this.profilePicture,
    this.relacao,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Responsavel.fromJson(Map<String, dynamic> json) {
    return Responsavel(
      id: json['id'] as int,
      nome: json['nome'] as String,
      email: json['email'] as String?,
      telefone: json['telefone'] as String?,
      profilePicture: json['profile_picture'] as String?,
      relacao: json['relacao'] as String?,
      userId: json['user_id'] ?? 0,
      createdAt: json['created_at'] is String 
        ? DateTime.parse(json['created_at'])
        : DateTime.now(),
      updatedAt: json['updated_at'] is String 
        ? DateTime.parse(json['updated_at'])
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'profile_picture': profilePicture,
      'relacao': relacao,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get temFotoPerfil => profilePicture != null && profilePicture!.isNotEmpty;
  String get iniciais => nome.isNotEmpty ? nome.substring(0, 1).toUpperCase() : '?';
}

// Modelo de recorrência
class Recorrencia {
  final int id;
  final String tipo; // 'diario', 'semanal', 'mensal', 'anual'
  final DateTime dataInicio;
  final DateTime? dataFim;
  final int? quantidadeOcorrencias;
  final int intervalo;
  final String? observacoes;
  final DateTime criadoEm;
  final int userId;
  final int isActive;

  Recorrencia({
    required this.id,
    required this.tipo,
    required this.dataInicio,
    this.dataFim,
    this.quantidadeOcorrencias,
    this.intervalo = 1,
    this.observacoes,
    required this.criadoEm,
    required this.userId,
    this.isActive = 1,
  });

  factory Recorrencia.fromJson(Map<String, dynamic> json) {
    return Recorrencia(
      id: json['id'] as int,
      tipo: json['tipo'] as String,
      dataInicio: json['data_inicio'] is String 
        ? DateTime.parse(json['data_inicio'])
        : DateTime.now(),
      dataFim: json['data_fim'] != null 
        ? DateTime.parse(json['data_fim'])
        : null,
      quantidadeOcorrencias: json['quantidade_ocorrencias'] as int?,
      intervalo: json['intervalo'] as int? ?? 1,
      observacoes: json['observacoes'] as String?,
      criadoEm: json['criado_em'] is String 
        ? DateTime.parse(json['criado_em'])
        : DateTime.now(),
      userId: json['user_id'] ?? 0,
      isActive: json['is_active'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim?.toIso8601String(),
      'quantidade_ocorrencias': quantidadeOcorrencias,
      'intervalo': intervalo,
      'observacoes': observacoes,
      'criado_em': criadoEm.toIso8601String(),
      'user_id': userId,
      'is_active': isActive,
    };
  }

  String get tipoLabel {
    switch (tipo) {
      case 'diario': return 'Diário';
      case 'semanal': return 'Semanal';
      case 'mensal': return 'Mensal';
      case 'anual': return 'Anual';
      default: return tipo;
    }
  }
}

