/// Textos curtos de tempo e distância para o passageiro.
class PassengerFormat {
  PassengerFormat._();

  /// "agora", "há 25 s", "há 3 min", "há 2 h", "há 3 dias".
  static String ago(DateTime? when, {DateTime? now}) {
    if (when == null) return 'sem registro';
    final diff = (now ?? DateTime.now()).difference(when);
    if (diff.inSeconds < 5) return 'agora';
    if (diff.inSeconds < 60) return 'há ${diff.inSeconds} s';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    final dias = diff.inDays;
    return dias == 1 ? 'há 1 dia' : 'há $dias dias';
  }

  /// "350 m", "1,2 km", "15 km".
  static String distance(double meters) {
    if (meters < 1000) return '${(meters / 10).round() * 10} m';
    final km = meters / 1000;
    final texto = km < 10 ? km.toStringAsFixed(1) : km.round().toString();
    return '${texto.replaceAll('.', ',')} km';
  }

  /// "08:24".
  static String hour(DateTime when) =>
      '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';

  /// Posição considerada desatualizada (o motorista envia a cada ~10 s).
  static bool isStale(DateTime? when, {DateTime? now}) =>
      when == null || (now ?? DateTime.now()).difference(when) > const Duration(minutes: 5);
}
