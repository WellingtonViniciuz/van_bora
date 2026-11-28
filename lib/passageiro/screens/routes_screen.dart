import 'package:flutter/material.dart';

import '../../app/route_names.dart';
import '../../core/widgets/vb_text_field.dart';
import '../controllers/passenger_controller.dart';
import '../models/passenger_route.dart';
import '../widgets/passenger_banners.dart';
import '../widgets/passenger_state_view.dart';
import '../widgets/route_tile.dart';

/// Aba "Rotas": lista de rotas cadastradas pelo admin, com busca.
class RoutesTab extends StatefulWidget {
  const RoutesTab({super.key, required this.controller});

  final PassengerController controller;

  @override
  State<RoutesTab> createState() => _RoutesTabState();
}

class _RoutesTabState extends State<RoutesTab> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final c = widget.controller;
    return SafeArea(
      child: ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          final filtradas = c.routes.where((r) => r.corresponde(_search.text)).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            children: [
              Text('Olá!\nPara onde você vai?', style: textTheme.headlineSmall),
              const SizedBox(height: 16),
              VbTextField(
                controller: _search,
                hint: 'Buscar rota, bairro ou destino',
                icon: Icons.search_rounded,
                textInputAction: TextInputAction.search,
                suffix: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar busca',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _search.clear,
                      ),
              ),
              const SizedBox(height: 16),
              PassengerBanners(controller: c, showLocation: false),
              const SizedBox(height: 8),
              Text('Rotas disponíveis', style: textTheme.titleMedium),
              const SizedBox(height: 12),
              ..._content(c, filtradas),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _content(PassengerController c, List<PassengerRoute> filtradas) {
    if (c.error != null && c.routes.isEmpty) {
      return [
        PassengerStateView(
          icon: Icons.cloud_off_rounded,
          title: 'Não foi possível carregar as rotas',
          message: c.error!,
          actionLabel: 'Tentar novamente',
          onAction: c.retry,
        ),
      ];
    }
    if (c.loading) return const [PassengerStateView.loading(message: 'Carregando as rotas...')];
    if (c.routes.isEmpty) {
      return const [
        PassengerStateView(
          icon: Icons.alt_route_rounded,
          title: 'Nenhuma rota cadastrada',
          message: 'As rotas aparecem aqui assim que a empresa cadastrá-las.',
        ),
      ];
    }
    if (filtradas.isEmpty) {
      return [
        PassengerStateView(
          icon: Icons.search_off_rounded,
          title: 'Nenhuma rota encontrada',
          message: 'Nenhuma rota corresponde a "${_search.text.trim()}".',
        ),
      ];
    }
    return [
      for (final route in filtradas)
        RouteTile(
          route: route,
          vansEmOperacao: c.vansEmOperacaoNaRota(route.id),
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.passengerRoute, arguments: route.id),
        ),
    ];
  }
}
