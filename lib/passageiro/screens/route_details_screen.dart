import 'package:flutter/material.dart';

import '../../app/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../controllers/passenger_controller.dart';
import '../models/live_van.dart';
import '../models/passenger_route.dart';
import '../services/maps_config.dart';
import '../services/passageiro_services.dart';
import '../widgets/passenger_banners.dart';
import '../widgets/passenger_map.dart';
import '../widgets/passenger_state_view.dart';
import '../widgets/van_info_card.dart';

/// Detalhes de uma rota: trajeto e paradas no mapa (quando cadastrados) e as
/// vans da rota.
class RouteDetailsScreen extends StatefulWidget {
  const RouteDetailsScreen({super.key, required this.services, required this.routeId});

  final PassageiroServices services;
  final String routeId;

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  late final PassengerController _c = PassengerController(services: widget.services)..init();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final route = _c.routeById(widget.routeId);
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(route?.titulo ?? 'Rota'),
                if (route != null)
                  Text(route.percurso, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          body: SafeArea(child: _body(context, route)),
        );
      },
    );
  }

  Widget _body(BuildContext context, PassengerRoute? route) {
    if (_c.loading) return const PassengerStateView.loading(message: 'Carregando a rota...');
    if (_c.error != null && route == null) {
      return PassengerStateView(
        icon: Icons.cloud_off_rounded,
        title: 'Erro de conexão',
        message: _c.error!,
        actionLabel: 'Tentar novamente',
        onAction: _c.retry,
      );
    }
    if (route == null) {
      return const PassengerStateView(
        icon: Icons.alt_route_rounded,
        title: 'Rota não encontrada',
        message: 'Esta rota não está mais cadastrada.',
      );
    }
    final textTheme = Theme.of(context).textTheme;
    final vans = _c.vansDaRota(route.id);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        PassengerBanners(controller: _c, showLocation: false),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 260,
            child: _RouteMap(
              route: route,
              controller: _c,
              onVanTap: (van) =>
                  Navigator.of(context).pushNamed(AppRoutes.passengerVan, arguments: van.id),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.schedule_rounded, color: AppColors.textMuted, size: 20),
            const SizedBox(width: 8),
            Text(
              route.intervaloMinutos == null
                  ? 'Intervalo entre saídas não informado'
                  : 'Saídas a cada ${route.intervaloMinutos} minutos',
              style: textTheme.bodyLarge,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Paradas', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        if (route.paradas.isEmpty)
          Text(
            'A empresa ainda não cadastrou as paradas desta rota. '
            'Embarque em ${route.origem} com destino a ${route.destino}.',
            style: textTheme.bodyMedium,
          )
        else
          _StopsList(route: route),
        const SizedBox(height: 24),
        Text('Vans desta rota', style: textTheme.titleMedium),
        const SizedBox(height: 10),
        if (vans.isEmpty)
          Text('Nenhuma van vinculada a esta rota no momento.', style: textTheme.bodyMedium)
        else
          for (final van in vans)
            VanListTile(
              van: van,
              distanceMeters: _c.distanceTo(van),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.passengerVan, arguments: van.id),
            ),
      ],
    );
  }
}

class _RouteMap extends StatelessWidget {
  const _RouteMap({required this.route, required this.controller, required this.onVanTap});

  final PassengerRoute route;
  final PassengerController controller;
  final ValueChanged<LiveVan> onVanTap;

  @override
  Widget build(BuildContext context) {
    if (!MapsConfig.isAvailable) return const MapUnavailableView(compact: true);
    final vans = controller.vansDaRota(route.id).where((v) => v.temPosicao).toList();
    return Stack(
      children: [
        PassengerMap(
          vans: vans,
          route: route,
          onVanTap: onVanTap,
          showUserLocation: controller.locationAccess?.isGranted ?? false,
        ),
        if (!route.temDadosDeMapa)
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  'Trajeto não cadastrado: o mapa mostra só as vans desta rota.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StopsList extends StatelessWidget {
  const _StopsList({required this.route});

  final PassengerRoute route;

  @override
  Widget build(BuildContext context) {
    final stops = route.paradas;
    return Column(
      children: [
        for (var i = 0; i < stops.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(top: 3),
                      decoration: BoxDecoration(
                        color: i == 0 || i == stops.length - 1 ? AppColors.primary : AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 3),
                      ),
                    ),
                    if (i < stops.length - 1)
                      Container(width: 3, height: 26, color: AppColors.primarySoft),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stops[i].nome,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: i == 0 || i == stops.length - 1 ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
