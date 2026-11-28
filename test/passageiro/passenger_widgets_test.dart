import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vanbora_motorista/motorista/models/occupancy.dart';
import 'package:vanbora_motorista/passageiro/models/live_van.dart';
import 'package:vanbora_motorista/passageiro/models/passenger_route.dart';
import 'package:vanbora_motorista/passageiro/widgets/passenger_map.dart';
import 'package:vanbora_motorista/passageiro/widgets/route_tile.dart';
import 'package:vanbora_motorista/passageiro/widgets/van_info_card.dart';

// Usa MaterialApp sem o AppTheme para não depender de baixar fontes no teste.
Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  const rota = PassengerRoute(
    id: 'rf09',
    codigo: 'RF09',
    origem: 'Centro',
    destino: 'IFPE',
    intervaloMinutos: 30,
  );

  final van = LiveVan(
    id: 'van12',
    nome: 'Van 12',
    placa: 'QXV-4821',
    status: VanStatus.emRota,
    lotacao: Occupancy.cheia,
    posicao: const LatLng(-8.05, -34.9),
    posicaoEm: DateTime.now(),
    motoristaNome: 'José Carlos',
    rota: rota,
  );

  testWidgets('RouteTile mostra a rota e as vans em rota', (tester) async {
    var tocou = false;
    await tester.pumpWidget(_wrap(
      RouteTile(route: rota, vansEmOperacao: 2, onTap: () => tocou = true),
    ));
    expect(find.text('RF09'), findsOneWidget);
    expect(find.text('Centro → IFPE'), findsOneWidget);
    expect(find.text('2 em rota'), findsOneWidget);
    expect(find.text('a cada 30 min'), findsOneWidget);
    await tester.tap(find.byType(RouteTile));
    expect(tocou, isTrue);
  });

  testWidgets('RouteTile indica rota sem vans', (tester) async {
    await tester.pumpWidget(_wrap(RouteTile(route: rota, vansEmOperacao: 0, onTap: () {})));
    expect(find.text('Sem vans'), findsOneWidget);
  });

  testWidgets('VanInfoCard mostra status, lotação e distância e aciona os botões', (tester) async {
    var detalhes = 0, acompanhar = 0;
    await tester.pumpWidget(_wrap(
      SizedBox(
        width: 380,
        child: VanInfoCard(
          van: van,
          distanceMeters: 1234,
          onDetails: () => detalhes++,
          onTrack: () => acompanhar++,
        ),
      ),
    ));
    expect(find.text('Van 12'), findsOneWidget);
    expect(find.text('RF09 · Centro → IFPE'), findsOneWidget);
    expect(find.text('Em rota'), findsOneWidget);
    expect(find.text('Lotação: Cheia'), findsOneWidget);
    expect(find.text('1,2 km de você'), findsOneWidget);

    await tester.tap(find.text('Detalhes'));
    await tester.tap(find.text('Acompanhar'));
    expect(detalhes, 1);
    expect(acompanhar, 1);
  });

  testWidgets('VanListTile de van parada não mostra lotação', (tester) async {
    const parada = LiveVan(id: 'v', nome: 'Van 04', placa: 'MNO-3482', status: VanStatus.disponivel);
    await tester.pumpWidget(_wrap(VanListTile(van: parada, onTap: () {})));
    expect(find.text('Parada'), findsOneWidget);
    expect(find.textContaining('Lotação'), findsNothing);
  });

  testWidgets('sem chave do Maps, o mapa mostra o aviso em vez de tela vazia', (tester) async {
    // Nos testes não há --dart-define=MAPS_API_KEY.
    await tester.pumpWidget(_wrap(PassengerMap(vans: [van])));
    expect(find.byType(MapUnavailableView), findsOneWidget);
    expect(find.text('Mapa indisponível'), findsOneWidget);
  });
}
