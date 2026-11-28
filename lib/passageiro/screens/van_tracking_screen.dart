import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../controllers/passenger_controller.dart';
import '../models/live_van.dart';
import '../services/maps_config.dart';
import '../services/passageiro_services.dart';
import '../utils/formatters.dart';
import '../widgets/passenger_banners.dart';
import '../widgets/passenger_map.dart';
import '../widgets/passenger_state_view.dart';
import '../widgets/van_info_card.dart';

/// Acompanhamento de uma van em tempo real: posição, trajeto já percorrido na
/// viagem e distância até o passageiro.
class VanTrackingScreen extends StatefulWidget {
  const VanTrackingScreen({super.key, required this.services, required this.vanId});

  final PassageiroServices services;
  final String vanId;

  @override
  State<VanTrackingScreen> createState() => _VanTrackingScreenState();
}

class _VanTrackingScreenState extends State<VanTrackingScreen> {
  late final PassengerController _c = PassengerController(services: widget.services)..init();
  final _mapKey = GlobalKey<PassengerMapState>();
  StreamSubscription<List<LatLng>>? _trailSub;
  String? _trailTripId;
  List<LatLng> _trail = const [];
  bool _follow = true;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _c.addListener(_syncTrail);
    // Atualiza o "há X s" mesmo sem posição nova.
    _clock = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  /// Assina os pontos da viagem atual da van (ou cancela se ela terminou).
  void _syncTrail() {
    final tripId = _c.vanById(widget.vanId)?.viagem?.id;
    if (tripId == _trailTripId) return;
    _trailTripId = tripId;
    _trailSub?.cancel();
    _trailSub = null;
    setState(() => _trail = const []);
    if (tripId == null) return;
    _trailSub = _c.watchTrail(tripId).listen(
      (points) {
        if (mounted) setState(() => _trail = points);
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _clock?.cancel();
    _trailSub?.cancel();
    _c.removeListener(_syncTrail);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final van = _c.vanById(widget.vanId);
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(van?.rota?.titulo ?? van?.titulo ?? 'Acompanhar van'),
                if (van?.rota != null)
                  Text(van!.rota!.percurso, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          body: _body(context, van),
        );
      },
    );
  }

  Widget _body(BuildContext context, LiveVan? van) {
    if (_c.loading) return const PassengerStateView.loading(message: 'Localizando a van...');
    if (_c.error != null && van == null) {
      return PassengerStateView(
        icon: Icons.cloud_off_rounded,
        title: 'Erro de conexão',
        message: _c.error!,
        actionLabel: 'Tentar novamente',
        onAction: _c.retry,
      );
    }
    if (van == null) {
      return const PassengerStateView(
        icon: Icons.airport_shuttle_outlined,
        title: 'Van não encontrada',
        message: 'Esta van não está mais disponível no sistema.',
      );
    }
    if (!van.temPosicao) {
      return const PassengerStateView(
        icon: Icons.location_searching_rounded,
        title: 'Aguardando localização',
        message: 'A van aparece no mapa assim que o motorista iniciar a rota.',
      );
    }
    final mapa = MapsConfig.isAvailable
        ? PassengerMap(
            key: _mapKey,
            vans: [van],
            selectedVanId: van.id,
            route: van.rota,
            trail: _trail,
            followVanId: _follow ? van.id : null,
            showUserLocation: _c.locationAccess?.isGranted ?? false,
            padding: const EdgeInsets.only(bottom: 170),
          )
        : const MapUnavailableView();
    return Stack(
      children: [
        Positioned.fill(child: mapa),
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: PassengerBanners(controller: _c),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (MapsConfig.isAvailable) ...[
                  _FollowButton(
                    following: _follow,
                    onPressed: () {
                      setState(() => _follow = !_follow);
                      if (_follow) _mapKey.currentState?.centerOn(van.posicao!, zoom: 15);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                _TrackingCard(
                  van: van,
                  distanceMeters: _c.distanceTo(van),
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.passengerVan, arguments: van.id),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.following, required this.onPressed});

  final bool following;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: following ? AppColors.primary : AppColors.surface,
      shape: const CircleBorder(),
      elevation: 3,
      child: IconButton(
        tooltip: following ? 'Parar de seguir a van' : 'Seguir a van',
        onPressed: onPressed,
        padding: const EdgeInsets.all(12),
        icon: Icon(
          Icons.gps_fixed_rounded,
          color: following ? Colors.white : AppColors.primary,
        ),
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard({required this.van, required this.distanceMeters, required this.onTap});

  final LiveVan van;
  final double? distanceMeters;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final titulo = !van.emOperacao
        ? '${van.titulo} não está em viagem'
        : distanceMeters != null
            ? '${van.titulo} a ${PassengerFormat.distance(distanceMeters!)} de você'
            : '${van.titulo} em rota';
    final stale = PassengerFormat.isStale(van.posicaoEm);
    return Material(
      color: AppColors.surface,
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titulo, style: textTheme.titleMedium),
                        Text(
                          'Última atualização: ${PassengerFormat.ago(van.posicaoEm)}',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  VanStatusBadge(van: van),
                  if (van.lotacao != null && van.emOperacao) OccupancyBadge(occupancy: van.lotacao!),
                ],
              ),
              if (stale || !van.emOperacao) ...[
                const SizedBox(height: 10),
                Text(
                  !van.emOperacao
                      ? 'O motorista encerrou a viagem. Esta é a última posição conhecida.'
                      : 'Sem atualização recente. A van pode estar sem sinal.',
                  style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
              if (!MapsConfig.isAvailable) ...[
                const SizedBox(height: 10),
                Text(
                  'Coordenadas: ${van.posicao!.latitude.toStringAsFixed(5)}, '
                  '${van.posicao!.longitude.toStringAsFixed(5)}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
