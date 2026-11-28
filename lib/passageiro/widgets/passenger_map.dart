import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../models/live_van.dart';
import '../models/passenger_route.dart';
import '../services/maps_config.dart';
import 'van_marker_icons.dart';

/// Mapa do passageiro (Google Maps) com vans, rota, paradas, trajeto
/// percorrido e a localização do passageiro.
///
/// Sem chave do Google Maps configurada, mostra [fallback] no lugar do mapa.
class PassengerMap extends StatefulWidget {
  const PassengerMap({
    super.key,
    required this.vans,
    this.selectedVanId,
    this.onVanTap,
    this.onMapTap,
    this.showUserLocation = false,
    this.route,
    this.trail = const [],
    this.followVanId,
    this.padding = EdgeInsets.zero,
    this.fallback,
  });

  final List<LiveVan> vans;
  final String? selectedVanId;
  final ValueChanged<LiveVan>? onVanTap;
  final VoidCallback? onMapTap;
  final bool showUserLocation;
  final PassengerRoute? route;
  final List<LatLng> trail;

  /// Se definido, a câmera acompanha esta van a cada atualização.
  final String? followVanId;
  final EdgeInsets padding;
  final Widget? fallback;

  @override
  State<PassengerMap> createState() => PassengerMapState();
}

class PassengerMapState extends State<PassengerMap> {
  final _controller = Completer<GoogleMapController>();
  Map<PassengerMarkerKind, BitmapDescriptor>? _icons;
  bool _fitted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_icons == null && MapsConfig.isAvailable) {
      final dpr = MediaQuery.devicePixelRatioOf(context);
      VanMarkerIcons.loadAll(dpr).then((icons) {
        if (mounted) setState(() => _icons = icons);
      });
    }
  }

  @override
  void didUpdateWidget(covariant PassengerMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final follow = widget.followVanId;
    if (follow != null) {
      final van = widget.vans.where((v) => v.id == follow).firstOrNull;
      final old = oldWidget.vans.where((v) => v.id == follow).firstOrNull;
      if (van?.posicao != null && van!.posicao != old?.posicao) centerOn(van.posicao!);
    }
    if (!_fitted) _fitInitial();
  }

  /// Centraliza o mapa em [target].
  Future<void> centerOn(LatLng target, {double? zoom}) async {
    if (!_controller.isCompleted) return;
    final c = await _controller.future;
    await c.animateCamera(
      zoom == null ? CameraUpdate.newLatLng(target) : CameraUpdate.newLatLngZoom(target, zoom),
    );
  }

  /// Enquadra todas as vans e a rota.
  Future<void> fitAll() async {
    final points = _allPoints();
    if (points.isEmpty || !_controller.isCompleted) return;
    final c = await _controller.future;
    if (points.length == 1) {
      await c.animateCamera(CameraUpdate.newLatLngZoom(points.first, 15));
      return;
    }
    await c.animateCamera(CameraUpdate.newLatLngBounds(_bounds(points), 60));
  }

  List<LatLng> _allPoints() {
    final follow = widget.followVanId;
    if (follow != null) {
      final van = widget.vans.where((v) => v.id == follow).firstOrNull;
      if (van?.posicao != null) return [van!.posicao!];
    }
    return [
      ...widget.vans.map((v) => v.posicao).whereType<LatLng>(),
      ...?widget.route?.linhaNoMapa,
      ...?widget.route?.paradas.map((p) => p.posicao),
    ];
  }

  void _fitInitial() {
    if (_allPoints().isEmpty || !_controller.isCompleted) return;
    _fitted = true;
    // Espera o mapa terminar o layout para aplicar os limites.
    Future.delayed(const Duration(milliseconds: 300), fitAll);
  }

  static LatLngBounds _bounds(List<LatLng> points) {
    var minLat = points.first.latitude, maxLat = minLat;
    var minLng = points.first.longitude, maxLng = minLng;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
  }

  Set<Marker> _markers() {
    final icons = _icons;
    final markers = <Marker>{};
    for (final van in widget.vans) {
      final pos = van.posicao;
      if (pos == null) continue;
      final selected = van.id == widget.selectedVanId;
      final kind = selected
          ? PassengerMarkerKind.vanSelected
          : van.emOperacao
              ? PassengerMarkerKind.vanActive
              : PassengerMarkerKind.vanIdle;
      markers.add(Marker(
        markerId: MarkerId('van_${van.id}'),
        position: pos,
        icon: icons?[kind] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        anchor: const Offset(0.5, 0.5),
        zIndexInt: selected ? 3 : (van.emOperacao ? 2 : 1),
        infoWindow: InfoWindow(title: van.titulo, snippet: van.statusTexto),
        onTap: widget.onVanTap == null ? null : () => widget.onVanTap!(van),
      ));
    }
    final route = widget.route;
    if (route != null) {
      for (var i = 0; i < route.paradas.length; i++) {
        final stop = route.paradas[i];
        markers.add(Marker(
          markerId: MarkerId('stop_${route.id}_$i'),
          position: stop.posicao,
          icon: icons?[PassengerMarkerKind.stop] ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(title: stop.nome, snippet: 'Parada · ${route.titulo}'),
        ));
      }
    }
    return markers;
  }

  Set<Polyline> _polylines() {
    final lines = <Polyline>{};
    final line = widget.route?.linhaNoMapa ?? const [];
    if (line.length >= 2) {
      lines.add(Polyline(
        polylineId: const PolylineId('rota'),
        points: line,
        color: AppColors.primary.withValues(alpha: 0.45),
        width: 6,
      ));
    }
    if (widget.trail.length >= 2) {
      lines.add(Polyline(
        polylineId: const PolylineId('percorrido'),
        points: widget.trail,
        color: AppColors.navy,
        width: 5,
      ));
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    if (!MapsConfig.isAvailable) {
      return widget.fallback ?? const MapUnavailableView();
    }
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: MapsConfig.initialTarget,
        zoom: MapsConfig.initialZoom,
      ),
      onMapCreated: (c) {
        if (!_controller.isCompleted) _controller.complete(c);
        _fitInitial();
      },
      markers: _markers(),
      polylines: _polylines(),
      myLocationEnabled: widget.showUserLocation,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      padding: widget.padding,
      onTap: widget.onMapTap == null ? null : (_) => widget.onMapTap!(),
    );
  }
}

/// Aviso mostrado quando o Google Maps não pode ser carregado.
class MapUnavailableView extends StatelessWidget {
  const MapUnavailableView({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      color: AppColors.neutralSoft,
      padding: EdgeInsets.all(compact ? 16 : 32),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.map_outlined, size: compact ? 32 : 48, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text('Mapa indisponível', style: textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            'A chave do Google Maps não foi configurada neste aparelho. '
            'As informações das vans continuam disponíveis abaixo.',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
