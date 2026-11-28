import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Configuração do Google Maps.
///
/// A chave NÃO fica no código. Ela é passada na execução:
///   flutter run --dart-define=MAPS_API_KEY=sua_chave
/// O `android/app/build.gradle.kts` lê esse mesmo valor e o coloca no
/// AndroidManifest (`com.google.android.geo.API_KEY`).
class MapsConfig {
  MapsConfig._();

  static const apiKey = String.fromEnvironment('MAPS_API_KEY');

  /// Sem chave o SDK do Google Maps mostra um mapa vazio, então o app usa
  /// a visão em lista no lugar do mapa.
  static bool get isAvailable =>
      apiKey.isNotEmpty &&
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Enquadramento inicial (Recife) antes de chegarem as posições das vans.
  static const initialTarget = LatLng(-8.0539, -34.8811);
  static const initialZoom = 12.0;
}
