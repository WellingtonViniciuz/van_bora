import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/live_van.dart';
import '../models/passenger_route.dart';

/// Fonte de dados do passageiro. Só leitura: o passageiro consome o que o
/// admin cadastra e o que o motorista transmite.
abstract class PassengerDataSource {
  /// `true` quando os dados são simulados (modo de teste em debug).
  bool get isDemo;

  /// Rotas cadastradas pelo admin, em tempo real.
  Stream<List<PassengerRoute>> watchRoutes();

  /// Vans com posição, status, motorista e rota, em tempo real.
  Stream<List<LiveVan>> watchVans();

  /// Pontos de GPS já enviados pelo motorista na viagem [tripId].
  Stream<List<LatLng>> watchTripTrail(String tripId);
}
