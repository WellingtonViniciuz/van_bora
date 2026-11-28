import 'package:cloud_firestore/cloud_firestore.dart';

/// Converte o valor salvo no Firestore (Timestamp) em DateTime.
DateTime? adminDateTime(Object? raw) => switch (raw) {
      Timestamp t => t.toDate(),
      DateTime d => d,
      _ => null,
    };

class AdminFormat {
  AdminFormat._();

  /// "09:15".
  static String hour(DateTime when) =>
      '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';

  /// "agora", "há 40 s", "há 2 min", "há 3 h", "há 2 dias".
  static String ago(DateTime when, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(when);
    if (diff.inSeconds < 10) return 'agora';
    if (diff.inSeconds < 60) return 'há ${diff.inSeconds} s';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    return diff.inDays == 1 ? 'há 1 dia' : 'há ${diff.inDays} dias';
  }
}
