import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../motorista/services/firestore_paths.dart';
import '../../motorista/services/modo_teste.dart';
import '../models/admin_driver.dart';
import '../models/admin_route.dart';
import '../models/admin_vehicle.dart';

class AdminRemoteService {
  AdminRemoteService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static final _vehiclesController =
      StreamController<List<AdminVehicle>>.broadcast();
  static final _routesController = StreamController<List<AdminRoute>>.broadcast();
  static final _driversController =
      StreamController<List<AdminDriver>>.broadcast();

  static final List<AdminVehicle> _mockVehicles = [
    const AdminVehicle(
      id: 'van12',
      vanNome: 'Van 12',
      placa: 'QXV-4821',
      capacidade: 15,
      status: 'disponivel',
    ),
    const AdminVehicle(
      id: 'van08',
      vanNome: 'Van 08',
      placa: 'KPT-9123',
      capacidade: 15,
      status: 'disponivel',
    ),
    const AdminVehicle(
      id: 'van04',
      vanNome: 'Van 04',
      placa: 'MNO-3482',
      capacidade: 18,
      status: 'disponivel',
    ),
  ];

  static final List<AdminRoute> _mockRoutes = [
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

  static final List<AdminDriver> _mockDrivers = [
    const AdminDriver(
      id: 'teste-uid',
      nome: 'Motorista de Teste',
      vanId: 'van12',
      vanNome: 'Van 12',
      placa: 'QXV-4821',
      rotaId: 'rf09',
      rotaCodigo: 'RF09',
      origem: 'Centro',
      destino: 'IFPE',
    ),
  ];

  // Vehicles CRUD
  Stream<List<AdminVehicle>> watchVehicles() {
    if (ModoTeste.ativo) {
      Future.microtask(() => _vehiclesController.add(List.from(_mockVehicles)));
      return _vehiclesController.stream;
    }
    return _db.collection(FirestorePaths.vans).snapshots().map(
          (snap) => snap.docs
              .map((d) => AdminVehicle.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> saveVehicle(AdminVehicle vehicle) async {
    if (ModoTeste.ativo) {
      if (vehicle.id.isEmpty) {
        final newId = 'van_${DateTime.now().millisecondsSinceEpoch}';
        final v = AdminVehicle(
          id: newId,
          vanNome: vehicle.vanNome,
          placa: vehicle.placa,
          capacidade: vehicle.capacidade,
          status: vehicle.status,
        );
        _mockVehicles.add(v);
      } else {
        final index = _mockVehicles.indexWhere((item) => item.id == vehicle.id);
        if (index >= 0) {
          _mockVehicles[index] = vehicle;
        } else {
          _mockVehicles.add(vehicle);
        }
      }
      _vehiclesController.add(List.from(_mockVehicles));
      return;
    }
    final ref = vehicle.id.isEmpty
        ? _db.collection(FirestorePaths.vans).doc()
        : _db.collection(FirestorePaths.vans).doc(vehicle.id);
    await ref.set(vehicle.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteVehicle(String id) async {
    if (ModoTeste.ativo) {
      _mockVehicles.removeWhere((v) => v.id == id);
      _vehiclesController.add(List.from(_mockVehicles));
      return;
    }
    await _db.collection(FirestorePaths.vans).doc(id).delete();
  }

  // Routes CRUD
  Stream<List<AdminRoute>> watchRoutes() {
    if (ModoTeste.ativo) {
      Future.microtask(() => _routesController.add(List.from(_mockRoutes)));
      return _routesController.stream;
    }
    return _db.collection('rotas').snapshots().map(
          (snap) => snap.docs
              .map((d) => AdminRoute.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> saveRoute(AdminRoute route) async {
    if (ModoTeste.ativo) {
      if (route.id.isEmpty) {
        final newId = 'route_${DateTime.now().millisecondsSinceEpoch}';
        final r = AdminRoute(
          id: newId,
          codigo: route.codigo,
          origem: route.origem,
          destino: route.destino,
          intervaloMinutos: route.intervaloMinutos,
        );
        _mockRoutes.add(r);
      } else {
        final index = _mockRoutes.indexWhere((item) => item.id == route.id);
        if (index >= 0) {
          _mockRoutes[index] = route;
        } else {
          _mockRoutes.add(route);
        }
      }
      _routesController.add(List.from(_mockRoutes));
      return;
    }
    final ref = route.id.isEmpty
        ? _db.collection('rotas').doc()
        : _db.collection('rotas').doc(route.id);
    await ref.set(route.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteRoute(String id) async {
    if (ModoTeste.ativo) {
      _mockRoutes.removeWhere((r) => r.id == id);
      _routesController.add(List.from(_mockRoutes));
      return;
    }
    await _db.collection('rotas').doc(id).delete();
  }

  // Drivers CRUD
  Stream<List<AdminDriver>> watchDrivers() {
    if (ModoTeste.ativo) {
      Future.microtask(() => _driversController.add(List.from(_mockDrivers)));
      return _driversController.stream;
    }
    return _db.collection(FirestorePaths.motoristas).snapshots().map(
          (snap) => snap.docs
              .map((d) => AdminDriver.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> saveDriver(AdminDriver driver) async {
    if (ModoTeste.ativo) {
      if (driver.id.isEmpty) {
        final newId = 'driver_${DateTime.now().millisecondsSinceEpoch}';
        final d = AdminDriver(
          id: newId,
          nome: driver.nome,
          vanId: driver.vanId,
          vanNome: driver.vanNome,
          placa: driver.placa,
          rotaId: driver.rotaId,
          rotaCodigo: driver.rotaCodigo,
          origem: driver.origem,
          destino: driver.destino,
        );
        _mockDrivers.add(d);
      } else {
        final index = _mockDrivers.indexWhere((item) => item.id == driver.id);
        if (index >= 0) {
          _mockDrivers[index] = driver;
        } else {
          _mockDrivers.add(driver);
        }
      }
      _driversController.add(List.from(_mockDrivers));
      return;
    }
    await _db
        .collection(FirestorePaths.motoristas)
        .doc(driver.id)
        .set(driver.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteDriver(String id) async {
    if (ModoTeste.ativo) {
      _mockDrivers.removeWhere((d) => d.id == id);
      _driversController.add(List.from(_mockDrivers));
      return;
    }
    await _db.collection(FirestorePaths.motoristas).doc(id).delete();
  }
}
