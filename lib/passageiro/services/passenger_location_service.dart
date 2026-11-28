import 'package:geolocator/geolocator.dart';

/// Resultado da tentativa de usar a localização do passageiro.
enum LocationAccess {
  granted,
  denied,
  deniedForever,
  serviceDisabled;

  bool get isGranted => this == LocationAccess.granted;

  String get message => switch (this) {
        LocationAccess.granted => '',
        LocationAccess.denied =>
          'Sem permissão de localização. Você ainda pode ver as vans no mapa.',
        LocationAccess.deniedForever =>
          'A localização foi bloqueada. Libere nas configurações do aparelho para ver sua posição.',
        LocationAccess.serviceDisabled =>
          'O GPS do aparelho está desligado. Ative a localização para ver sua posição.',
      };
}

/// Localização do passageiro. É só para mostrar "você está aqui" e a
/// distância até a van; nada é enviado ao servidor.
///
/// Separado do `LocationService` do motorista porque aquele mantém uma
/// notificação de "compartilhando a localização da van", que não faz sentido
/// para o passageiro.
class PassengerLocationService {
  /// Verifica o acesso à localização. Com [ask] `true`, pede a permissão se
  /// ela ainda não foi dada.
  Future<LocationAccess> requestAccess({bool ask = true}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationAccess.serviceDisabled;
      }
      var permission = await Geolocator.checkPermission();
      if (ask && permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return switch (permission) {
        LocationPermission.always || LocationPermission.whileInUse => LocationAccess.granted,
        LocationPermission.deniedForever => LocationAccess.deniedForever,
        _ => LocationAccess.denied,
      };
    } catch (_) {
      return LocationAccess.denied;
    }
  }

  Future<Position?> lastKnown() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  Stream<Position> positions() => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
        ),
      );

  Future<void> openSettings(LocationAccess access) async {
    if (access == LocationAccess.serviceDisabled) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  static double distanceInMeters(double lat1, double lng1, double lat2, double lng2) =>
      Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
}
