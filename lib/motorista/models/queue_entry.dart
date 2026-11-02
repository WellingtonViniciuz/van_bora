class QueueEntry {
  const QueueEntry({
    required this.motoristaId,
    required this.vanNome,
    required this.motoristaNome,
    required this.status,
    required this.ordem,
  });

  factory QueueEntry.fromMap(String id, Map<String, dynamic> map) {
    return QueueEntry(
      motoristaId: id,
      vanNome: map['vanNome'] as String? ?? '',
      motoristaNome: map['motoristaNome'] as String? ?? '',
      status: map['status'] as String? ?? 'aguardando',
      ordem: (map['ordem'] as num?)?.toInt() ?? 0,
    );
  }

  final String motoristaId;
  final String vanNome;
  final String motoristaNome;
  final String status;
  final int ordem;

  bool get aguardando => status == 'aguardando';
}

class QueuePosition {
  const QueuePosition({
    required this.position,
    required this.total,
    required this.ahead,
  });

  final int position;
  final int total;
  final List<QueueEntry> ahead;

  static QueuePosition? find(List<QueueEntry> entries, String motoristaId) {
    final waiting = entries.where((e) => e.aguardando).toList()
      ..sort((a, b) => a.ordem.compareTo(b.ordem));
    final index = waiting.indexWhere((e) => e.motoristaId == motoristaId);
    if (index < 0) return null;
    return QueuePosition(
      position: index + 1,
      total: waiting.length,
      ahead: waiting.sublist(0, index),
    );
  }
}
