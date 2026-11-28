import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vanbora_motorista/motorista/models/occupancy.dart';
import 'package:vanbora_motorista/passageiro/models/live_van.dart';
import 'package:vanbora_motorista/passageiro/models/passenger_route.dart';
import 'package:vanbora_motorista/passageiro/services/live_van_assembler.dart';
import 'package:vanbora_motorista/passageiro/utils/formatters.dart';

void main() {
  group('PassengerRoute.fromMap', () {
    test('lê o cadastro atual do admin (sem trajeto nem paradas)', () {
      final r = PassengerRoute.fromMap('rf09', {
        'codigo': 'RF09',
        'origem': 'Centro',
        'destino': 'IFPE',
        'intervaloMinutos': 30,
      });
      expect(r.titulo, 'RF09');
      expect(r.percurso, 'Centro → IFPE');
      expect(r.intervaloMinutos, 30);
      expect(r.paradas, isEmpty);
      expect(r.temDadosDeMapa, isFalse);
    });

    test('lê paradas e trajeto opcionais em vários formatos', () {
      final r = PassengerRoute.fromMap('x', {
        'codigo': 'X1',
        'paradas': [
          {'nome': 'A', 'lat': -8.0, 'lng': -34.9},
          {'nome': 'B', 'local': const GeoPoint(-8.1, -34.8)},
          {'nome': 'inválida'},
        ],
        'trajeto': [
          const GeoPoint(-8.0, -34.9),
          {'latitude': -8.05, 'longitude': -34.85},
          [-8.1, -34.8],
        ],
      });
      expect(r.paradas.map((p) => p.nome), ['A', 'B']);
      expect(r.paradas[1].posicao, const LatLng(-8.1, -34.8));
      expect(r.trajeto, hasLength(3));
      expect(r.linhaNoMapa, r.trajeto);
      expect(r.temDadosDeMapa, isTrue);
    });

    test('usa as paradas como linha quando não há trajeto', () {
      final r = PassengerRoute.fromMap('x', {
        'paradas': [
          {'nome': 'A', 'lat': 1, 'lng': 2},
          {'nome': 'B', 'lat': 3, 'lng': 4},
        ],
      });
      expect(r.linhaNoMapa, const [LatLng(1, 2), LatLng(3, 4)]);
    });

    test('busca por código, bairro e parada', () {
      final r = PassengerRoute.fromMap('x', {
        'codigo': 'RF10',
        'origem': 'Boa Viagem',
        'destino': 'IFPE',
        'paradas': [
          {'nome': 'Imbiribeira', 'lat': 1, 'lng': 2},
        ],
      });
      expect(r.corresponde(''), isTrue);
      expect(r.corresponde('rf1'), isTrue);
      expect(r.corresponde('boa'), isTrue);
      expect(r.corresponde('imbiri'), isTrue);
      expect(r.corresponde('casa amarela'), isFalse);
    });
  });

  group('LiveVanAssembler', () {
    final rotas = [
      PassengerRoute.fromMap('rf09', {'codigo': 'RF09', 'origem': 'Centro', 'destino': 'IFPE'}),
      PassengerRoute.fromMap('rf10', {'codigo': 'RF10', 'origem': 'Boa Viagem', 'destino': 'IFPE'}),
    ];

    test('junta van, motorista vinculado, viagem ativa e rota', () {
      final inicio = DateTime(2026, 11, 27, 8, 10);
      final vans = LiveVanAssembler.assemble(
        vans: [
          (
            id: 'van12',
            data: {
              'vanNome': 'Van 12',
              'placa': 'QXV-4821',
              'capacidade': 15,
              'status': 'em_rota',
              'lotacao': 'metade',
              'localizacao': const GeoPoint(-8.05, -34.9),
              'localizacaoEm': Timestamp.fromDate(DateTime(2026, 11, 27, 8, 20)),
            },
          ),
          (id: 'van04', data: {'vanNome': 'Van 04', 'placa': 'MNO-3482'}),
        ],
        motoristas: [
          (id: 'm1', data: {'nome': 'José Carlos', 'vanId': 'van12', 'rotaId': 'rf09'}),
          (id: 'm2', data: {'nome': 'Carlos', 'vanId': 'van04', 'rotaId': 'rf10'}),
        ],
        viagensAtivas: [
          (
            id: 'van12_1',
            data: {
              'vanId': 'van12',
              'motoristaId': 'm1',
              'rotaId': 'rf09',
              'status': 'ativa',
              'iniciadaEm': Timestamp.fromDate(inicio),
            },
          ),
        ],
        rotas: rotas,
      );

      expect(vans.map((v) => v.id), ['van12', 'van04'], reason: 'em operação primeiro');
      final v12 = vans.first;
      expect(v12.emOperacao, isTrue);
      expect(v12.motoristaNome, 'José Carlos');
      expect(v12.rota?.codigo, 'RF09');
      expect(v12.lotacao, Occupancy.metade);
      expect(v12.posicao, const LatLng(-8.05, -34.9));
      expect(v12.viagem?.iniciadaEm, inicio);

      final v04 = vans.last;
      expect(v04.emOperacao, isFalse);
      expect(v04.status, VanStatus.disponivel);
      expect(v04.temPosicao, isFalse);
      expect(v04.rota?.codigo, 'RF10', reason: 'rota do vínculo do admin');
      expect(v04.motoristaNome, 'Carlos');
    });

    test('a rota da viagem ativa tem prioridade sobre o vínculo', () {
      final vans = LiveVanAssembler.assemble(
        vans: [(id: 'van12', data: {'vanNome': 'Van 12'})],
        motoristas: [(id: 'm1', data: {'nome': 'Ana', 'vanId': 'van12', 'rotaId': 'rf09'})],
        viagensAtivas: [
          (id: 't', data: {'vanId': 'van12', 'motoristaId': 'm1', 'rotaId': 'rf10'}),
        ],
        rotas: rotas,
      );
      expect(vans.single.rota?.codigo, 'RF10');
      expect(vans.single.emOperacao, isTrue);
    });

    test('não inventa motorista nem rota quando não há vínculo', () {
      final vans = LiveVanAssembler.assemble(
        vans: [(id: 'v', data: {'status': 'manutencao'})],
        motoristas: const [],
        viagensAtivas: const [],
        rotas: rotas,
      );
      final v = vans.single;
      expect(v.motoristaNome, isNull);
      expect(v.rota, isNull);
      expect(v.status, VanStatus.indisponivel);
      expect(v.titulo, 'Van');
    });
  });

  group('PassengerFormat', () {
    final agora = DateTime(2026, 11, 27, 10);

    test('tempo relativo', () {
      expect(PassengerFormat.ago(null), 'sem registro');
      expect(PassengerFormat.ago(agora, now: agora), 'agora');
      expect(PassengerFormat.ago(agora.subtract(const Duration(seconds: 25)), now: agora), 'há 25 s');
      expect(PassengerFormat.ago(agora.subtract(const Duration(minutes: 3)), now: agora), 'há 3 min');
      expect(PassengerFormat.ago(agora.subtract(const Duration(hours: 2)), now: agora), 'há 2 h');
      expect(PassengerFormat.ago(agora.subtract(const Duration(days: 1)), now: agora), 'há 1 dia');
    });

    test('distância', () {
      expect(PassengerFormat.distance(347), '350 m');
      expect(PassengerFormat.distance(1234), '1,2 km');
      expect(PassengerFormat.distance(15400), '15 km');
    });

    test('posição desatualizada', () {
      expect(PassengerFormat.isStale(null), isTrue);
      expect(PassengerFormat.isStale(agora.subtract(const Duration(seconds: 30)), now: agora), isFalse);
      expect(PassengerFormat.isStale(agora.subtract(const Duration(minutes: 10)), now: agora), isTrue);
    });
  });
}
