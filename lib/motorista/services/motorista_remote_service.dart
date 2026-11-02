import 'package:cloud_firestore/cloud_firestore.dart';
// Deletar
import 'package:flutter/foundation.dart';
import 'modo_teste.dart';
// Depois
import '../models/driver_assignment.dart';
import '../models/pending_event.dart';
import '../models/queue_entry.dart';
import 'firestore_paths.dart';

class MotoristaRemoteService {
  MotoristaRemoteService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<DriverAssignment?> fetchAssignment(String motoristaId) async {
    if (ModoTeste.ativo && motoristaId == ModoTeste.uid) return ModoTeste.assignment;
    final doc = await _db.collection(FirestorePaths.motoristas).doc(motoristaId).get();
    final data = doc.data();
    if (data == null) return null;
    return DriverAssignment.fromMap(doc.id, data);
  }

  Stream<List<QueueEntry>> watchQueue(String rotaId) {
    if (ModoTeste.ativo) return Stream.value(ModoTeste.fila);
    return _db
        .collection(FirestorePaths.filas)
        .doc(rotaId)
        .collection(FirestorePaths.entradas)
        .orderBy('ordem')
        .snapshots()
        .map((snap) => snap.docs.map((d) => QueueEntry.fromMap(d.id, d.data())).toList());
  }

  Future<void> send(PendingEvent event) {
    if (ModoTeste.ativo) {
      debugPrint('[TESTE] evento simulado: ${event.type.name} ${event.data}');
      return Future.value();
    }
    return switch (event.type) {
      EventType.iniciarRota => _iniciarRota(event),
      EventType.encerrarRota => _encerrarRota(event),
      EventType.lotacao => _lotacao(event),
      EventType.localizacao => _localizacao(event),
    };
  }

  DocumentReference<Map<String, dynamic>> _viagem(String tripId) =>
      _db.collection(FirestorePaths.viagens).doc(tripId);

  DocumentReference<Map<String, dynamic>> _van(String vanId) =>
      _db.collection(FirestorePaths.vans).doc(vanId);

  DocumentReference<Map<String, dynamic>> _entrada(String rotaId, String motoristaId) => _db
      .collection(FirestorePaths.filas)
      .doc(rotaId)
      .collection(FirestorePaths.entradas)
      .doc(motoristaId);

  Future<void> _iniciarRota(PendingEvent e) {
    final d = e.data;
    final batch = _db.batch()
      ..set(
        _viagem(d['tripId'] as String),
        {
          'vanId': d['vanId'],
          'motoristaId': d['motoristaId'],
          'rotaId': d['rotaId'],
          'status': 'ativa',
          'iniciadaEm': Timestamp.fromDate(e.at),
        },
        SetOptions(merge: true),
      )
      ..set(
        _entrada(d['rotaId'] as String, d['motoristaId'] as String),
        {'status': 'em_rota'},
        SetOptions(merge: true),
      )
      ..set(_van(d['vanId'] as String), {'status': 'em_rota'}, SetOptions(merge: true));
    return batch.commit();
  }

  Future<void> _encerrarRota(PendingEvent e) {
    final d = e.data;
    final batch = _db.batch()
      ..set(
        _viagem(d['tripId'] as String),
        {'status': 'concluida', 'encerradaEm': Timestamp.fromDate(e.at)},
        SetOptions(merge: true),
      )
      ..set(
        _entrada(d['rotaId'] as String, d['motoristaId'] as String),
        {'status': 'concluida'},
        SetOptions(merge: true),
      )
      ..set(_van(d['vanId'] as String), {'status': 'disponivel'}, SetOptions(merge: true));
    return batch.commit();
  }

  Future<void> _lotacao(PendingEvent e) {
    final d = e.data;
    final batch = _db.batch()
      ..set(_viagem(d['tripId'] as String), {'lotacao': d['lotacao']}, SetOptions(merge: true))
      ..set(
        _van(d['vanId'] as String),
        {'lotacao': d['lotacao'], 'lotacaoEm': Timestamp.fromDate(e.at)},
        SetOptions(merge: true),
      );
    return batch.commit();
  }

  Future<void> _localizacao(PendingEvent e) {
    final d = e.data;
    final lat = (d['lat'] as num).toDouble();
    final lng = (d['lng'] as num).toDouble();
    final ponto = _viagem(d['tripId'] as String)
        .collection(FirestorePaths.pontos)
        .doc('${e.at.microsecondsSinceEpoch}');
    final batch = _db.batch()
      ..set(ponto, {'lat': lat, 'lng': lng, 'em': Timestamp.fromDate(e.at)})
      ..set(
        _van(d['vanId'] as String),
        {'localizacao': GeoPoint(lat, lng), 'localizacaoEm': Timestamp.fromDate(e.at)},
        SetOptions(merge: true),
      );
    return batch.commit();
  }
}
