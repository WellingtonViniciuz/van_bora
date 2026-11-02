import 'dart:async';

import 'connectivity_service.dart';
import 'motorista_remote_service.dart';
import 'pending_event_store.dart';

class SyncService {
  SyncService({
    required this.remote,
    required this.store,
    required this.connectivity,
  });

  final MotoristaRemoteService remote;
  final PendingEventStore store;
  final ConnectivityService connectivity;

  StreamSubscription<bool>? _connectionSubscription;
  Timer? _retryTimer;
  bool _running = false;

  Future<void> start() async {
    _connectionSubscription = connectivity.onChanged.listen((online) {
      if (online) flush();
    });
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (_) => flush());
    await flush();
  }

  /// Envia os eventos pendentes em ordem cronológica. Interrompe no primeiro erro
  /// e mantém o restante para a próxima tentativa.
  Future<void> flush() async {
    if (_running || store.isEmpty) return;
    if (!await connectivity.isOnline()) return;
    _running = true;
    try {
      while (true) {
        final next = store.oldest();
        if (next == null) break;
        await remote.send(next.event).timeout(const Duration(seconds: 15));
        await store.remove(next.key);
      }
    } catch (_) {
      // Sem envio: os eventos continuam no Hive até a próxima tentativa.
    } finally {
      _running = false;
    }
  }

  void dispose() {
    _connectionSubscription?.cancel();
    _retryTimer?.cancel();
  }
}
