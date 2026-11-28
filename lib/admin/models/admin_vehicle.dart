import 'admin_time.dart';

class AdminVehicle {
  const AdminVehicle({
    required this.id,
    required this.vanNome,
    required this.placa,
    required this.capacidade,
    required this.status,
    this.localizacaoEm,
  });

  factory AdminVehicle.fromMap(String id, Map<String, dynamic> map) {
    return AdminVehicle(
      id: id,
      vanNome: map['vanNome'] as String? ?? '',
      placa: map['placa'] as String? ?? '',
      capacidade: (map['capacidade'] as num?)?.toInt() ?? 15,
      status: map['status'] as String? ?? statusDisponivel,
      localizacaoEm: adminDateTime(map['localizacaoEm']),
    );
  }

  static const statusDisponivel = 'disponivel';
  static const statusEmRota = 'em_rota';
  static const statusIndisponivel = 'indisponivel';

  final String id;
  final String vanNome;
  final String placa;
  final int capacidade;
  final String status;

  /// Última localização enviada pelo motorista (somente leitura no admin).
  final DateTime? localizacaoEm;

  bool get emRota => status == statusEmRota;
  bool get indisponivel => status == statusIndisponivel;

  String get titulo => vanNome.isEmpty ? 'Van' : vanNome;

  String get statusLabel => switch (status) {
        statusEmRota => 'Em rota',
        statusIndisponivel => 'Indisponível',
        _ => 'Disponível',
      };

  AdminVehicle copyWith({
    String? id,
    String? vanNome,
    String? placa,
    int? capacidade,
    String? status,
    DateTime? localizacaoEm,
  }) {
    return AdminVehicle(
      id: id ?? this.id,
      vanNome: vanNome ?? this.vanNome,
      placa: placa ?? this.placa,
      capacidade: capacidade ?? this.capacidade,
      status: status ?? this.status,
      localizacaoEm: localizacaoEm ?? this.localizacaoEm,
    );
  }

  /// `localizacaoEm` não entra aqui: quem grava é o motorista.
  Map<String, dynamic> toMap() => {
        'vanNome': vanNome,
        'placa': placa,
        'capacidade': capacidade,
        'status': status,
      };
}
