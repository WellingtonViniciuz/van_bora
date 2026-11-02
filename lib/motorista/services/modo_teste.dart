import 'package:flutter/foundation.dart';

import '../models/driver_assignment.dart';
import '../models/queue_entry.dart';

/// Login de teste para desenvolvimento. Só funciona em modo debug.
/// Usuário: teste | Senha: teste123
class ModoTeste {
  ModoTeste._();

  static bool get ativo => kDebugMode;

  static const usuario = 'teste';
  static const senha = 'teste123';
  static const uid = 'teste-uid';

  static bool credenciaisValidas(String user, String pass) {
    return ativo && user.trim() == usuario && pass == senha;
  }

  static const assignment = DriverAssignment(
    motoristaId: uid,
    nome: 'Motorista de Teste',
    vanId: 'van12',
    vanNome: 'Van 12',
    placa: 'QXV-4821',
    rotaId: 'rf09',
    rotaCodigo: 'RF09',
    origem: 'Centro',
    destino: 'IFPE',
  );

  // O motorista de teste começa em 1º lugar para o botão "Ir para o painel" aparecer.
  static const fila = <QueueEntry>[
    QueueEntry(
      motoristaId: uid,
      vanNome: 'Van 12',
      motoristaNome: 'Motorista de Teste',
      status: 'aguardando',
      ordem: 1,
    ),
    QueueEntry(
      motoristaId: 'teste-van08',
      vanNome: 'Van 08',
      motoristaNome: 'Roberto',
      status: 'aguardando',
      ordem: 2,
    ),
    QueueEntry(
      motoristaId: 'teste-van04',
      vanNome: 'Van 04',
      motoristaNome: 'Carlos',
      status: 'aguardando',
      ordem: 3,
    ),
  ];
}