import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/admin_driver.dart';
import '../models/admin_route.dart';
import '../models/admin_vehicle.dart';
import '../services/admin_remote_service.dart';

class AdminDashboardController extends ChangeNotifier {
  AdminDashboardController({required AdminRemoteService remote})
      : _remote = remote {
    _vehiclesSub = _remote.watchVehicles().listen((v) {
      _vehicles = v;
      _notify();
    });
    _routesSub = _remote.watchRoutes().listen((r) {
      _routes = r;
      _notify();
    });
    _driversSub = _remote.watchDrivers().listen((d) {
      _drivers = d;
      _notify();
    });
  }

  final AdminRemoteService _remote;
  StreamSubscription<List<AdminVehicle>>? _vehiclesSub;
  StreamSubscription<List<AdminRoute>>? _routesSub;
  StreamSubscription<List<AdminDriver>>? _driversSub;

  List<AdminVehicle> _vehicles = [];
  List<AdminRoute> _routes = [];
  List<AdminDriver> _drivers = [];

  List<AdminVehicle> get vehicles => _vehicles;
  List<AdminRoute> get routes => _routes;
  List<AdminDriver> get drivers => _drivers;

  Future<void> saveVehicle(AdminVehicle vehicle) =>
      _remote.saveVehicle(vehicle);
  Future<void> deleteVehicle(String id) => _remote.deleteVehicle(id);

  Future<void> saveRoute(AdminRoute route) => _remote.saveRoute(route);
  Future<void> deleteRoute(String id) => _remote.deleteRoute(id);

  Future<void> saveDriver(AdminDriver driver) => _remote.saveDriver(driver);
  Future<void> deleteDriver(String id) => _remote.deleteDriver(id);

  void _notify() {
    notifyListeners();
  }

  @override
  void dispose() {
    _vehiclesSub?.cancel();
    _routesSub?.cancel();
    _driversSub?.cancel();
    super.dispose();
  }
}
