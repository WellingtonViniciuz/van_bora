import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vanbora_motorista/passageiro/services/demo_passenger_source.dart';
import 'package:vanbora_motorista/passageiro/services/shared_stream.dart';

void main() {
  group('SharedStream', () {
    test('abre uma única assinatura e repete o último valor', () async {
      var assinaturas = 0;
      final fonte = StreamController<int>.broadcast(onListen: () => assinaturas++);
      final shared = SharedStream<int>(() => fonte.stream);

      final a = <int>[];
      final subA = shared.stream.listen(a.add);
      fonte.add(1);
      await Future<void>.delayed(Duration.zero);

      final b = <int>[];
      final subB = shared.stream.listen(b.add);
      await Future<void>.delayed(Duration.zero);
      fonte.add(2);
      await Future<void>.delayed(Duration.zero);

      expect(assinaturas, 1);
      expect(a, [1, 2]);
      expect(b, [1, 2], reason: 'recebe o último valor ao entrar');

      await subA.cancel();
      await subB.cancel();
      expect(fonte.hasListener, isFalse, reason: 'fecha a fonte quando ninguém ouve');
    });
  });

  group('combineLatest', () {
    test('só emite depois que todas as fontes emitiram', () async {
      final a = StreamController<Object?>();
      final b = StreamController<Object?>();
      final out = <List<Object?>>[];
      final sub = combineLatest([a.stream, b.stream]).listen(out.add);

      a.add(1);
      await Future<void>.delayed(Duration.zero);
      expect(out, isEmpty);

      b.add('x');
      a.add(2);
      await Future<void>.delayed(Duration.zero);
      expect(out, [
        [1, 'x'],
        [2, 'x'],
      ]);
      await sub.cancel();
    });
  });

  group('DemoPassengerSource', () {
    test('é marcada como demonstração e usa as rotas de teste', () async {
      final source = DemoPassengerSource();
      expect(source.isDemo, isTrue);
      final rotas = await source.watchRoutes().first;
      expect(rotas.map((r) => r.id), containsAll(['rf09', 'rf10']));
    });

    test('move as vans em viagem a cada atualização', () async {
      final source = DemoPassengerSource(tick: const Duration(milliseconds: 10));
      final snapshots = await source.watchVans().take(3).toList();
      final primeira = snapshots.first.firstWhere((v) => v.id == 'van12');
      final ultima = snapshots.last.firstWhere((v) => v.id == 'van12');
      expect(primeira.emOperacao, isTrue);
      expect(primeira.motoristaNome, isNotEmpty);
      expect(ultima.posicao, isNot(primeira.posicao));

      final parada = snapshots.last.firstWhere((v) => v.id == 'van04');
      expect(parada.emOperacao, isFalse);
      expect(parada.viagem, isNull);
    });

    test('o trajeto percorrido cresce durante a viagem', () async {
      final source = DemoPassengerSource(tick: const Duration(milliseconds: 10));
      final van = (await source.watchVans().first).firstWhere((v) => v.id == 'van12');
      final trilhas = await source.watchTripTrail(van.viagem!.id).take(3).toList();
      expect(trilhas.first, isNotEmpty);
      expect(trilhas.last.length, greaterThanOrEqualTo(trilhas.first.length));
    });
  });
}
