import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../motorista/services/firestore_paths.dart';
import '../models/live_van.dart';
import '../models/passenger_route.dart';
import 'live_van_assembler.dart';
import 'passenger_data_source.dart';
import 'shared_stream.dart';

/// Lê as mesmas coleções usadas pelo admin e pelo motorista:
/// - `vans`: localização (`localizacao`/`localizacaoEm`), `status` e `lotacao`,
///   gravados pelo motorista em `MotoristaRemoteService`;
/// - `motoristas`: vínculo motorista → van/rota, cadastrado pelo admin;
/// - `viagens` (status `ativa`) e `viagens/{id}/pontos`: viagem em andamento;
/// - `rotas`: rotas cadastradas pelo admin.
class FirestorePassengerSource implements PassengerDataSource {
  FirestorePassengerSource({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance {
    _routes = SharedStream(_routesQuery);
    _vans = SharedStream(_vansQuery);
  }

  /// Mesmo nome de coleção usado em `AdminRemoteService`.
  static const rotasCollection = 'rotas';

  /// Limite de pontos lidos para desenhar o trajeto já percorrido.
  static const maxTrailPoints = 500;

  final FirebaseFirestore _db;
  late final SharedStream<List<PassengerRoute>> _routes;
  late final SharedStream<List<LiveVan>> _vans;

  @override
  bool get isDemo => false;

  @override
  Stream<List<PassengerRoute>> watchRoutes() => _routes.stream;

  @override
  Stream<List<LiveVan>> watchVans() => _vans.stream;

  @override
  Stream<List<LatLng>> watchTripTrail(String tripId) {
    return _db
        .collection(FirestorePaths.viagens)
        .doc(tripId)
        .collection(FirestorePaths.pontos)
        .orderBy('em')
        .limitToLast(maxTrailPoints)
        .snapshots()
        .map((snap) => snap.docs.map((d) => parseLatLng(d.data())).whereType<LatLng>().toList());
  }

  Stream<List<PassengerRoute>> _routesQuery() => _db
      .collection(rotasCollection)
      .snapshots()
      .map((snap) {
        final rotas = snap.docs.map((d) => PassengerRoute.fromMap(d.id, d.data())).toList()
          ..sort((a, b) => a.codigo.compareTo(b.codigo));
        return rotas;
      });

  Stream<List<DocData>> _docs(Query<Map<String, dynamic>> query) => query
      .snapshots()
      .map((snap) => snap.docs.map((d) => (id: d.id, data: d.data())).toList());

  Stream<List<LiveVan>> _vansQuery() {
    return combineLatest([
      _docs(_db.collection(FirestorePaths.vans)),
      _docs(_db.collection(FirestorePaths.motoristas)),
      _docs(_db.collection(FirestorePaths.viagens).where('status', isEqualTo: 'ativa')),
      _routes.stream,
    ]).map((values) => LiveVanAssembler.assemble(
          vans: values[0] as List<DocData>,
          motoristas: values[1] as List<DocData>,
          viagensAtivas: values[2] as List<DocData>,
          rotas: values[3] as List<PassengerRoute>,
        ));
  }
}
