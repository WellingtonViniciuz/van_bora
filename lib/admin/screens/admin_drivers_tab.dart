import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/vb_confirm_dialog.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../models/admin_driver.dart';
import '../widgets/admin_widgets.dart';

class AdminDriversTab extends StatelessWidget {
  const AdminDriversTab({super.key, required this.controller});

  final AdminDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final list = controller.drivers;
    if (list.isEmpty) {
      return const AdminEmptyState(
        icon: Icons.badge_rounded,
        message: 'Nenhum motorista cadastrado.\nToque em "Novo motorista" para começar.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final d = list[index];
        final pendente = switch ((d.temVan, d.temRota)) {
          (false, false) => 'Sem van e sem rota vinculadas',
          (false, true) => 'Sem van vinculada',
          (true, false) => 'Sem rota vinculada',
          _ => null,
        };
        return AdminListCard(
          icon: Icons.badge_rounded,
          title: d.nome,
          lines: [
            if (d.temVan) '${d.vanNome} – ${d.placa}',
            if (d.temRota) 'Rota ${d.rotaCodigo} · ${d.origem} → ${d.destino}',
          ],
          warning: pendente,
          onTap: () => showDriverForm(context, controller, d),
          onDelete: () => _delete(context, d),
        );
      },
    );
  }

  Future<void> _delete(BuildContext context, AdminDriver d) async {
    final confirmed = await showVbConfirm(
      context,
      title: 'Excluir ${d.nome}?',
      message: d.temVan
          ? '${d.vanNome} ficará sem motorista. Esta ação não pode ser desfeita.'
          : 'Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      danger: true,
    );
    if (!confirmed || !context.mounted) return;
    await runAdminAction(context, () => controller.deleteDriver(d.id),
        success: '${d.nome} excluído.');
  }
}

typedef _DriverForm = ({AdminDriver driver, String vanId, String rotaId});

Future<void> showDriverForm(
  BuildContext context,
  AdminDashboardController controller, [
  AdminDriver? driver,
]) async {
  final result = await showDialog<_DriverForm>(
    context: context,
    builder: (_) => _DriverFormDialog(controller: controller, driver: driver),
  );
  if (result == null || !context.mounted) return;
  await runAdminAction(
    context,
    () => controller.saveDriver(result.driver, vanId: result.vanId, rotaId: result.rotaId),
    success: driver == null
        ? '${result.driver.nome} cadastrado.'
        : '${result.driver.nome} atualizado.',
  );
}

class _DriverFormDialog extends StatefulWidget {
  const _DriverFormDialog({required this.controller, this.driver});

  final AdminDashboardController controller;
  final AdminDriver? driver;

  @override
  State<_DriverFormDialog> createState() => _DriverFormDialogState();
}

class _DriverFormDialogState extends State<_DriverFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.driver?.nome ?? '');

  // '' = sem vínculo. Ignora ids de vans/rotas que foram excluídas.
  late String _vanId = widget.controller.vehicleById(widget.driver?.vanId ?? '')?.id ?? '';
  late String _rotaId = widget.controller.routeById(widget.driver?.rotaId ?? '')?.id ?? '';

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final base = widget.driver ?? const AdminDriver(id: '', nome: '');
    Navigator.pop<_DriverForm>(
      context,
      (driver: base.copyWith(nome: _nome.text.trim()), vanId: _vanId, rotaId: _rotaId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final meuId = widget.driver?.id ?? '';

    final vanItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: '', child: Text('Nenhuma')),
      for (final v in c.vehicles)
        () {
          final ocupante = c.driverOfVehicle(v.id);
          final ocupada = ocupante != null && ocupante.id != meuId;
          return DropdownMenuItem(
            value: v.id,
            enabled: !ocupada,
            child: Text(
              ocupada ? '${v.titulo} – ${v.placa} (com ${ocupante.nome})' : '${v.titulo} – ${v.placa}',
              overflow: TextOverflow.ellipsis,
              style: ocupada ? const TextStyle(color: AppColors.disabled) : null,
            ),
          );
        }(),
    ];

    final rotaItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: '', child: Text('Nenhuma')),
      for (final r in c.routes)
        DropdownMenuItem(
          value: r.id,
          child: Text('${r.codigo} · ${r.percurso}', overflow: TextOverflow.ellipsis),
        ),
    ];

    return AdminFormDialog(
      title: widget.driver == null ? 'Novo motorista' : 'Editar motorista',
      formKey: _formKey,
      onSave: _save,
      children: [
        TextFormField(
          controller: _nome,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nome do motorista'),
          validator: (v) => requiredField(v, 'Informe o nome do motorista'),
        ),
        const SizedBox(height: 20),
        Text('Vínculo', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        const Text(
          'O motorista só consegue entrar no app com uma van e uma rota vinculadas.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _vanId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Van',
            prefixIcon: const Icon(Icons.directions_bus_rounded),
            helperText: c.vehicles.isEmpty ? 'Cadastre uma van primeiro' : null,
          ),
          items: vanItems,
          onChanged: (v) => setState(() => _vanId = v ?? ''),
          validator: (v) => (v ?? '').isEmpty && _rotaId.isNotEmpty
              ? 'Escolha também a van'
              : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _rotaId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Rota',
            prefixIcon: const Icon(Icons.map_rounded),
            helperText: c.routes.isEmpty ? 'Cadastre uma rota primeiro' : null,
          ),
          items: rotaItems,
          onChanged: (v) => setState(() => _rotaId = v ?? ''),
          validator: (v) => (v ?? '').isEmpty && _vanId.isNotEmpty
              ? 'Escolha também a rota'
              : null,
        ),
      ],
    );
  }
}
