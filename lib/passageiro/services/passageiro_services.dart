import '../../motorista/services/connectivity_service.dart';
import '../../motorista/services/modo_teste.dart';
import 'demo_passenger_source.dart';
import 'firestore_passenger_source.dart';
import 'passenger_data_source.dart';
import 'passenger_location_service.dart';

/// Serviços do módulo do passageiro. Reaproveita o [ConnectivityService] já
/// criado para o motorista.
class PassageiroServices {
  PassageiroServices({
    required this.data,
    required this.connectivity,
    required this.location,
  });

  /// Em debug usa os dados simulados, igual ao `ModoTeste` dos outros
  /// módulos; em release lê o Firestore.
  factory PassageiroServices.create({required ConnectivityService connectivity}) {
    return PassageiroServices(
      data: ModoTeste.ativo ? DemoPassengerSource() : FirestorePassengerSource(),
      connectivity: connectivity,
      location: PassengerLocationService(),
    );
  }

  final PassengerDataSource data;
  final ConnectivityService connectivity;
  final PassengerLocationService location;
}
