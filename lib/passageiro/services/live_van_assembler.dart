import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/live_van.dart';
import '../models/passenger_route.dart';

/// Documento lido do Firestore (id + dados).
typedef DocData = ({String id, Map<String, dynamic> data});

/// Monta a lista de [LiveVan] a partir das coleções já usadas pelos módulos
/// de admin e motorista. Função pura, para poder ser testada sem Firebase.
class LiveVanAssembler {
  LiveVanAssembler._();

  static List<LiveVan> assemble({
    required List<DocData> vans,
    required List<DocData> motoristas,
    required List<DocData> viagensAtivas,
    required List<PassengerRoute> rotas,
  }) {
    final rotasPorId = {for (final r in rotas) r.id: r};
    final motoristasPorId = {for (final m in motoristas) m.id: m.data};
    final motoristaPorVan = <String, Map<String, dynamic>>{};
    for (final m in motoristas) {
      final vanId = m.data['vanId'] as String?;
      if (vanId != null && vanId.isNotEmpty) motoristaPorVan.putIfAbsent(vanId, () => m.data);
    }
    final viagemPorVan = <String, ActiveTrip>{};
    for (final v in viagensAtivas) {
      final trip = _trip(v);
      if (trip == null) continue;
      final atual = viagemPorVan[trip.vanId];
      final maisRecente = atual == null ||
          (trip.iniciadaEm ?? DateTime(0)).isAfter(atual.iniciadaEm ?? DateTime(0));
      if (maisRecente) viagemPorVan[trip.vanId] = trip;
    }

    final result = vans.map((doc) {
      final d = doc.data;
      final viagem = viagemPorVan[doc.id];
      // Motorista e rota: primeiro os da viagem em andamento, depois o vínculo do admin.
      final motorista = (viagem != null ? motoristasPorId[viagem.motoristaId] : null) ??
          motoristaPorVan[doc.id];
      final rotaId = viagem?.rotaId ?? motorista?['rotaId'] as String?;
      return LiveVan(
        id: doc.id,
        nome: d['vanNome'] as String? ?? '',
        placa: d['placa'] as String? ?? '',
        status: VanStatus.fromCodigo(d['status'] as String?),
        capacidade: (d['capacidade'] as num?)?.toInt(),
        lotacao: LiveVan.occupancyFromCodigo(d['lotacao'] as String?),
        lotacaoEm: toDateTime(d['lotacaoEm']),
        posicao: parseLatLng(d['localizacao']),
        posicaoEm: toDateTime(d['localizacaoEm']),
        motoristaNome: _naoVazio(motorista?['nome'] as String?),
        rota: rotaId == null ? null : rotasPorId[rotaId],
        viagem: viagem,
      );
    }).toList()
      ..sort((a, b) {
        if (a.emOperacao != b.emOperacao) return a.emOperacao ? -1 : 1;
        return a.titulo.compareTo(b.titulo);
      });
    return result;
  }

  static ActiveTrip? _trip(DocData doc) {
    final vanId = doc.data['vanId'] as String?;
    if (vanId == null || vanId.isEmpty) return null;
    return ActiveTrip(
      id: doc.id,
      vanId: vanId,
      motoristaId: doc.data['motoristaId'] as String? ?? '',
      rotaId: doc.data['rotaId'] as String? ?? '',
      iniciadaEm: toDateTime(doc.data['iniciadaEm']),
    );
  }

  static String? _naoVazio(String? s) => (s == null || s.trim().isEmpty) ? null : s;
}

DateTime? toDateTime(Object? raw) => switch (raw) {
      Timestamp t => t.toDate(),
      DateTime d => d,
      _ => null,
    };
