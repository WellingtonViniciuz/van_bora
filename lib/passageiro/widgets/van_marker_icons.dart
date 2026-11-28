import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_colors.dart';

/// Tipos de marcador desenhados para o mapa do passageiro.
enum PassengerMarkerKind { vanActive, vanIdle, vanSelected, stop }

/// Gera (e guarda em cache) os ícones personalizados dos marcadores:
/// van em rota (verde-azulado), van parada (cinza), van selecionada (azul
/// escuro, maior) e ponto de parada.
class VanMarkerIcons {
  VanMarkerIcons._();

  static final _cache = <String, Future<BitmapDescriptor>>{};

  static Future<BitmapDescriptor> get(PassengerMarkerKind kind, double devicePixelRatio) {
    final key = '${kind.name}@$devicePixelRatio';
    return _cache.putIfAbsent(key, () => _draw(kind, devicePixelRatio));
  }

  /// Carrega todos os ícones de uma vez.
  static Future<Map<PassengerMarkerKind, BitmapDescriptor>> loadAll(double dpr) async {
    final entries = await Future.wait(
      PassengerMarkerKind.values.map((k) async => MapEntry(k, await get(k, dpr))),
    );
    return Map.fromEntries(entries);
  }

  static Future<BitmapDescriptor> _draw(PassengerMarkerKind kind, double dpr) async {
    final (double size, Color fill, IconData? icon) = switch (kind) {
      PassengerMarkerKind.vanActive => (44, AppColors.primary, Icons.airport_shuttle_rounded),
      PassengerMarkerKind.vanIdle => (38, AppColors.textMuted, Icons.airport_shuttle_rounded),
      PassengerMarkerKind.vanSelected => (54, AppColors.navy, Icons.airport_shuttle_rounded),
      PassengerMarkerKind.stop => (18, AppColors.surface, null),
    };
    final px = size * dpr;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(px / 2, px / 2);
    final radius = px / 2 - 2 * dpr;

    canvas.drawCircle(
      center.translate(0, dpr),
      radius,
      Paint()
        ..color = Colors.black26
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * dpr),
    );
    canvas.drawCircle(center, radius, Paint()..color = fill);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (kind == PassengerMarkerKind.stop ? 4 : 3) * dpr
        ..color = kind == PassengerMarkerKind.stop ? AppColors.primary : Colors.white,
    );

    if (icon != null) {
      final painter = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: px * 0.5,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            color: Colors.white,
          ),
        )
        ..layout();
      painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
    }

    final image = await recorder.endRecording().toImage(px.round(), px.round());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BytesMapBitmap(
      bytes!.buffer.asUint8List(),
      width: size,
      height: size,
    );
  }
}
