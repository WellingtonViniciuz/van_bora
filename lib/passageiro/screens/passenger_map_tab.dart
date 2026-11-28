import 'package:flutter/material.dart';

import '../../app/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../controllers/passenger_controller.dart';
import '../models/live_van.dart';
import '../services/maps_config.dart';
import '../widgets/passenger_banners.dart';
import '../widgets/passenger_map.dart';
import '../widgets/passenger_state_view.dart';
import '../widgets/van_info_card.dart';

/// Tela inicial do passageiro: mapa com as vans em tempo real.
class PassengerMapTab extends StatefulWidget {
  const PassengerMapTab({super.key, required this.controller});

  final PassengerController controller;

  @override
  State<PassengerMapTab> createState() => _PassengerMapTabState();
}

class _PassengerMapTabState extends State<PassengerMapTab> {
  final _mapKey = GlobalKey<PassengerMapState>();
  String? _selectedVanId;

  PassengerController get _c => widget.controller;

  void _select(LiveVan van) {
    setState(() => _selectedVanId = van.id);
    final pos = van.posicao;
    if (pos != null) _mapKey.currentState?.centerOn(pos);
  }

  void _openDetails(LiveVan van) =>
      Navigator.of(context).pushNamed(AppRoutes.passengerVan, arguments: van.id);

  void _openTracking(LiveVan van) =>
      Navigator.of(context).pushNamed(AppRoutes.passengerTracking, arguments: van.id);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        if (_c.error != null && _c.vans.isEmpty) {
          return SafeArea(
            child: PassengerStateView(
              icon: _c.isOnline ? Icons.cloud_off_rounded : Icons.wifi_off_rounded,
              title: _c.isOnline ? 'Erro de conexão' : 'Sem internet',
              message: _c.error!,
              actionLabel: 'Tentar novamente',
              onAction: _c.retry,
            ),
          );
        }
        return MapsConfig.isAvailable ? _buildMapLayout(context) : _buildListLayout(context);
      },
    );
  }

  /// Layout principal: mapa em tela cheia, cabeçalho e cartão por cima.
  Widget _buildMapLayout(BuildContext context) {
    final selected = _selectedVanId == null ? null : _c.vanById(_selectedVanId!);
    final showMyLocation = _c.locationAccess?.isGranted ?? false;
    return Stack(
      children: [
        Positioned.fill(
          child: PassengerMap(
            key: _mapKey,
            vans: _c.vansNoMapa,
            selectedVanId: selected?.id,
            onVanTap: _select,
            onMapTap: () => setState(() => _selectedVanId = null),
            showUserLocation: showMyLocation,
            padding: const EdgeInsets.only(top: 150, bottom: 200),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  _Header(controller: _c),
                  const SizedBox(height: 8),
                  PassengerBanners(controller: _c),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _MapButtons(
                onFitAll: () => _mapKey.currentState?.fitAll(),
                onMyLocation: _c.userPosition == null
                    ? null
                    : () => _mapKey.currentState?.centerOn(_c.userPosition!, zoom: 15),
              ),
              const SizedBox(height: 12),
              if (_c.loading)
                const _LoadingCard()
              else if (selected != null)
                VanInfoCard(
                  van: selected,
                  distanceMeters: _c.distanceTo(selected),
                  onDetails: () => _openDetails(selected),
                  onTrack: () => _openTracking(selected),
                  onClose: () => setState(() => _selectedVanId = null),
                )
              else
                _ActiveVansStrip(vans: _c.vansNoMapa, onSelect: _select),
            ],
          ),
        ),
      ],
    );
  }

  /// Sem chave do Google Maps: mesma informação em lista.
  Widget _buildListLayout(BuildContext context) {
    final vans = _c.vans;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Header(controller: _c),
          const SizedBox(height: 8),
          PassengerBanners(controller: _c),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: const MapUnavailableView(compact: true),
          ),
          const SizedBox(height: 20),
          Text('Vans', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (_c.loading)
            const PassengerStateView.loading()
          else if (vans.isEmpty)
            const PassengerStateView(
              icon: Icons.airport_shuttle_outlined,
              title: 'Nenhuma van cadastrada',
              message: 'Quando a empresa cadastrar as vans, elas aparecem aqui.',
            )
          else
            for (final van in vans)
              VanListTile(
                van: van,
                distanceMeters: _c.distanceTo(van),
                onTap: () => _openDetails(van),
              ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final PassengerController controller;

  @override
  Widget build(BuildContext context) {
    final emRota = controller.vansEmOperacao.length;
    final resumo = controller.loading
        ? 'Buscando vans...'
        : emRota == 0
            ? 'Nenhuma van em rota agora'
            : emRota == 1
                ? '1 van em rota agora'
                : '$emRota vans em rota agora';
    return Material(
      color: AppColors.surface,
      elevation: 3,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 14, 8),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Voltar',
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.airport_shuttle_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'vanbora',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          height: 1.1,
                        ),
                  ),
                  Text(resumo, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapButtons extends StatelessWidget {
  const _MapButtons({required this.onFitAll, required this.onMyLocation});

  final VoidCallback onFitAll;
  final VoidCallback? onMyLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundButton(icon: Icons.zoom_out_map_rounded, tooltip: 'Ver todas as vans', onPressed: onFitAll),
        if (onMyLocation != null) ...[
          const SizedBox(height: 10),
          _RoundButton(icon: Icons.my_location_rounded, tooltip: 'Minha localização', onPressed: onMyLocation!),
        ],
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 3,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        iconSize: 24,
        padding: const EdgeInsets.all(12),
        icon: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      elevation: 4,
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
            SizedBox(width: 14),
            Text('Carregando as vans...'),
          ],
        ),
      ),
    );
  }
}

/// Faixa inferior com as vans no mapa; tocar seleciona e centraliza.
class _ActiveVansStrip extends StatelessWidget {
  const _ActiveVansStrip({required this.vans, required this.onSelect});

  final List<LiveVan> vans;
  final ValueChanged<LiveVan> onSelect;

  @override
  Widget build(BuildContext context) {
    if (vans.isEmpty) {
      return Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        elevation: 4,
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.textMuted),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nenhuma van com localização disponível no momento. '
                  'As vans aparecem aqui quando o motorista inicia a rota.',
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: vans.length,
        separatorBuilder: (_, i) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final van = vans[i];
          return Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            elevation: 3,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onSelect(van),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    VanAvatar(active: van.emOperacao, size: 40),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(van.titulo, style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          van.rota?.titulo ?? van.statusTexto,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
