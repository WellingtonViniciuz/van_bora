enum EventType { iniciarRota, encerrarRota, lotacao, localizacao }

class PendingEvent {
  PendingEvent({required this.type, required this.data, DateTime? at})
      : at = at ?? DateTime.now();

  factory PendingEvent.fromMap(Map<String, dynamic> map) {
    return PendingEvent(
      type: EventType.values.byName(map['type'] as String),
      data: Map<String, dynamic>.from(map['data'] as Map),
      at: DateTime.parse(map['at'] as String),
    );
  }

  final EventType type;
  final Map<String, dynamic> data;
  final DateTime at;

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'data': data,
        'at': at.toIso8601String(),
      };
}
