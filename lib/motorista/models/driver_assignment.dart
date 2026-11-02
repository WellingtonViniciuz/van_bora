class DriverAssignment {
  const DriverAssignment({
    required this.motoristaId,
    required this.nome,
    required this.vanId,
    required this.vanNome,
    required this.placa,
    required this.rotaId,
    required this.rotaCodigo,
    required this.origem,
    required this.destino,
  });

  factory DriverAssignment.fromMap(String id, Map<String, dynamic> map) {
    return DriverAssignment(
      motoristaId: id,
      nome: map['nome'] as String? ?? '',
      vanId: map['vanId'] as String? ?? '',
      vanNome: map['vanNome'] as String? ?? '',
      placa: map['placa'] as String? ?? '',
      rotaId: map['rotaId'] as String? ?? '',
      rotaCodigo: map['rotaCodigo'] as String? ?? '',
      origem: map['origem'] as String? ?? '',
      destino: map['destino'] as String? ?? '',
    );
  }

  final String motoristaId;
  final String nome;
  final String vanId;
  final String vanNome;
  final String placa;
  final String rotaId;
  final String rotaCodigo;
  final String origem;
  final String destino;

  String get vanTitle => '$vanNome – $placa';

  String get rotaSubtitle => 'Rota $rotaCodigo · $origem → $destino';
}
