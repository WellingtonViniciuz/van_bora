import 'dart:async';

/// Compartilha uma única assinatura da [source] entre várias telas e entrega o
/// último valor recebido a quem começar a ouvir depois.
///
/// A assinatura da fonte abre com o primeiro ouvinte e fecha quando o último
/// sai, então nenhum listener do Firestore fica aberto à toa.
class SharedStream<T> {
  SharedStream(this._source);

  final Stream<T> Function() _source;
  final _listeners = <MultiStreamController<T>>{};
  StreamSubscription<T>? _subscription;
  T? _last;
  bool _hasLast = false;

  Stream<T> get stream => Stream<T>.multi((controller) {
        _listeners.add(controller);
        if (_hasLast) controller.add(_last as T);
        _subscription ??= _source().listen(
          (value) {
            _last = value;
            _hasLast = true;
            for (final l in _listeners.toList()) {
              l.add(value);
            }
          },
          onError: (Object e, StackTrace st) {
            for (final l in _listeners.toList()) {
              l.addError(e, st);
            }
            // Permite tentar de novo na próxima assinatura.
            _subscription?.cancel();
            _subscription = null;
          },
        );
        controller.onCancel = () {
          _listeners.remove(controller);
          if (_listeners.isEmpty) {
            _subscription?.cancel();
            _subscription = null;
          }
        };
      });
}

/// Emite uma lista com o último valor de cada fonte assim que todas tiverem
/// emitido pelo menos uma vez.
Stream<List<Object?>> combineLatest(List<Stream<Object?>> sources) {
  late StreamController<List<Object?>> controller;
  final subs = <StreamSubscription<Object?>>[];
  final values = List<Object?>.filled(sources.length, null);
  final ready = List<bool>.filled(sources.length, false);

  controller = StreamController<List<Object?>>(
    onListen: () {
      for (var i = 0; i < sources.length; i++) {
        subs.add(sources[i].listen(
          (v) {
            values[i] = v;
            ready[i] = true;
            if (ready.every((r) => r)) controller.add(List.unmodifiable(values));
          },
          onError: controller.addError,
        ));
      }
    },
    onCancel: () async {
      for (final s in subs) {
        await s.cancel();
      }
      subs.clear();
    },
  );
  return controller.stream;
}
