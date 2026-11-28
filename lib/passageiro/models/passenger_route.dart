import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Ponto de parada de uma rota.
class RouteStop {
  const RouteStop({required this.nome, required this.posicao});

  final String nome;
  final LatLng posicao;

  /// Aceita `{nome, lat, lng}` ou `{nome, local: GeoPoint}`.
  static RouteStop? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final posicao = parseLatLng(raw['local']) ?? parseLatLng(raw);
    if (posicao == null) return null;
    return RouteStop(nome: raw['nome'] as String? ?? 'Parada', posicao: posicao);
  }
}

/// Rota cadastrada pelo administrador (coleção `rotas`).
///
/// Os campos `paradas` e `trajeto` são opcionais: o cadastro atual do admin
/// grava só código, origem, destino e intervalo. Se existirem no documento,
/// o passageiro mostra o trajeto e as paradas no mapa.
class PassengerRoute {
  const PassengerRoute({
    required this.id,
    required this.codigo,
    required this.origem,
    required this.destino,
    required this.intervaloMinutos,
    this.paradas = const [],
    this.trajeto = const [],
  });

  factory PassengerRoute.fromMap(String id, Map<String, dynamic> map) {
    final paradas = (map['paradas'] as List?)
            ?.map(RouteStop.tryParse)
            .whereType<RouteStop>()
            .toList() ??
        const <RouteStop>[];
    final trajeto = (map['trajeto'] as List?)
            ?.map(parseLatLng)
            .whereType<LatLng>()
            .toList() ??
        const <LatLng>[];
    return PassengerRoute(
      id: id,
      codigo: map['codigo'] as String? ?? '',
      origem: map['origem'] as String? ?? '',
      destino: map['destino'] as String? ?? '',
      intervaloMinutos: (map['intervaloMinutos'] as num?)?.toInt(),
      paradas: paradas,
      trajeto: trajeto,
    );
  }

  final String id;
  final String codigo;
  final String origem;
  final String destino;
  final int? intervaloMinutos;
  final List<RouteStop> paradas;
  final List<LatLng> trajeto;

  String get titulo => codigo.isEmpty ? 'Rota' : codigo;
  String get percurso => '$origem → $destino';

  /// Pontos para desenhar a linha da rota: o trajeto cadastrado ou, na falta
  /// dele, a sequência das paradas.
  List<LatLng> get linhaNoMapa =>
      trajeto.length >= 2 ? trajeto : paradas.map((p) => p.posicao).toList();

  bool get temDadosDeMapa => linhaNoMapa.length >= 2 || paradas.isNotEmpty;

  bool corresponde(String busca) {
    final termo = busca.trim().toLowerCase();
    if (termo.isEmpty) return true;
    return codigo.toLowerCase().contains(termo) ||
        origem.toLowerCase().contains(termo) ||
        destino.toLowerCase().contains(termo) ||
        paradas.any((p) => p.nome.toLowerCase().contains(termo));
  }
}

/// Converte GeoPoint, `{lat, lng}`, `{latitude, longitude}` ou `[lat, lng]`.
LatLng? parseLatLng(Object? raw) {
  if (raw is GeoPoint) return LatLng(raw.latitude, raw.longitude);
  if (raw is Map) {
    final lat = raw['lat'] ?? raw['latitude'];
    final lng = raw['lng'] ?? raw['longitude'];
    if (lat is num && lng is num) return LatLng(lat.toDouble(), lng.toDouble());
  }
  if (raw is List && raw.length == 2 && raw[0] is num && raw[1] is num) {
    return LatLng((raw[0] as num).toDouble(), (raw[1] as num).toDouble());
  }
  return null;
}
