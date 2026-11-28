import '../../motorista/models/queue_entry.dart';
import 'admin_route.dart';
import 'admin_time.dart';
import 'admin_trip.dart';
import 'admin_vehicle.dart';

enum AdminActivityKind { iniciada, encerrada, semConexao }

class AdminActivity {
  const AdminActivity({
    required this.kind,
    required this.titulo,
    required this.subtitulo,
    required this.vanId,
  });

  final AdminActivityKind kind;
  final String titulo;
  final String subtitulo;
  final String vanId;
}

/// Números e atividades da tela "Visão geral". Calculado a partir das listas
/// já carregadas no controller, sem consultas extras.
class AdminOverview {
  const AdminOverview({
    required this.emOperacao,
    required this.naFila,
    required this.conectadas,
    required this.semConexao,
    required this.atividades,
  });

  /// O motorista envia a localização a cada ~10 s. Sem envio por mais tempo
  /// que isso, a van é considerada sem conexão.
  static const limiteConexao = Duration(minutes: 1);

  final int emOperacao;
  final int naFila;
  final int conectadas;
  final int semConexao;
  final List<AdminActivity> atividades;

  factory AdminOverview.build({
    required List<AdminVehicle> vehicles,
    required List<AdminRoute> routes,
    required List<QueueEntry> queue,
    required List<AdminTrip> trips,
    DateTime? now,
    int maxAtividades = 6,
  }) {
    final agora = now ?? DateTime.now();
    final vansComViagem = {for (final t in trips.where((t) => t.ativa)) t.vanId};
    final vansPorId = {for (final v in vehicles) v.id: v};
    final rotasPorId = {for (final r in routes) r.id: r};

    final operando =
        vehicles.where((v) => v.emRota || vansComViagem.contains(v.id)).toList();
    bool conectada(AdminVehicle v) =>
        v.localizacaoEm != null && agora.difference(v.localizacaoEm!) <= limiteConexao;
    final desconectadas = operando.where((v) => !conectada(v)).toList();

    final atividades = <AdminActivity>[
      for (final v in desconectadas)
        AdminActivity(
          kind: AdminActivityKind.semConexao,
          titulo: '${v.titulo} - Sem conexão',
          subtitulo: v.localizacaoEm == null
              ? 'Nenhuma localização recebida'
              : 'Última atualização ${AdminFormat.ago(v.localizacaoEm!, now: agora)}',
          vanId: v.id,
        ),
    ];

    final viagens = trips.where((t) => t.ultimoEvento != null).toList()
      ..sort((a, b) => b.ultimoEvento!.compareTo(a.ultimoEvento!));
    for (final t in viagens) {
      final van = vansPorId[t.vanId]?.titulo ?? 'Van';
      final rota = rotasPorId[t.rotaId]?.codigo ?? t.rotaId;
      final titulo = rota.isEmpty ? van : '$van - Rota $rota';
      if (t.concluida) {
        atividades.add(AdminActivity(
          kind: AdminActivityKind.encerrada,
          titulo: titulo,
          subtitulo: 'Encerrada às ${AdminFormat.hour(t.ultimoEvento!)}',
          vanId: t.vanId,
        ));
      } else if (t.ativa) {
        atividades.add(AdminActivity(
          kind: AdminActivityKind.iniciada,
          titulo: titulo,
          subtitulo: 'Iniciada às ${AdminFormat.hour(t.ultimoEvento!)}',
          vanId: t.vanId,
        ));
      }
    }

    return AdminOverview(
      emOperacao: operando.length,
      naFila: queue.where((e) => e.aguardando).length,
      conectadas: operando.length - desconectadas.length,
      semConexao: desconectadas.length,
      atividades: atividades.take(maxAtividades).toList(),
    );
  }
}
