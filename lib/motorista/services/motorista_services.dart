import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'auth_service.dart';
import 'connectivity_service.dart';
import 'location_service.dart';
import 'motorista_remote_service.dart';
import 'pending_event_store.dart';
import 'sync_service.dart';

class MotoristaServices {
  MotoristaServices._({
    required this.auth,
    required this.remote,
    required this.store,
    required this.connectivity,
    required this.location,
    required this.sync,
  });

  final AuthService auth;
  final MotoristaRemoteService remote;
  final PendingEventStore store;
  final ConnectivityService connectivity;
  final LocationService location;
  final SyncService sync;

  static Future<MotoristaServices> create() async {
    await Hive.initFlutter();
    final store = await PendingEventStore.open();
    final remote = MotoristaRemoteService();
    final connectivity = ConnectivityService(Connectivity());
    final sync = SyncService(remote: remote, store: store, connectivity: connectivity);
    await sync.start();
    return MotoristaServices._(
      auth: AuthService(),
      remote: remote,
      store: store,
      connectivity: connectivity,
      location: LocationService(),
      sync: sync,
    );
  }

  void dispose() => sync.dispose();
}
