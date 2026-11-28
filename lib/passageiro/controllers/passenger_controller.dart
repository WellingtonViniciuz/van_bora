import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/live_van.dart';
import '../models/passenger_route.dart';
import '../services/passageiro_services.dart';
import '../services/passenger_location_service.dart';

/// Estado em tempo real usado pelas telas do passageiro: vans, rotas,
/// conexão e localização do passageiro.
class PassengerController extends ChangeNotifier {
  PassengerController({required this.services});

  final PassageiroServices services;

  StreamSubscription<List<LiveVan>>? _vansSub;
  StreamSubscription<List<PassengerRoute>>? _routesSub;
  StreamSubscription<bool>? _connectionSub;
  StreamSubscription<Position>? _positionSub;
  bool _disposed = false;

  List<LiveVan>? _vans;
  List<PassengerRoute>? _routes;
  String? _error;
  bool _online = true;
  LocationAccess? _locationAccess;
  LatLng? _userPosition;

  bool get isDemo => services.data.isDemo;
  bool get loading => (_vans == null || _routes == null) && _error == null;
  String? get error => _error;
  bool get isOnline => _online;
  LocationAccess? get locationAccess => _locationAccess;
  LatLng? get userPosition => _userPosition;

  List<LiveVan> get vans => _vans ?? const [];
  List<PassengerRoute> get routes => _routes ?? const [];

  /// Vans em viagem que já enviaram posição.
  List<LiveVan> get vansEmOperacao => vans.where((v) => v.emOperacao).toList();

  /// Vans que aparecem no mapa.
  List<LiveVan> get vansNoMapa => vans.where((v) => v.temPosicao).toList();

  LiveVan? vanById(String id) => vans.where((v) => v.id == id).firstOrNull;

  PassengerRoute? routeById(String id) => routes.where((r) => r.id == id).firstOrNull;

  List<LiveVan> vansDaRota(String routeId) =>
      vans.where((v) => v.rota?.id == routeId).toList();

  int vansEmOperacaoNaRota(String routeId) =>
      vansDaRota(routeId).where((v) => v.emOperacao).length;

  /// Distância em metros entre o passageiro e a van, quando as duas posições
  /// são conhecidas.
  double? distanceTo(LiveVan van) {
    final user = _userPosition;
    final pos = van.posicao;
    if (user == null || pos == null) return null;
    return PassengerLocationService.distanceInMeters(
        user.latitude, user.longitude, pos.latitude, pos.longitude);
  }

  Stream<List<LatLng>> watchTrail(String tripId) => services.data.watchTripTrail(tripId);

  /// Começa a ouvir os dados. Com [askLocation], pede a permissão de
  /// localização; sem ela, só usa a localização se já estiver liberada.
  Future<void> init({bool askLocation = false}) async {
    _subscribeData();
    _online = await services.connectivity.isOnline();
    _connectionSub = services.connectivity.onChanged.listen((online) {
      final voltou = online && !_online;
      _online = online;
      if (voltou && _error != null) retry();
      _notify();
    });
    _notify();
    await refreshLocation(ask: askLocation);
  }

  void _subscribeData() {
    _vansSub?.cancel();
    _routesSub?.cancel();
    _vansSub = services.data.watchVans().listen(
      (v) {
        _vans = v;
        _error = null;
        _notify();
      },
      onError: _onError,
    );
    _routesSub = services.data.watchRoutes().listen(
      (r) {
        _routes = r;
        _error = null;
        _notify();
      },
      onError: _onError,
    );
  }

  void _onError(Object error) {
    _error = _online
        ? 'Não foi possível carregar os dados das vans. Tente novamente.'
        : 'Sem conexão com a internet. Os dados vão atualizar quando a conexão voltar.';
    _notify();
  }

  void retry() {
    _error = null;
    _vans = null;
    _routes = null;
    _notify();
    _subscribeData();
  }

  Future<void> refreshLocation({bool ask = true}) async {
    final access = await services.location.requestAccess(ask: ask);
    if (_disposed) return;
    _locationAccess = access;
    _notify();
    if (!access.isGranted) {
      await _positionSub?.cancel();
      _positionSub = null;
      return;
    }
    // Mostra logo a última posição conhecida enquanto o GPS não envia a primeira leitura.
    if (_userPosition == null) {
      final last = await services.location.lastKnown();
      if (last != null && _userPosition == null && !_disposed) {
        _userPosition = LatLng(last.latitude, last.longitude);
        _notify();
      }
    }
    if (_disposed) return;
    _positionSub ??= services.location.positions().listen(
      (p) {
        _userPosition = LatLng(p.latitude, p.longitude);
        _notify();
      },
      onError: (_) {},
    );
  }

  Future<void> openLocationSettings() async {
    final access = _locationAccess;
    if (access == null) return;
    await services.location.openSettings(access);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _vansSub?.cancel();
    _routesSub?.cancel();
    _connectionSub?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }
}
