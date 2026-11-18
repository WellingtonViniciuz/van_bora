class AdminDriver {
  const AdminDriver({
    required this.id,
    required this.nome,
    required this.vanId,
    required this.vanNome,
    required this.placa,
    required this.rotaId,
    required this.rotaCodigo,
    required this.origem,
    required this.destino,
  });

  factory AdminDriver.fromMap(String id, Map<String, dynamic> map) {
    return AdminDriver(
      id: id,
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

  final String id;
  final String nome;
  final String vanId;
  final String vanNome;
  final String placa;
  final String rotaId;
  final String rotaCodigo;
  final String origem;
  final String destino;

  Map<String, dynamic> toMap() => {
        'nome': nome,
        'vanId': vanId,
        'vanNome': vanNome,
        'placa': placa,
        'rotaId': rotaId,
        'rotaCodigo': rotaCodigo,
        'origem': origem,
        'destino': destino,
      };
}
