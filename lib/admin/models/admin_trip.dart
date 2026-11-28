import 'admin_time.dart';

/// Viagem gravada pelo motorista (coleção `viagens`).
class AdminTrip {
  const AdminTrip({
    required this.id,
    required this.vanId,
    required this.motoristaId,
    required this.rotaId,
    required this.status,
    this.iniciadaEm,
    this.encerradaEm,
  });

  factory AdminTrip.fromMap(String id, Map<String, dynamic> map) {
    return AdminTrip(
      id: id,
      vanId: map['vanId'] as String? ?? '',
      motoristaId: map['motoristaId'] as String? ?? '',
      rotaId: map['rotaId'] as String? ?? '',
      status: map['status'] as String? ?? '',
      iniciadaEm: adminDateTime(map['iniciadaEm']),
      encerradaEm: adminDateTime(map['encerradaEm']),
    );
  }

  final String id;
  final String vanId;
  final String motoristaId;
  final String rotaId;
  final String status;
  final DateTime? iniciadaEm;
  final DateTime? encerradaEm;

  bool get ativa => status == 'ativa';
  bool get concluida => status == 'concluida';

  /// Momento do último acontecimento da viagem.
  DateTime? get ultimoEvento => concluida ? (encerradaEm ?? iniciadaEm) : iniciadaEm;
}
