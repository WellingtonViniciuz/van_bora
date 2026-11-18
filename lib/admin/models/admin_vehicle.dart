class AdminVehicle {
  const AdminVehicle({
    required this.id,
    required this.vanNome,
    required this.placa,
    required this.capacidade,
    required this.status,
  });

  factory AdminVehicle.fromMap(String id, Map<String, dynamic> map) {
    return AdminVehicle(
      id: id,
      vanNome: map['vanNome'] as String? ?? '',
      placa: map['placa'] as String? ?? '',
      capacidade: (map['capacidade'] as num?)?.toInt() ?? 15,
      status: map['status'] as String? ?? 'disponivel',
    );
  }

  final String id;
  final String vanNome;
  final String placa;
  final int capacidade;
  final String status;

  Map<String, dynamic> toMap() => {
        'vanNome': vanNome,
        'placa': placa,
        'capacidade': capacidade,
        'status': status,
      };
}
