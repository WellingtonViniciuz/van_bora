import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../motorista/models/occupancy.dart';
import 'passenger_route.dart';

/// Situação da van como gravada em `vans.status` pelo admin e pelo motorista.
enum VanStatus {
  emRota('Em rota'),
  disponivel('Parada'),
  indisponivel('Fora de operação');

  const VanStatus(this.label);

  final String label;

  static VanStatus fromCodigo(String? codigo) => switch (codigo) {
        'em_rota' => VanStatus.emRota,
        'disponivel' || null || '' => VanStatus.disponivel,
        _ => VanStatus.indisponivel,
      };
}

/// Viagem em andamento (coleção `viagens`, status `ativa`).
class ActiveTrip {
  const ActiveTrip({
    required this.id,
    required this.vanId,
    required this.motoristaId,
    required this.rotaId,
    this.iniciadaEm,
  });

  final String id;
  final String vanId;
  final String motoristaId;
  final String rotaId;
  final DateTime? iniciadaEm;
}

/// Visão da van para o passageiro: junta os dados de `vans`, `motoristas`,
/// `viagens` e `rotas`, sem gravar nada novo no banco.
class LiveVan {
  const LiveVan({
    required this.id,
    required this.nome,
    required this.placa,
    required this.status,
    this.capacidade,
    this.lotacao,
    this.lotacaoEm,
    this.posicao,
    this.posicaoEm,
    this.motoristaNome,
    this.rota,
    this.viagem,
  });

  final String id;
  final String nome;
  final String placa;
  final VanStatus status;
  final int? capacidade;
  final Occupancy? lotacao;
  final DateTime? lotacaoEm;
  final LatLng? posicao;
  final DateTime? posicaoEm;
  final String? motoristaNome;
  final PassengerRoute? rota;
  final ActiveTrip? viagem;

  /// A van está fazendo uma viagem agora.
  bool get emOperacao => viagem != null || status == VanStatus.emRota;

  bool get temPosicao => posicao != null;

  String get titulo => nome.isEmpty ? 'Van' : nome;

  /// Texto do status mostrado ao passageiro.
  String get statusTexto => emOperacao ? VanStatus.emRota.label : status.label;

  static Occupancy? occupancyFromCodigo(String? codigo) {
    for (final o in Occupancy.values) {
      if (o.codigo == codigo) return o;
    }
    return null;
  }
}
