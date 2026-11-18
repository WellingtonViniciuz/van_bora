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

  Map<String, dynamic> toMap() => {
        'codigo': codigo,
        'origem': origem,
        'destino': destino,
        'intervaloMinutos': intervaloMinutos,
      };
}
