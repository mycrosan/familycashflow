import 'package:flutter/material.dart';

class Category {
  final int? id;
  final String name;
  final String type; // 'income' ou 'expense'
  final String? icon;
  final String? color;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int?,
      name: json['nome'] as String,
      type: json['tipo'] as String,
      icon: json['icone'] as String?,
      color: json['cor'] as String?,
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
      'nome': name,
      'tipo': type,
      'icone': icon,
      'cor': color,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Category copyWith({
    int? id,
    String? name,
    String? type,
    String? icon,
    String? color,
    int? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Category(id: $id, name: $name, type: $type)';
  }

  // Getters úteis
  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  
  Color get displayColor {
    if (color != null && color!.isNotEmpty) {
      try {
        return Color(int.parse(color!.replaceAll('#', '0xFF')));
      } catch (e) {
        // Se falhar, usar cor padrão
      }
    }
    return isIncome ? Colors.green : Colors.red;
  }

  IconData get displayIcon {
    if (icon != null && icon!.isNotEmpty) {
      // Aqui você pode mapear strings para IconData
      // Por enquanto, retornamos ícones padrão
    }
    return isIncome ? Icons.trending_up : Icons.trending_down;
  }
}
