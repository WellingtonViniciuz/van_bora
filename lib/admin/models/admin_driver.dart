import 'admin_route.dart';
import 'admin_vehicle.dart';

/// Motorista cadastrado pelo admin (coleção `motoristas`).
///
/// Os dados da van e da rota ficam copiados no documento porque o módulo do
/// motorista lê tudo de uma vez em `DriverAssignment.fromMap`.
class AdminDriver {
  const AdminDriver({
    required this.id,
    required this.nome,
    this.vanId = '',
    this.vanNome = '',
    this.placa = '',
    this.rotaId = '',
    this.rotaCodigo = '',
    this.origem = '',
    this.destino = '',
  });

  factory AdminDriver.fromMap(String id, Map<String, dynamic> map) {
    return AdminDriver(
      id: id,
      nome: map['nome'] as String? ?? '',
      vanId: map['vanId'] as String? ?? '',
      vanNome: map['vanNome'] as String? ?? '',
      placa: map['placa'] as String? ?? '',
      rotaId: map['rotaId'] as String? ?? '',
      rotaCodigo: map['rotaCodigo'] as String? ?? '',
      origem: map['origem'] as String? ?? '',
      destino: map['destino'] as String? ?? '',
    );
  }

  final String id;
  final String nome;
  final String vanId;
  final String vanNome;
  final String placa;
  final String rotaId;
  final String rotaCodigo;
  final String origem;
  final String destino;

  bool get temVan => vanId.isNotEmpty;
  bool get temRota => rotaId.isNotEmpty;
  bool get vinculado => temVan && temRota;

  /// Copia o vínculo com a van e a rota. `null` remove o vínculo.
  AdminDriver comVinculo({AdminVehicle? van, AdminRoute? rota}) {
    return AdminDriver(
      id: id,
      nome: nome,
      vanId: van?.id ?? '',
      vanNome: van?.vanNome ?? '',
      placa: van?.placa ?? '',
      rotaId: rota?.id ?? '',
      rotaCodigo: rota?.codigo ?? '',
      origem: rota?.origem ?? '',
      destino: rota?.destino ?? '',
    );
  }

  AdminDriver copyWith({String? id, String? nome}) {
    return AdminDriver(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      vanId: vanId,
      vanNome: vanNome,
      placa: placa,
      rotaId: rotaId,
      rotaCodigo: rotaCodigo,
      origem: origem,
      destino: destino,
    );
  }

  Map<String, dynamic> toMap() => {
        'nome': nome,
        'vanId': vanId,
        'vanNome': vanNome,
        'placa': placa,
        'rotaId': rotaId,
        'rotaCodigo': rotaCodigo,
        'origem': origem,
        'destino': destino,
      };
}
