import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../motorista/models/queue_entry.dart';
import '../models/admin_driver.dart';
import '../models/admin_overview.dart';
import '../models/admin_route.dart';
import '../models/admin_trip.dart';
import '../models/admin_vehicle.dart';
import '../services/admin_remote_service.dart';

class AdminDashboardController extends ChangeNotifier {
  AdminDashboardController({
    required AdminRemoteService remote,
    Duration refresh = const Duration(seconds: 20),
  }) : _remote = remote {
    _subs.addAll([
      _remote.watchVehicles().listen((v) {
        _vehicles = v;
        _loadedVehicles = true;
        _notify();
      }, onError: _onError),
      _remote.watchRoutes().listen((r) {
        _routes = r;
        _notify();
      }, onError: _onError),
      _remote.watchDrivers().listen((d) {
        _drivers = d;
        _notify();
      }, onError: _onError),
      _remote.watchQueue().listen((q) {
        _queue = q;
        _notify();
      }, onError: _onError),
      _remote.watchRecentTrips().listen((t) {
        _trips = t;
        _notify();
      }, onError: _onError),
    ]);
    // Atualiza "há X min" e o status de conexão mesmo sem dados novos.
    _ticker = Timer.periodic(refresh, (_) => _notify());
  }

  final AdminRemoteService _remote;
  final _subs = <StreamSubscription<Object?>>[];
  Timer? _ticker;
  bool _disposed = false;

  List<AdminVehicle> _vehicles = [];
  List<AdminRoute> _routes = [];
  List<AdminDriver> _drivers = [];
  List<QueueEntry> _queue = [];
  List<AdminTrip> _trips = [];
  bool _loadedVehicles = false;
  String? _error;

  List<AdminVehicle> get vehicles => _vehicles;
  List<AdminRoute> get routes => _routes;
  List<AdminDriver> get drivers => _drivers;
  bool get loaded => _loadedVehicles;
  String? get error => _error;

  AdminOverview get overview => AdminOverview.build(
        vehicles: _vehicles,
        routes: _routes,
        queue: _queue,
        trips: _trips,
      );

  // ---------------------------------------------------------------- Consultas

  AdminVehicle? vehicleById(String id) => _find(_vehicles, (v) => v.id == id);
  AdminRoute? routeById(String id) => _find(_routes, (r) => r.id == id);

  AdminDriver? driverOfVehicle(String vanId) =>
      vanId.isEmpty ? null : _find(_drivers, (d) => d.vanId == vanId);

  List<AdminDriver> driversOfRoute(String rotaId) =>
      _drivers.where((d) => d.rotaId == rotaId).toList();

  bool placaEmUso(String placa, {String exceptId = ''}) {
    final alvo = _normalizar(placa);
    return _vehicles.any((v) => v.id != exceptId && _normalizar(v.placa) == alvo);
  }

  bool codigoEmUso(String codigo, {String exceptId = ''}) {
    final alvo = _normalizar(codigo);
    return _routes.any((r) => r.id != exceptId && _normalizar(r.codigo) == alvo);
  }

  // ---------------------------------------------------------------- Vans

  Future<void> saveVehicle(AdminVehicle vehicle) async {
    final v = vehicle.id.isEmpty ? vehicle.copyWith(id: _remote.newId('van')) : vehicle;
    _vehicles = _upsert(_vehicles, v, (e) => e.id);
    _notify();
    await _remote.saveVehicle(v);
    // Mantém nome e placa atualizados no cadastro do motorista vinculado.
    for (final d in _drivers.where((d) => d.vanId == v.id).toList()) {
      await _saveDriverLocal(d.comVinculo(van: v, rota: routeById(d.rotaId)));
    }
  }

  Future<void> deleteVehicle(String id) async {
    for (final d in _drivers.where((d) => d.vanId == id).toList()) {
      await _saveDriverLocal(d.comVinculo(van: null, rota: routeById(d.rotaId)));
    }
    _vehicles = _vehicles.where((v) => v.id != id).toList();
    _notify();
    await _remote.deleteVehicle(id);
  }

  // ---------------------------------------------------------------- Rotas

  Future<void> saveRoute(AdminRoute route) async {
    final r = route.id.isEmpty ? route.copyWith(id: _remote.newId('rota')) : route;
    _routes = _upsert(_routes, r, (e) => e.id);
    _notify();
    await _remote.saveRoute(r);
    for (final d in _drivers.where((d) => d.rotaId == r.id).toList()) {
      await _saveDriverLocal(d.comVinculo(van: vehicleById(d.vanId), rota: r));
    }
  }

  Future<void> deleteRoute(String id) async {
    for (final d in _drivers.where((d) => d.rotaId == id).toList()) {
      await _saveDriverLocal(d.comVinculo(van: vehicleById(d.vanId), rota: null));
    }
    _routes = _routes.where((r) => r.id != id).toList();
    _notify();
    await _remote.deleteRoute(id);
  }

  // ---------------------------------------------------------------- Motoristas

  /// Salva o motorista vinculado à van [vanId] e à rota [rotaId]
  /// (vazio = sem vínculo). Uma van só pode ter um motorista.
  Future<void> saveDriver(AdminDriver driver, {String vanId = '', String rotaId = ''}) async {
    final id = driver.id.isEmpty ? _remote.newId('motorista') : driver.id;
    final ocupante = driverOfVehicle(vanId);
    if (ocupante != null && ocupante.id != id) {
      throw StateError('${vehicleById(vanId)?.titulo ?? 'Esta van'} já está com ${ocupante.nome}.');
    }
    final d = driver
        .copyWith(id: id)
        .comVinculo(van: vehicleById(vanId), rota: routeById(rotaId));
    await _saveDriverLocal(d);
  }

  Future<void> deleteDriver(String id) async {
    _drivers = _drivers.where((d) => d.id != id).toList();
    _notify();
    await _remote.deleteDriver(id);
  }

  Future<void> _saveDriverLocal(AdminDriver d) async {
    _drivers = _upsert(_drivers, d, (e) => e.id);
    _notify();
    await _remote.saveDriver(d);
  }

  // ---------------------------------------------------------------- Apoio

  static T? _find<T>(List<T> list, bool Function(T) test) {
    for (final e in list) {
      if (test(e)) return e;
    }
    return null;
  }

  static List<T> _upsert<T>(List<T> list, T item, String Function(T) idOf) {
    final result = List<T>.of(list);
    final index = result.indexWhere((e) => idOf(e) == idOf(item));
    if (index >= 0) {
      result[index] = item;
    } else {
      result.add(item);
    }
    return result;
  }

  static String _normalizar(String s) =>
      s.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  void _onError(Object erro) {
    _error = 'Não foi possível carregar os dados. Verifique a conexão.';
    _loadedVehicles = true;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
