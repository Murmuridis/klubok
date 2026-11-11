import 'package:flutter/material.dart';

/// Русское склонение: 1 ряд, 2 ряда, 5 рядов.
String plural(int n, String one, String few, String many) {
  final n10 = n.abs() % 10;
  final n100 = n.abs() % 100;
  if (n10 == 1 && n100 != 11) return one;
  if (n10 >= 2 && n10 <= 4 && (n100 < 12 || n100 > 14)) return few;
  return many;
}

String rowsText(int n) => '$n ${plural(n, 'ряд', 'ряда', 'рядов')}';

/// 3 → «3», 2.5 → «2,5».
String fmtNum(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  final s = v.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  return s.replaceAll('.', ',');
}

String skeinsText(double v) {
  if (v == v.roundToDouble()) {
    final n = v.toInt();
    return '$n ${plural(n, 'моток', 'мотка', 'мотков')}';
  }
  return '${fmtNum(v)} мотка';
}

String lengthText(double meters) {
  if (meters >= 1000) return '${fmtNum((meters / 100).round() / 10)} км';
  return '${meters.round()} м';
}

String weightText(double grams) {
  if (grams >= 1000) return '${fmtNum((grams / 100).round() / 10)} кг';
  return '${grams.round()} г';
}

/// Понимает и «2,5», и «2.5». Пустая строка — null.
double? parseNum(String s) {
  final t = s.trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

int? parseInt(String s) {
  final t = s.trim();
  if (t.isEmpty) return null;
  return int.tryParse(t);
}

void snack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String ok = 'Удалить',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(ok),
        ),
      ],
    ),
  );
  return result ?? false;
}
