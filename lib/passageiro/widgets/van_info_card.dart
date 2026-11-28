import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/vb_status_badge.dart';
import '../../motorista/models/occupancy.dart';
import '../models/live_van.dart';
import '../utils/formatters.dart';

/// Selo de status da van (em rota / parada / fora de operação).
class VanStatusBadge extends StatelessWidget {
  const VanStatusBadge({super.key, required this.van});

  final LiveVan van;

  @override
  Widget build(BuildContext context) {
    final (Color color, Color bg) = van.emOperacao
        ? (AppColors.success, AppColors.successSoft)
        : van.status == VanStatus.indisponivel
            ? (AppColors.warning, AppColors.warningSoft)
            : (AppColors.textMuted, AppColors.neutralSoft);
    return VbStatusBadge(label: van.statusTexto, color: color, background: bg);
  }
}

/// Selo de lotação informada pelo motorista.
class OccupancyBadge extends StatelessWidget {
  const OccupancyBadge({super.key, required this.occupancy});

  final Occupancy occupancy;

  @override
  Widget build(BuildContext context) {
    final (Color color, Color bg) = switch (occupancy) {
      Occupancy.vazia => (AppColors.success, AppColors.successSoft),
      Occupancy.metade => (AppColors.warning, AppColors.warningSoft),
      Occupancy.cheia => (AppColors.danger, AppColors.dangerSoft),
    };
    return VbStatusBadge(label: 'Lotação: ${occupancy.label}', color: color, background: bg);
  }
}

/// Ícone quadrado da van, igual ao usado no painel do motorista.
class VanAvatar extends StatelessWidget {
  const VanAvatar({super.key, required this.active, this.size = 48});

  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.neutralSoft,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        Icons.airport_shuttle_rounded,
        color: active ? Colors.white : AppColors.textMuted,
        size: size * 0.55,
      ),
    );
  }
}

/// Resumo da van selecionada no mapa, com atalhos para detalhes e
/// acompanhamento.
class VanInfoCard extends StatelessWidget {
  const VanInfoCard({
    super.key,
    required this.van,
    this.distanceMeters,
    required this.onDetails,
    required this.onTrack,
    this.onClose,
  });

  final LiveVan van;
  final double? distanceMeters;
  final VoidCallback onDetails;
  final VoidCallback onTrack;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rota = van.rota;
    return Material(
      color: AppColors.surface,
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VanAvatar(active: van.emOperacao),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(van.titulo, style: textTheme.titleLarge),
                      Text(
                        rota == null ? 'Sem rota vinculada' : '${rota.titulo} · ${rota.percurso}',
                        style: textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  VanStatusBadge(van: van),
                  if (van.lotacao != null && van.emOperacao) OccupancyBadge(occupancy: van.lotacao!),
                  _InfoChip(
                    icon: Icons.update_rounded,
                    text: PassengerFormat.ago(van.posicaoEm),
                  ),
                  if (distanceMeters != null)
                    _InfoChip(
                      icon: Icons.near_me_outlined,
                      text: '${PassengerFormat.distance(distanceMeters!)} de você',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDetails,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Detalhes'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onTrack,
                      icon: const Icon(Icons.my_location_rounded, size: 20),
                      label: const Text('Acompanhar'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Linha de van para listas.
class VanListTile extends StatelessWidget {
  const VanListTile({super.key, required this.van, required this.onTap, this.distanceMeters});

  final LiveVan van;
  final VoidCallback onTap;
  final double? distanceMeters;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final detalhes = <String>[
      if (van.placa.isNotEmpty) van.placa,
      if (van.rota != null) van.rota!.titulo,
      if (van.temPosicao) PassengerFormat.ago(van.posicaoEm),
      if (distanceMeters != null) PassengerFormat.distance(distanceMeters!),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                VanAvatar(active: van.emOperacao, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(van.titulo, style: textTheme.titleMedium),
                      if (detalhes.isNotEmpty)
                        Text(detalhes, style: textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                VanStatusBadge(van: van),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }
}
