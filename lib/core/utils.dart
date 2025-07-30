// lib/core/utils.dart
String formatarData(DateTime data) {
  return '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
}