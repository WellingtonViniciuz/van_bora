import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../motorista/models/queue_entry.dart';
import '../../motorista/services/firestore_paths.dart';
import '../../motorista/services/modo_teste.dart';
import '../models/admin_driver.dart';
import '../models/admin_route.dart';
import '../models/admin_trip.dart';
import '../models/admin_vehicle.dart';

/// Acesso aos dados do admin. Em debug (`ModoTeste.ativo`) usa dados em
/// memória; em release lê e grava no Firestore.
class AdminRemoteService {
  AdminRemoteService({FirebaseFirestore? firestore}) : _firestore = firestore;

  static const rotas = 'rotas';

  /// Quantas viagens recentes são lidas para a "Atividade recente".
  static const maxViagens = 20;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  static final _mock = _MockStore();

  // ---------------------------------------------------------------- IDs

  /// Gera o id antes de salvar, para o item já aparecer na lista com o
  /// mesmo id que terá no banco.
  String newId(String prefixo) {
    if (ModoTeste.ativo) return '${prefixo}_${DateTime.now().microsecondsSinceEpoch}';
    final colecao = switch (prefixo) {
      'van' => FirestorePaths.vans,
      'rota' => rotas,
      _ => FirestorePaths.motoristas,
    };
    return _db.collection(colecao).doc().id;
  }

  // ---------------------------------------------------------------- Vans

  Stream<List<AdminVehicle>> watchVehicles() {
    if (ModoTeste.ativo) {
      return _mock.watch(_mock.vehiclesSnapshot, refresh: const Duration(seconds: 10));
    }
    return _db.collection(FirestorePaths.vans).snapshots().map(
          (snap) => snap.docs.map((d) => AdminVehicle.fromMap(d.id, d.data())).toList()
            ..sort((a, b) => a.vanNome.compareTo(b.vanNome)),
        );
  }

