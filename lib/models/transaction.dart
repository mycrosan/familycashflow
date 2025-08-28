import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'member.dart';

class Transaction {
  final int? id;
  final double value;
  final DateTime date;
  final String category;
  final Member associatedMember;
  final String? notes;
  final String? receiptImage;
  final int? recurringTransactionId;
  final String syncStatus; // 'synced', 'pending', 'conflict'
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    this.id,
    required this.value,
    required this.date,
    required this.category,
    required this.associatedMember,
    this.notes,
    this.receiptImage,
    this.recurringTransactionId,
    this.syncStatus = 'synced',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int?,
      value: (json['valor'] ?? 0.0).toDouble(),
      date: json['data'] is String 
        ? DateTime.parse(json['data'])
        : DateTime.now(),
      category: json['categoria'] ?? '',
      associatedMember: json['responsavel'] != null 
        ? Member.fromJson(json['responsavel'])
        : Member(
            id: json['responsavel_id'] ?? 0,
            name: 'Responsável',
            relation: 'Familiar',
            userId: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
      notes: json['observacoes'],
      receiptImage: json['receipt_image'],
      recurringTransactionId: json['recorrencia_id'],
      syncStatus: json['sync_status'] ?? 'synced',
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
      'valor': value,
      'data': date.toIso8601String(),
      'categoria': category,
      'responsavel_id': associatedMember.id,
      'observacoes': notes,
      'receipt_image': receiptImage,
      'recorrencia_id': recurringTransactionId,
      'sync_status': syncStatus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Transaction copyWith({
    int? id,
    double? value,
    DateTime? date,
    String? category,
    Member? associatedMember,
    String? notes,
    String? receiptImage,
    int? recurringTransactionId,
    String? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      value: value ?? this.value,
      date: date ?? this.date,
      category: category ?? this.category,
      associatedMember: associatedMember ?? this.associatedMember,
      notes: notes ?? this.notes,
      receiptImage: receiptImage ?? this.receiptImage,
      recurringTransactionId: recurringTransactionId ?? this.recurringTransactionId,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Transaction(id: $id, value: $value, category: $category)';
  }

  // Getters úteis
  bool get isIncome => value > 0;
  bool get isExpense => value < 0;
  double get absoluteValue => value.abs();
  
  String get formattedValue {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$ ',
      decimalDigits: 2,
    );
    final prefix = isIncome ? '+' : '-';
    return '$prefix${formatter.format(absoluteValue)}';
  }

  String get formattedDate {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String get displayDate {
    final hoje = DateTime.now();
    final ontem = hoje.subtract(Duration(days: 1));
    
    if (date.year == hoje.year && date.month == hoje.month && date.day == hoje.day) {
      return 'Hoje';
    } else if (date.year == ontem.year && date.month == ontem.month && date.day == ontem.day) {
      return 'Ontem';
    } else if (date.year == hoje.year) {
      return DateFormat('dd/MM').format(date);
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  bool get hasReceipt => receiptImage != null && receiptImage!.isNotEmpty;
  bool get isSynced => syncStatus == 'synced';
  bool get isPending => syncStatus == 'pending';
  bool get hasConflict => syncStatus == 'conflict';
  bool get isRecurring => recurringTransactionId != null;

  Color get displayColor {
    return isIncome ? Colors.green : Colors.red;
  }

  IconData get displayIcon {
    return isIncome ? Icons.trending_up : Icons.trending_down;
  }
}
