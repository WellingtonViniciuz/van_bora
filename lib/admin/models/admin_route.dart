class AdminRoute {
  const AdminRoute({
    required this.id,
    required this.codigo,
    required this.origem,
    required this.destino,
    required this.intervaloMinutos,
  });

  factory AdminRoute.fromMap(String id, Map<String, dynamic> map) {
    return AdminRoute(
      id: id,
      codigo: map['codigo'] as String? ?? '',
      origem: map['origem'] as String? ?? '',
      destino: map['destino'] as String? ?? '',
      intervaloMinutos: (map['intervaloMinutos'] as num?)?.toInt() ?? 30,
    );
  }

  final String id;
  final String codigo;
  final String origem;
  final String destino;
  final int intervaloMinutos;

  String get percurso => '$origem → $destino';

  AdminRoute copyWith({
    String? id,
    String? codigo,
    String? origem,
    String? destino,
    int? intervaloMinutos,
  }) {
    return AdminRoute(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      origem: origem ?? this.origem,
      destino: destino ?? this.destino,
      intervaloMinutos: intervaloMinutos ?? this.intervaloMinutos,
    );
  }

  Map<String, dynamic> toMap() => {
        'codigo': codigo,
        'origem': origem,
        'destino': destino,
        'intervaloMinutos': intervaloMinutos,
      };
}