  Future<void> saveVehicle(AdminVehicle vehicle) async {
    if (ModoTeste.ativo) {
      _mock.upsert(_mock.vehicles, vehicle, (v) => v.id);
      return;
    }
    await _db
        .collection(FirestorePaths.vans)
        .doc(vehicle.id)
        .set(vehicle.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteVehicle(String id) async {
    if (ModoTeste.ativo) {
      _mock.remove(_mock.vehicles, (v) => v.id == id);
      return;
    }
    await _db.collection(FirestorePaths.vans).doc(id).delete();
  }

  // ---------------------------------------------------------------- Rotas

  Stream<List<AdminRoute>> watchRoutes() {
    if (ModoTeste.ativo) return _mock.watch(() => List.of(_mock.routes));
    return _db.collection(rotas).snapshots().map(
          (snap) => snap.docs.map((d) => AdminRoute.fromMap(d.id, d.data())).toList()
            ..sort((a, b) => a.codigo.compareTo(b.codigo)),
        );
  }

  Future<void> saveRoute(AdminRoute route) async {
    if (ModoTeste.ativo) {
      _mock.upsert(_mock.routes, route, (r) => r.id);
      return;
    }
    await _db.collection(rotas).doc(route.id).set(route.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteRoute(String id) async {
    if (ModoTeste.ativo) {
      _mock.remove(_mock.routes, (r) => r.id == id);
      return;
    }
    await _db.collection(rotas).doc(id).delete();
  }

  // ---------------------------------------------------------------- Motoristas

  Stream<List<AdminDriver>> watchDrivers() {
    if (ModoTeste.ativo) return _mock.watch(() => List.of(_mock.drivers));
    return _db.collection(FirestorePaths.motoristas).snapshots().map(
          (snap) => snap.docs.map((d) => AdminDriver.fromMap(d.id, d.data())).toList()
            ..sort((a, b) => a.nome.compareTo(b.nome)),
        );
  }

  Future<void> saveDriver(AdminDriver driver) async {
    if (ModoTeste.ativo) {
      _mock.upsert(_mock.drivers, driver, (d) => d.id);
      return;
    }
    await _db
        .collection(FirestorePaths.motoristas)
        .doc(driver.id)
        .set(driver.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteDriver(String id) async {
    if (ModoTeste.ativo) {
      _mock.remove(_mock.drivers, (d) => d.id == id);
      return;
    }
    await _db.collection(FirestorePaths.motoristas).doc(id).delete();
  }

  // ---------------------------------------------------------------- Dashboard

  /// Entradas das filas de todas as rotas (`filas/{rotaId}/entradas`).
  Stream<List<QueueEntry>> watchQueue() {
    if (ModoTeste.ativo) return _mock.watch(_mock.queueSnapshot);
    return _db.collectionGroup(FirestorePaths.entradas).snapshots().map(
          (snap) => snap.docs.map((d) => QueueEntry.fromMap(d.id, d.data())).toList(),
        );
  }

  /// Viagens mais recentes, gravadas pelo motorista.
  Stream<List<AdminTrip>> watchRecentTrips() {
    if (ModoTeste.ativo) return _mock.watch(() => List.of(_mock.trips));
    return _db
        .collection(FirestorePaths.viagens)
        .orderBy('iniciadaEm', descending: true)
        .limit(maxViagens)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AdminTrip.fromMap(d.id, d.data())).toList());
  }
}

/// Dados de teste em memória. Usa os mesmos ids do `ModoTeste` do motorista
/// e da demonstração do passageiro (van12, rf09...).
class _MockStore {
  _MockStore() {
    final agora = DateTime.now();
    vehicles.last = vehicles.last.copyWith(
      localizacaoEm: agora.subtract(const Duration(minutes: 2)),
    );
    trips.addAll([
      AdminTrip(
        id: 'demo-van12',
        vanId: 'van12',
        motoristaId: ModoTeste.uid,
        rotaId: 'rf09',
        status: 'ativa',
        iniciadaEm: agora.subtract(const Duration(minutes: 12)),
      ),
      AdminTrip(
        id: 'demo-van04',
        vanId: 'van04',
        motoristaId: 'teste-van04',
        rotaId: 'rf09',
        status: 'ativa',
        iniciadaEm: agora.subtract(const Duration(minutes: 35)),
      ),
      AdminTrip(
        id: 'demo-van08',
        vanId: 'van08',
        motoristaId: 'teste-van08',
        rotaId: 'rf10',
        status: 'concluida',
        iniciadaEm: agora.subtract(const Duration(minutes: 80)),
        encerradaEm: agora.subtract(const Duration(minutes: 40)),
      ),
    ]);
  }

  final _changes = StreamController<void>.broadcast();

  /// Vans que estão "transmitindo" a localização na simulação.
  final _online = {'van12'};

  final vehicles = <AdminVehicle>[
    const AdminVehicle(
      id: 'van12',
      vanNome: 'Van 12',
      placa: 'QXV-4821',
      capacidade: 15,
      status: AdminVehicle.statusEmRota,
    ),
    const AdminVehicle(
      id: 'van08',
      vanNome: 'Van 08',
      placa: 'KPT-9123',
      capacidade: 15,
      status: AdminVehicle.statusDisponivel,
    ),
    const AdminVehicle(
      id: 'van04',
      vanNome: 'Van 04',
      placa: 'MNO-3482',
      capacidade: 18,
      status: AdminVehicle.statusEmRota,
    ),
  ];

  final routes = <AdminRoute>[
    const AdminRoute(
      id: 'rf09',
      codigo: 'RF09',
      origem: 'Centro',
      destino: 'IFPE',
      intervaloMinutos: 30,
    ),
    const AdminRoute(
      id: 'rf10',
      codigo: 'RF10',
      origem: 'Boa Viagem',
      destino: 'IFPE',
      intervaloMinutos: 40,
    ),
  ];

  final drivers = <AdminDriver>[
    const AdminDriver(
      id: ModoTeste.uid,
      nome: 'Motorista de Teste',
      vanId: 'van12',
      vanNome: 'Van 12',
      placa: 'QXV-4821',
      rotaId: 'rf09',
      rotaCodigo: 'RF09',
      origem: 'Centro',
      destino: 'IFPE',
    ),
    const AdminDriver(
      id: 'teste-van08',
      nome: 'Roberto',
      vanId: 'van08',
      vanNome: 'Van 08',
      placa: 'KPT-9123',
      rotaId: 'rf10',
      rotaCodigo: 'RF10',
      origem: 'Boa Viagem',
      destino: 'IFPE',
    ),
    const AdminDriver(
      id: 'teste-van04',
      nome: 'Carlos',
      vanId: 'van04',
      vanNome: 'Van 04',
      placa: 'MNO-3482',
      rotaId: 'rf09',
      rotaCodigo: 'RF09',
      origem: 'Centro',
      destino: 'IFPE',
    ),
  ];

  final trips = <AdminTrip>[];

  List<AdminVehicle> vehiclesSnapshot() {
    final agora = DateTime.now();
    return [
      for (final v in vehicles)
        _online.contains(v.id) ? v.copyWith(localizacaoEm: agora) : v,
    ];
  }

  /// Na simulação, todo motorista com van disponível e rota está na fila.
  List<QueueEntry> queueSnapshot() {
    final disponiveis = {
      for (final v in vehicles.where((v) => v.status == AdminVehicle.statusDisponivel)) v.id
    };
    var ordem = 0;
    return [
      for (final d in drivers.where((d) => d.vinculado && disponiveis.contains(d.vanId)))
        QueueEntry(
          motoristaId: d.id,
          vanNome: d.vanNome,
          motoristaNome: d.nome,
          status: 'aguardando',
          ordem: ++ordem,
        ),
    ];
  }

  /// Emite o valor atual na hora em que alguém começa a ouvir e de novo a
  /// cada alteração. Assim a lista nunca fica para trás.
  Stream<T> watch<T>(T Function() read, {Duration? refresh}) => Stream<T>.multi((c) {
        c.add(read());
        final sub = _changes.stream.listen((_) => c.add(read()));
        final timer = refresh == null ? null : Timer.periodic(refresh, (_) => c.add(read()));
        c.onCancel = () {
          timer?.cancel();
          return sub.cancel();
        };
      });

  void upsert<T>(List<T> list, T item, String Function(T) idOf) {
    final index = list.indexWhere((e) => idOf(e) == idOf(item));
    if (index >= 0) {
      list[index] = item;
    } else {
      list.add(item);
    }
    _changes.add(null);
  }

  void remove<T>(List<T> list, bool Function(T) test) {
    list.removeWhere(test);
    _changes.add(null);
  }
}
