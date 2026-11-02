import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/driver_assignment.dart';
import '../models/queue_entry.dart';
import '../services/motorista_remote_service.dart';

class QueueController extends ChangeNotifier {
  QueueController({
    required this.assignment,
    required MotoristaRemoteService remote,
  }) : _remote = remote {
    _subscription = _remote.watchQueue(assignment.rotaId).listen(_onEntries, onError: _onError);
  }

  final DriverAssignment assignment;
  final MotoristaRemoteService _remote;
  StreamSubscription<List<QueueEntry>>? _subscription;

  bool _loaded = false;
  QueuePosition? _position;
  String? _error;

  bool get loaded => _loaded;
  QueuePosition? get position => _position;
  String? get error => _error;
  bool get isFirst => _position?.position == 1;

  void _onEntries(List<QueueEntry> entries) {
    _position = QueuePosition.find(entries, assignment.motoristaId);
    _loaded = true;
    _error = null;
    notifyListeners();
  }

  void _onError(Object error) {
    _loaded = true;
    _error = 'Não foi possível atualizar a fila. Verifique a conexão.';
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
