import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/vb_confirm_dialog.dart';
import '../../core/widgets/vb_status_badge.dart';
import '../controllers/admin_dashboard_controller.dart';
import '../models/admin_vehicle.dart';
import '../widgets/admin_widgets.dart';

class AdminVehiclesTab extends StatelessWidget {
  const AdminVehiclesTab({super.key, required this.controller});

  final AdminDashboardController controller;

  @override
  Widget build(BuildContext context) {
    final list = controller.vehicles;
    if (list.isEmpty) {
      return const AdminEmptyState(
        icon: Icons.directions_bus_rounded,
        message: 'Nenhuma van cadastrada.\nToque em "Nova van" para começar.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final v = list[index];
        final driver = controller.driverOfVehicle(v.id);
        return AdminListCard(
          icon: Icons.directions_bus_rounded,
          title: v.titulo,
          lines: [
            'Placa ${v.placa} · ${v.capacidade} lugares',
            if (driver != null) 'Motorista: ${driver.nome}',
          ],
          warning: driver == null ? 'Sem motorista vinculado' : null,
          badge: vehicleStatusBadge(v),
          onTap: () => showVehicleForm(context, controller, v),
          onDelete: () => _delete(context, v),
        );
      },
    );
  }

  Future<void> _delete(BuildContext context, AdminVehicle v) async {
    final driver = controller.driverOfVehicle(v.id);
    final confirmed = await showVbConfirm(
      context,
      title: 'Excluir ${v.titulo}?',
      message: driver == null
          ? 'Esta ação não pode ser desfeita.'
          : '${driver.nome} ficará sem van vinculada. Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      danger: true,
    );
    if (!confirmed || !context.mounted) return;
    await runAdminAction(context, () => controller.deleteVehicle(v.id),
        success: '${v.titulo} excluída.');
  }
}

Widget vehicleStatusBadge(AdminVehicle v) {
  final (color, background) = switch (v.status) {
    AdminVehicle.statusEmRota => (AppColors.success, AppColors.successSoft),
    AdminVehicle.statusIndisponivel => (AppColors.textMuted, AppColors.neutralSoft),
    _ => (AppColors.primary, AppColors.primarySoft),
  };
  return VbStatusBadge(label: v.statusLabel, color: color, background: background);
}

Future<void> showVehicleForm(
  BuildContext context,
  AdminDashboardController controller, [
  AdminVehicle? vehicle,
]) async {
  final result = await showDialog<AdminVehicle>(
    context: context,
    builder: (_) => _VehicleFormDialog(controller: controller, vehicle: vehicle),
  );
  if (result == null || !context.mounted) return;
  await runAdminAction(
    context,
    () => controller.saveVehicle(result),
    success: vehicle == null ? '${result.titulo} cadastrada.' : '${result.titulo} atualizada.',
  );
}

class _VehicleFormDialog extends StatefulWidget {
  const _VehicleFormDialog({required this.controller, this.vehicle});

  final AdminDashboardController controller;
  final AdminVehicle? vehicle;

  @override
  State<_VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<_VehicleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.vehicle?.vanNome ?? '');
  late final _placa = TextEditingController(text: widget.vehicle?.placa ?? '');
  late final _capacidade =
      TextEditingController(text: (widget.vehicle?.capacidade ?? 15).toString());
  late String _status = widget.vehicle?.status ?? AdminVehicle.statusDisponivel;

  static final _placaValida = RegExp(r'^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$');

  @override
  void dispose() {
    _nome.dispose();
    _placa.dispose();
    _capacidade.dispose();
    super.dispose();
  }

  static String _limparPlaca(String s) => s.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  /// "ABC-1234" no padrão antigo e "ABC1D23" no padrão Mercosul.
  static String _formatarPlaca(String s) {
    final p = _limparPlaca(s);
    final antiga = RegExp(r'^[A-Z]{3}[0-9]{4}$').hasMatch(p);
    return antiga ? '${p.substring(0, 3)}-${p.substring(3)}' : p;
  }

  String? _validarPlaca(String? value) {
    final p = _limparPlaca(value ?? '');
    if (p.isEmpty) return 'Informe a placa';
    if (!_placaValida.hasMatch(p)) return 'Placa inválida (ex: ABC-1234 ou ABC1D23)';
    if (widget.controller.placaEmUso(p, exceptId: widget.vehicle?.id ?? '')) {
      return 'Já existe uma van com essa placa';
    }
    return null;
  }

  String? _validarCapacidade(String? value) {
    final n = int.tryParse(value?.trim() ?? '');
    if (n == null || n < 1 || n > 60) return 'Informe um número entre 1 e 60';
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final base = widget.vehicle ??
        const AdminVehicle(
          id: '',
          vanNome: '',
          placa: '',
          capacidade: 15,
          status: AdminVehicle.statusDisponivel,
        );
    Navigator.pop(
      context,
      base.copyWith(
        vanNome: _nome.text.trim(),
        placa: _formatarPlaca(_placa.text),
        capacidade: int.parse(_capacidade.text.trim()),
        status: _status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emRota = widget.vehicle?.emRota ?? false;
    return AdminFormDialog(
      title: widget.vehicle == null ? 'Nova van' : 'Editar van',
      formKey: _formKey,
      onSave: _save,
      children: [
        TextFormField(
          controller: _nome,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nome da van (ex: Van 10)'),
          validator: (v) => requiredField(v, 'Informe o nome da van'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _placa,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Placa (ex: ABC-1234)'),
          validator: _validarPlaca,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _capacidade,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Capacidade (lugares)'),
          validator: _validarCapacidade,
        ),
        const SizedBox(height: 12),
        if (emRota)
          const Text(
            'Esta van está em rota agora. O status volta a "Disponível" quando o motorista encerrar a viagem.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          )
        else
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _status == AdminVehicle.statusIndisponivel
                ? AdminVehicle.statusIndisponivel
                : AdminVehicle.statusDisponivel,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Situação'),
            items: const [
              DropdownMenuItem(
                value: AdminVehicle.statusDisponivel,
                child: Text('Disponível'),
              ),
              DropdownMenuItem(
                value: AdminVehicle.statusIndisponivel,
                child: Text('Indisponível (manutenção)'),
              ),
            ],
            onChanged: (v) => setState(() => _status = v ?? AdminVehicle.statusDisponivel),
          ),
      ],
    );
  }
}
