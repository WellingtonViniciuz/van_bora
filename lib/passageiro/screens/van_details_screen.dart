import 'package:flutter/material.dart';

import '../../app/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/vb_primary_button.dart';
import '../controllers/passenger_controller.dart';
import '../models/live_van.dart';
import '../services/passageiro_services.dart';
import '../utils/formatters.dart';
import '../widgets/passenger_banners.dart';
import '../widgets/passenger_state_view.dart';
import '../widgets/van_info_card.dart';

/// Informações da van selecionada.
class VanDetailsScreen extends StatefulWidget {
  const VanDetailsScreen({super.key, required this.services, required this.vanId});

  final PassageiroServices services;
  final String vanId;

  @override
  State<VanDetailsScreen> createState() => _VanDetailsScreenState();
}

class _VanDetailsScreenState extends State<VanDetailsScreen> {
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
        final van = _c.vanById(widget.vanId);
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(van?.titulo ?? 'Van'),
                if (van?.rota != null)
                  Text(
                    '${van!.rota!.titulo} · ${van.rota!.percurso}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          ),
          body: SafeArea(child: _body(context, van)),
        );
      },
    );
  }

  Widget _body(BuildContext context, LiveVan? van) {
    if (_c.loading) return const PassengerStateView.loading(message: 'Carregando a van...');
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
    final textTheme = Theme.of(context).textTheme;
    final distancia = _c.distanceTo(van);
    final viagem = van.viagem;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              PassengerBanners(controller: _c, showLocation: false),
              _Section(
                color: van.emOperacao ? AppColors.primarySoft : AppColors.neutralSoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Situação', style: textTheme.titleMedium),
                        const Spacer(),
                        VanStatusBadge(van: van),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      van.emOperacao
                          ? (viagem?.iniciadaEm != null
                              ? 'Em viagem desde ${PassengerFormat.hour(viagem!.iniciadaEm!)}'
                              : 'Em viagem')
                          : 'Sem viagem em andamento',
                      style: textTheme.headlineSmall?.copyWith(
                        color: van.emOperacao ? AppColors.primary : AppColors.textPrimary,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      van.temPosicao
                          ? 'Última posição recebida ${PassengerFormat.ago(van.posicaoEm)}'
                              '${distancia != null ? ' · ${PassengerFormat.distance(distancia)} de você' : ''}'
                          : 'O motorista ainda não enviou a localização desta van.',
                      style: textTheme.bodyMedium,
                    ),
                    if (van.temPosicao && PassengerFormat.isStale(van.posicaoEm)) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Posição antiga: a van pode estar em outro lugar.',
                        style: TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _DriverCard(van: van),
              const SizedBox(height: 16),
              _Section(
                child: Column(
                  children: [
                    _InfoRow(label: 'Van', value: van.titulo),
                    _InfoRow(label: 'Placa', value: van.placa.isEmpty ? null : van.placa),
                    _InfoRow(
                      label: 'Capacidade',
                      value: van.capacidade == null ? null : '${van.capacidade} lugares',
                    ),
                    _InfoRow(
                      label: 'Lotação',
                      value: van.emOperacao ? van.lotacao?.label : null,
                      empty: van.emOperacao ? 'Não informada' : '—',
                    ),
                    _InfoRow(
                      label: 'Rota',
                      value: van.rota == null ? null : '${van.rota!.titulo} · ${van.rota!.percurso}',
                      onTap: van.rota == null
                          ? null
                          : () => Navigator.of(context)
                              .pushNamed(AppRoutes.passengerRoute, arguments: van.rota!.id),
                    ),
                    _InfoRow(
                      label: 'Saídas',
                      value: van.rota?.intervaloMinutos == null
                          ? null
                          : 'a cada ${van.rota!.intervaloMinutos} min',
                      last: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: VbPrimaryButton(
            label: 'Acompanhar no mapa',
            icon: Icons.location_on_rounded,
            onPressed: van.temPosicao
                ? () => Navigator.of(context)
                    .pushNamed(AppRoutes.passengerTracking, arguments: van.id)
                : null,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child, this.color = AppColors.surface});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: color == AppColors.surface ? Border.all(color: AppColors.border) : null,
      ),
      child: child,
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.van});

  final LiveVan van;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final nome = van.motoristaNome;
    final iniciais =
        nome?.trim().split(RegExp(r'\s+')).take(2).map((p) => p[0].toUpperCase()).join();
    return _Section(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primarySoft,
            child: iniciais == null
                ? const Icon(Icons.person_outline_rounded, color: AppColors.primary)
                : Text(
                    iniciais,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome ?? 'Motorista não informado', style: textTheme.titleMedium),
                Text(
                  van.emOperacao ? 'Motorista da vez' : 'Motorista vinculado',
                  style: textTheme.bodyMedium,
                ),
                if (van.placa.isNotEmpty)
                  Text('Placa: ${van.placa}', style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.empty = 'Não informado',
    this.onTap,
    this.last = false,
  });

  final String label;
  final String? value;
  final String empty;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(
              value ?? empty,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: value == null ? AppColors.textMuted : AppColors.textPrimary,
              ),
            ),
          ),
          if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
    return Column(
      children: [
        onTap == null ? row : InkWell(onTap: onTap, child: row),
        if (!last) const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}
