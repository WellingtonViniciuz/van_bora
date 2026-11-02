import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/driver_assignment.dart';
import '../models/occupancy.dart';
import '../models/pending_event.dart';
import '../services/motorista_services.dart';

class OperationController extends ChangeNotifier {
  OperationController({required this.assignment, required this.services});

  final DriverAssignment assignment;
  final MotoristaServices services;

  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<Position>? _gpsSubscription;
  String? _tripId;
  Occupancy? _occupancy;
  bool _online = true;
  bool _busy = false;
  bool _disposed = false;
  String? _message;

  bool get isOnline => _online;
  bool get isTripActive => _tripId != null;
  bool get isBusy => _busy;
  Occupancy? get occupancy => _occupancy;
  String? get message => _message;

  Future<void> init() async {
    _online = await services.connectivity.isOnline();
    _connectionSubscription = services.connectivity.onChanged.listen((online) {
      _online = online;
      _notify();
    });
    _notify();
  }

  Future<void> startTrip() async {
    if (isTripActive || _busy) return;
    _setBusy(true);
    final allowed = await services.location.ensurePermission();
    if (!allowed) {
      _message = 'Permita o acesso à localização para iniciar a rota.';
      _setBusy(false);
      return;
    }
    _message = null;
    _tripId = '${assignment.vanId}_${DateTime.now().millisecondsSinceEpoch}';
    await _record(EventType.iniciarRota, _baseData());
    _gpsSubscription = services.location.positions().listen(
      _onPosition,
      onError: (_) {
        _message = 'Sem sinal de GPS. Verifique a localização do aparelho.';
        _notify();
      },
    );
    _setBusy(false);
  }

  Future<void> endTrip() async {
    if (!isTripActive || _busy) return;
    _setBusy(true);
    await _gpsSubscription?.cancel();
    _gpsSubscription = null;
    await _record(EventType.encerrarRota, _baseData());
    _tripId = null;
    _occupancy = null;
    _setBusy(false);
  }

  Future<void> setOccupancy(Occupancy value) async {
    if (!isTripActive) return;
    _occupancy = value;
    _notify();
    await _record(EventType.lotacao, {..._baseData(), 'lotacao': value.codigo});
  }

  void _onPosition(Position position) {
    if (!isTripActive) return;
    _record(
      EventType.localizacao,
      {..._baseData(), 'lat': position.latitude, 'lng': position.longitude},
      at: position.timestamp,
    );
  }

  /// Offline-first: grava localmente primeiro e tenta enviar em seguida.
  Future<void> _record(EventType type, Map<String, dynamic> data, {DateTime? at}) async {
    await services.store.add(PendingEvent(type: type, data: data, at: at));
    await services.sync.flush();
  }

  Map<String, dynamic> _baseData() => {
        'tripId': _tripId,
        'vanId': assignment.vanId,
        'motoristaId': assignment.motoristaId,
        'rotaId': assignment.rotaId,
      };

  void _setBusy(bool value) {
    _busy = value;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _connectionSubscription?.cancel();
    _gpsSubscription?.cancel();
    super.dispose();
  }
}
