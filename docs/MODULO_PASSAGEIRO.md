# Módulo do Passageiro — Van Bora

O passageiro **não tem login nem cadastro**. Na tela inicial, "É um passageiro?" abre direto o mapa das vans.

## Telas

| Rota (`AppRoutes`) | Tela | O que mostra |
|---|---|---|
| `/passageiro` | `PassengerHomeScreen` | Aba **Mapa**: vans em tempo real, sua localização, resumo das vans em rota. Aba **Rotas**: busca e lista de rotas. |
| `/passageiro/van` (arg: id da van) | `VanDetailsScreen` | Status, viagem, motorista, placa, capacidade, lotação, rota, intervalo. |
| `/passageiro/rota` (arg: id da rota) | `RouteDetailsScreen` | Trajeto e paradas no mapa (se cadastrados), intervalo, vans da rota. |
| `/passageiro/acompanhar` (arg: id da van) | `VanTrackingScreen` | Mapa seguindo a van, trajeto já percorrido, distância até você, última atualização. |

## De onde vêm os dados (sem coleções novas)

O passageiro **só lê** o que os outros módulos já gravam:

| Coleção | Quem grava | O passageiro usa |
|---|---|---|
| `vans` | Admin (cadastro) e motorista (`localizacao`, `localizacaoEm`, `status`, `lotacao`) | Posição, status e lotação em tempo real |
| `motoristas` | Admin | Nome do motorista e vínculo van → rota |
| `viagens` (status `ativa`) | Motorista (`iniciarRota`/`encerrarRota`) | Viagem em andamento e horário de início |
| `viagens/{id}/pontos` | Motorista (a cada leitura do GPS) | Linha do trajeto já percorrido |
| `rotas` | Admin | Código, origem, destino, intervalo |

O acompanhamento usa os `snapshots()` do Firestore (Streams). Não existe uma segunda forma de transmitir a localização: o passageiro lê a mesma posição que `MotoristaRemoteService._localizacao` grava.

### Limitação: trajeto e paradas das rotas
O cadastro de rotas do admin grava só `codigo`, `origem`, `destino` e `intervaloMinutos`. O passageiro já lê dois campos **opcionais** no documento da rota. Se eles existirem, o trajeto e as paradas aparecem no mapa:

```json
{
  "paradas": [ { "nome": "Centro", "lat": -8.0631, "lng": -34.8780 } ],
  "trajeto": [ GeoPoint(-8.0631, -34.8780), GeoPoint(-8.0545, -34.8985) ]
}
```

Enquanto o admin não tiver esses campos no formulário, a tela da rota avisa "Trajeto não cadastrado" e mostra só as vans. O modelo de dados não foi alterado. A estimativa de chegada ("próxima van em X min") **não** foi implementada, porque não há ponto de embarque nem horários cadastrados para calculá-la sem inventar valores. No lugar dela, o app mostra a distância até você e a hora da última atualização.

## Modo demonstração (debug)
Em debug (`ModoTeste.ativo`), o passageiro usa `DemoPassengerSource`, como o admin e o motorista já fazem com seus dados de teste. As vans se movem sobre rotas de exemplo em Recife, e **todas as telas mostram o aviso "Modo demonstração"**. Em release, o app lê o Firestore.

## Configuração externa necessária

### 1. Chave do Google Maps (obrigatória para ver o mapa)
1. No Google Cloud Console, ative **Maps SDK for Android** (e **Maps SDK for iOS**, se for usar iOS) e crie uma chave de API restrita ao pacote `com.vambora.app.vam_bora`.
2. Rode passando a chave. Ela **não fica no código**:
   ```
   flutter run --dart-define=MAPS_API_KEY=SUA_CHAVE
   ```
   O `android/app/build.gradle.kts` lê esse valor e o coloca no `AndroidManifest.xml`.
3. Sem a chave, o app não trava: mostra "Mapa indisponível" e as mesmas informações em lista.
4. iOS: além do `--dart-define`, é preciso chamar `GMSServices.provideAPIKey("SUA_CHAVE")` no `ios/Runner/AppDelegate.swift`.

### 2. Firebase real
`lib/main.dart` usa opções de teste (`vanbora-local-test`). Para dados reais, rode `flutterfire configure` e troque as opções.

### 3. Regras do Firestore para o passageiro
O passageiro não faz login, então precisa de **leitura pública** só no que ele usa. Sugestão:
```
match /vans/{id}       { allow read: if true; }
match /rotas/{id}      { allow read: if true; }
match /viagens/{id}    { allow read: if true;
  match /pontos/{p}    { allow read: if true; } }
match /motoristas/{id} { allow read: if true; } // expõe nome/vínculo; avalie a privacidade
```
Se a equipe não quiser `motoristas` público, o app continua funcionando e mostra "Motorista não informado".

## Executar no VS Code
1. Instale as extensões **Flutter** e **Dart**.
2. Abra a pasta `van_bora`, escolha o emulador ou o celular na barra de status e aperte **F5**.
3. Para passar a chave do Maps, crie `.vscode/launch.json`:
   ```json
   { "version": "0.2.0", "configurations": [
     { "name": "Van Bora", "request": "launch", "type": "dart",
       "args": ["--dart-define=MAPS_API_KEY=SUA_CHAVE"] } ] }
   ```
   Não faça commit desse arquivo com a chave.

## Testar num Android físico
1. No celular: **Configurações → Sobre o telefone → toque 7 vezes em "Número da versão"**. Depois, em **Opções do desenvolvedor**, ligue a **Depuração USB**.
2. Ligue o cabo USB e aceite a autorização no celular. `flutter devices` deve listar o aparelho.
3. Rode `flutter run --dart-define=MAPS_API_KEY=SUA_CHAVE`.
4. Na tela inicial, toque em **"É um passageiro?"** e permita a localização.

## Testes
`flutter test` cobre a leitura dos modelos, a junção van + motorista + viagem + rota, os formatadores, o compartilhamento de Streams, a fonte de demonstração e os widgets principais (`test/passageiro/`).
