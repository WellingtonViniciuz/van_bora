import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../motorista/models/occupancy.dart';
import '../../motorista/services/modo_teste.dart';
import '../models/live_van.dart';
import '../models/passenger_route.dart';
import 'passenger_data_source.dart';

/// Dados SIMULADOS para o modo de teste (debug), no mesmo espírito do
/// `ModoTeste` usado pelo motorista e pelo admin. Usa os mesmos identificadores
/// dos dados de teste desses módulos (van12, rf09 etc.).
///
/// Nada aqui vem do banco: a interface mostra o aviso "Modo demonstração"
/// sempre que esta fonte está em uso.
class DemoPassengerSource implements PassengerDataSource {
  DemoPassengerSource({this.tick = const Duration(seconds: 3)});

  final Duration tick;

  static const _rf09 = PassengerRoute(
    id: 'rf09',
    codigo: 'RF09',
    origem: 'Centro',
    destino: 'IFPE',
    intervaloMinutos: 30,
    paradas: [
      RouteStop(nome: 'Centro', posicao: LatLng(-8.0631, -34.8780)),
      RouteStop(nome: 'Derby', posicao: LatLng(-8.0545, -34.8985)),
      RouteStop(nome: 'Cordeiro', posicao: LatLng(-8.0478, -34.9250)),
      RouteStop(nome: 'IFPE', posicao: LatLng(-8.0590, -34.9506)),
    ],
    trajeto: [
      LatLng(-8.0631, -34.8780),
      LatLng(-8.0582, -34.8855),
      LatLng(-8.0545, -34.8985),
      LatLng(-8.0485, -34.9105),
      LatLng(-8.0478, -34.9250),
      LatLng(-8.0502, -34.9382),
      LatLng(-8.0560, -34.9478),
      LatLng(-8.0590, -34.9506),
    ],
  );

  static const _rf10 = PassengerRoute(
    id: 'rf10',
    codigo: 'RF10',
    origem: 'Boa Viagem',
    destino: 'IFPE',
    intervaloMinutos: 40,
    paradas: [
      RouteStop(nome: 'Boa Viagem', posicao: LatLng(-8.1190, -34.9000)),
      RouteStop(nome: 'Imbiribeira', posicao: LatLng(-8.0960, -34.9195)),
      RouteStop(nome: 'IFPE', posicao: LatLng(-8.0590, -34.9506)),
    ],
    trajeto: [
      LatLng(-8.1190, -34.9000),
      LatLng(-8.1060, -34.9095),
      LatLng(-8.0960, -34.9195),
      LatLng(-8.0820, -34.9330),
      LatLng(-8.0690, -34.9455),
      LatLng(-8.0590, -34.9506),
    ],
  );

  static const routes = [_rf09, _rf10];

  final _changes = StreamController<void>.broadcast();
  Timer? _timer;
  int _listeners = 0;
  int _step = 0;

  // Duas vans em viagem e uma parada, para mostrar todos os estados.
  late final List<_SimulatedVan> _vans = [
    _SimulatedVan(
      id: ModoTeste.assignment.vanId,
      nome: ModoTeste.assignment.vanNome,
      placa: ModoTeste.assignment.placa,
      motorista: ModoTeste.assignment.nome,
      motoristaId: ModoTeste.uid,
      rota: _rf09,
      lotacao: Occupancy.metade,
      startOffset: 6,
      emViagem: true,
    ),
    _SimulatedVan(
      id: 'van08',
      nome: 'Van 08',
      placa: 'KPT-9123',
      motorista: 'Roberto',
      motoristaId: 'teste-van08',
      rota: _rf10,
      lotacao: Occupancy.vazia,
      startOffset: 2,
      emViagem: true,
    ),
    _SimulatedVan(
      id: 'van04',
      nome: 'Van 04',
      placa: 'MNO-3482',
      motorista: 'Carlos',
      motoristaId: 'teste-van04',
      rota: _rf09,
      lotacao: null,
      startOffset: 0,
      emViagem: false,
    ),
  ];

  @override
  bool get isDemo => true;

  @override
  Stream<List<PassengerRoute>> watchRoutes() => Stream.value(routes);

  @override
  Stream<List<LiveVan>> watchVans() => _live(_snapshot);

  @override
  Stream<List<LatLng>> watchTripTrail(String tripId) => _live(() {
        final van = _vans.where((v) => v.tripId == tripId).firstOrNull;
        return van == null ? const <LatLng>[] : van.trail(_step);
      });

  Stream<T> _live<T>(T Function() read) => Stream<T>.multi((controller) {
        controller.add(read());
        final sub = _changes.stream.listen((_) => controller.add(read()));
        _attach();
        controller.onCancel = () {
          sub.cancel();
          _detach();
        };
      });

  void _attach() {
    _listeners++;
    _timer ??= Timer.periodic(tick, (_) {
      _step++;
      _changes.add(null);
    });
  }

  void _detach() {
    _listeners--;
    if (_listeners <= 0) {
      _listeners = 0;
      _timer?.cancel();
      _timer = null;
    }
  }

  List<LiveVan> _snapshot() {
    final now = DateTime.now();
    return _vans.map((v) => v.toLiveVan(_step, now)).toList();
  }
}

class _SimulatedVan {
  _SimulatedVan({
    required this.id,
    required this.nome,
    required this.placa,
    required this.motorista,
    required this.motoristaId,
    required this.rota,
    required this.lotacao,
    required this.startOffset,
    required this.emViagem,
  });

  /// Quantos passos cada trecho entre dois pontos do trajeto leva.
  static const stepsPerSegment = 8;

  final String id;
  final String nome;
  final String placa;
  final String motorista;
  final String motoristaId;
  final PassengerRoute rota;
  final Occupancy? lotacao;
  final int startOffset;
  final bool emViagem;
  final DateTime _inicio = DateTime.now();

  String get tripId => 'demo-$id';

  int get _totalSteps => (rota.trajeto.length - 1) * stepsPerSegment;

  /// Posição no passo [step]; vai até o destino e recomeça do início.
  LatLng positionAt(int step) {
    if (!emViagem) return rota.trajeto.first;
    final s = (step + startOffset * stepsPerSegment) % (_totalSteps + 1);
    final segment = (s ~/ stepsPerSegment).clamp(0, rota.trajeto.length - 2);
    final t = (s - segment * stepsPerSegment) / stepsPerSegment;
    final a = rota.trajeto[segment];
    final b = rota.trajeto[segment + 1];
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  List<LatLng> trail(int step) {
    if (!emViagem) return const [];
    final s = (step + startOffset * stepsPerSegment) % (_totalSteps + 1);
    final from = step - s;
    return [for (var i = from; i <= step; i++) positionAt(i)];
  }

  LiveVan toLiveVan(int step, DateTime now) => LiveVan(
        id: id,
        nome: nome,
        placa: placa,
        status: emViagem ? VanStatus.emRota : VanStatus.disponivel,
        capacidade: 15,
        lotacao: emViagem ? lotacao : null,
        posicao: positionAt(step),
        posicaoEm: now,
        motoristaNome: motorista,
        rota: rota,
        viagem: emViagem
            ? ActiveTrip(
                id: tripId,
                vanId: id,
                motoristaId: motoristaId,
                rotaId: rota.id,
                iniciadaEm: _inicio,
              )
            : null,
      );
}
