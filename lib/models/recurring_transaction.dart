import 'package:flutter/material.dart';
import 'member.dart';

class RecurringTransaction {
  final int? id;
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final String category;
  final double value;
  final Member associatedMember;
  final DateTime startDate;
  final DateTime? endDate;
  final int? maxOccurrences;
  final int isActive;
  final String? notes;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecurringTransaction({
    this.id,
    required this.frequency,
    required this.category,
    required this.value,
    required this.associatedMember,
    required this.startDate,
    this.endDate,
    this.maxOccurrences,
    this.isActive = 1,
    this.notes,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id'] as int?,
      frequency: json['frequency'] as String,
      category: json['category'] as String,
      value: (json['value'] ?? 0.0).toDouble(),
      associatedMember: json['associated_member'] != null 
        ? Member.fromJson(json['associated_member'])
        : Member(
            id: json['associated_member_id'] ?? 0,
            name: 'Responsável',
            relation: 'Familiar',
            userId: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
      startDate: json['start_date'] is String 
        ? DateTime.parse(json['start_date'])
        : DateTime.now(),
      endDate: json['end_date'] != null 
        ? DateTime.parse(json['end_date'])
        : null,
      maxOccurrences: json['max_occurrences'] as int?,
      isActive: json['is_active'] as int? ?? 1,
      notes: json['notes'] as String?,
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
      'frequency': frequency,
      'category': category,
      'value': value,
      'associated_member_id': associatedMember.id,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'max_occurrences': maxOccurrences,
      'is_active': isActive,
      'notes': notes,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  RecurringTransaction copyWith({
    int? id,
    String? frequency,
    String? category,
    double? value,
    Member? associatedMember,
    DateTime? startDate,
    DateTime? endDate,
    int? maxOccurrences,
    int? isActive,
    String? notes,
    int? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      frequency: frequency ?? this.frequency,
      category: category ?? this.category,
      value: value ?? this.value,
      associatedMember: associatedMember ?? this.associatedMember,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      maxOccurrences: maxOccurrences ?? this.maxOccurrences,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecurringTransaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RecurringTransaction(id: $id, frequency: $frequency, value: $value)';
  }

  // Getters úteis
  String get frequencyLabel {
    switch (frequency) {
      case 'daily':
        return 'Diário';
      case 'weekly':
        return 'Semanal';
      case 'monthly':
        return 'Mensal';
      case 'yearly':
        return 'Anual';
      default:
        return frequency;
    }
  }

  bool get isIncome => value > 0;
  bool get isExpense => value < 0;
  
  Color get displayColor {
    return isIncome ? Colors.green : Colors.red;
  }

  IconData get displayIcon {
    return isIncome ? Icons.trending_up : Icons.trending_down;
  }

  // Calcular próxima ocorrência
  DateTime getNextOccurrence() {
    final now = DateTime.now();
    if (isActive != 1 || (endDate != null && now.isAfter(endDate!))) {
      return now;
    }

    DateTime next = startDate;
    while (next.isBefore(now)) {
      switch (frequency) {
        case 'daily':
          next = next.add(Duration(days: 1));
          break;
        case 'weekly':
          next = next.add(Duration(days: 7));
          break;
        case 'monthly':
          next = DateTime(next.year, next.month + 1, next.day);
          break;
        case 'yearly':
          next = DateTime(next.year + 1, next.month, next.day);
          break;
      }
    }

    return next;
  }

  // Verificar se deve notificar
  bool shouldNotify() {
    final nextOccurrence = getNextOccurrence();
    final now = DateTime.now();
    final difference = nextOccurrence.difference(now).inDays;
    
    // Notificar 1 dia antes
    return difference <= 1 && difference >= 0;
  }
}
