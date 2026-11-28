import 'package:flutter/material.dart';

import '../../core/widgets/vb_confirm_dialog.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../models/admin_route.dart';
import '../widgets/admin_widgets.dart';

class AdminRoutesTab extends StatelessWidget {
  const AdminRoutesTab({super.key, required this.controller});

  final AdminDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final list = controller.routes;
    if (list.isEmpty) {
      return const AdminEmptyState(
        icon: Icons.map_rounded,
        message: 'Nenhuma rota cadastrada.\nToque em "Nova rota" para começar.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final r = list[index];
        final motoristas = controller.driversOfRoute(r.id);
        return AdminListCard(
          icon: Icons.map_rounded,
          title: 'Rota ${r.codigo}',
          lines: [
            r.percurso,
            'Saída a cada ${r.intervaloMinutos} min',
            if (motoristas.isNotEmpty)
              motoristas.length == 1
                  ? '1 motorista: ${motoristas.first.nome}'
                  : '${motoristas.length} motoristas',
          ],
          warning: motoristas.isEmpty ? 'Nenhum motorista nesta rota' : null,
          onTap: () => showRouteForm(context, controller, r),
          onDelete: () => _delete(context, r),
        );
      },
    );
  }

  Future<void> _delete(BuildContext context, AdminRoute r) async {
    final motoristas = controller.driversOfRoute(r.id).length;
    final confirmed = await showVbConfirm(
      context,
      title: 'Excluir rota ${r.codigo}?',
      message: motoristas == 0
          ? 'Esta ação não pode ser desfeita.'
          : '$motoristas motorista(s) ficarão sem rota vinculada. Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      danger: true,
    );
    if (!confirmed || !context.mounted) return;
    await runAdminAction(context, () => controller.deleteRoute(r.id),
        success: 'Rota ${r.codigo} excluída.');
  }
}

Future<void> showRouteForm(
  BuildContext context,
  AdminDashboardController controller, [
  AdminRoute? route,
]) async {
  final result = await showDialog<AdminRoute>(
    context: context,
    builder: (_) => _RouteFormDialog(controller: controller, route: route),
  );
  if (result == null || !context.mounted) return;
  await runAdminAction(
    context,
    () => controller.saveRoute(result),
    success: route == null ? 'Rota ${result.codigo} cadastrada.' : 'Rota ${result.codigo} atualizada.',
  );
}

class _RouteFormDialog extends StatefulWidget {
  const _RouteFormDialog({required this.controller, this.route});

  final AdminDashboardController controller;
  final AdminRoute? route;

  @override
  State<_RouteFormDialog> createState() => _RouteFormDialogState();
}

class _RouteFormDialogState extends State<_RouteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _codigo = TextEditingController(text: widget.route?.codigo ?? '');
  late final _origem = TextEditingController(text: widget.route?.origem ?? '');
  late final _destino = TextEditingController(text: widget.route?.destino ?? '');
  late final _intervalo =
      TextEditingController(text: (widget.route?.intervaloMinutos ?? 30).toString());

  @override
  void dispose() {
    _codigo.dispose();
    _origem.dispose();
    _destino.dispose();
    _intervalo.dispose();
    super.dispose();
  }

  String? _validarCodigo(String? value) {
    final erro = requiredField(value, 'Informe o código da rota');
    if (erro != null) return erro;
    if (widget.controller.codigoEmUso(value!, exceptId: widget.route?.id ?? '')) {
      return 'Já existe uma rota com esse código';
    }
    return null;
  }

  String? _validarIntervalo(String? value) {
    final n = int.tryParse(value?.trim() ?? '');
    if (n == null || n < 1 || n > 240) return 'Informe um número entre 1 e 240';
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      AdminRoute(
        id: widget.route?.id ?? '',
        codigo: _codigo.text.trim().toUpperCase(),
        origem: _origem.text.trim(),
        destino: _destino.text.trim(),
        intervaloMinutos: int.parse(_intervalo.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormDialog(
      title: widget.route == null ? 'Nova rota' : 'Editar rota',
      formKey: _formKey,
      onSave: _save,
      children: [
        TextFormField(
          controller: _codigo,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Código da rota (ex: RF12)'),
          validator: _validarCodigo,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _origem,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Origem'),
          validator: (v) => requiredField(v, 'Informe a origem'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _destino,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Destino'),
          validator: (v) => requiredField(v, 'Informe o destino'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _intervalo,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Intervalo entre as vans (min)'),
          validator: _validarIntervalo,
        ),
      ],
    );
  }
}
