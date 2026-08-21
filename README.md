# Divisão de Tarefas - Aplicativo de Gestão para Transporte Alternativo

Com base na documentação detalhada do seu projeto, a maneira mais inteligente e eficiente de dividir o trabalho entre 3 pessoas para um aplicativo Flutter com essas características é fazer a **divisão por perfis de usuário (Módulos)**.

Isso evita conflitos de código (merge conflicts no Git), permite que cada um foque em uma jornada completa e distribui as complexidades técnicas (Mapas, GPS em background, e CRUDs de administração).

Aqui está a proposta de divisão das telas e responsabilidades para a sua equipe:

---

### 🧑‍💻 Pessoa 1: Módulo do Passageiro (Foco em Consumo de Dados e Mapas)

**Perfil da missão:** Esta pessoa lidará muito com a Google Maps API, `Streams` (para tempo real) e design focado no usuário final.

**Telas sob responsabilidade:**

1. **Tela de Login / Cadastro (Passageiro):** Autenticação simples (pode ser via telefone ou Google).
2. **Tela Inicial (Home do Passageiro):** Lista de rotas/linhas disponíveis para escolha.
3. **Tela de Previsão e Detalhes:**
* Exibir o horário estimado da próxima van (RF09).
* Exibir a foto/nome do motorista da vez e placa do veículo (RF11).
4. **Tela de Rastreamento (Mapa):**
* Integração com Google Maps API.
* Consumo do `Stream` (Firebase Firestore ou WebSocket) para animar o ícone da van se movendo no mapa em tempo real (RF10, RF12).

---

### 🧑‍💻 Pessoa 2: Módulo do Motorista (Foco em Usabilidade, GPS e Modo Offline)

**Perfil da missão:** Esta pessoa tem o maior desafio de UX (Interface fácil para motoristas mais velhos, botões grandes - RNF05) e o desafio técnico de capturar o GPS e lidar com falta de internet (Desafio 1).

**Telas sob responsabilidade:**

1. **Tela de Login (Motorista):** Acesso com credenciais fornecidas pela empresa.
2. **Tela da Fila de Saída:**
* Visualizar em qual posição ele está na fila e quem está na frente (RF08).
3. **Tela de Operação (Em Rota - O "Painel" do motorista):**
* Botão GIGANTE para **"Iniciar Rota"** (RF05).
* Botões de acesso rápido para **"Informar Lotação"** (Ex: Vazia, Metade, Cheia) (RF07).
* Botão GIGANTE para **"Encerrar Rota"** (RF06).
4. **Lógica de Background:** Configurar o envio da localização do celular para o servidor em tempo real (RF12) e implementar a lógica *offline-first* (salvar localmente se a internet cair e enviar quando voltar).

---

### 🧑‍💻 Pessoa 3: Módulo Empresa/Admin e Arquitetura Base (Foco em Gestão e CRUDs)

**Perfil da missão:** Esta pessoa vai estruturar a base do app (configurar Firebase, arquitetura MVC/MVVM) e criar as telas de gerenciamento, lidando com formulários e listas.

**Telas sob responsabilidade:**

1. **Configuração Base (Junto com a equipe):** Criar o projeto no Flutter, configurar Firebase, definir paleta de cores e componentes globais (ex: um botão padrão, um input padrão).
2. **Tela de Login (Admin):** Acesso restrito para gestores.
3. **Dashboard (Home do Admin):** Visão geral de quantas vans estão rodando, quem está na fila, etc.
4. **Tela de Gestão de Frota:** Formulário para cadastrar, editar e excluir veículos (RF01).
5. **Tela de Gestão de Motoristas:** Formulário para cadastrar, validar e vincular motoristas aos veículos (RF02).
6. **Tela de Configuração de Rotas e Escalas:** Tela para definir o trajeto, pontos e configurar o tempo de intervalo entre as vans (RF03).
7. **Painel de Auditoria/Histórico:** Uma tela de relatório para a empresa ver as viagens finalizadas no dia (centralização de informações).

---

### 💡 Dicas de Sucesso para a Equipe (Como trabalhar juntos)

Para que essa divisão funcione sem dor de cabeça no Flutter, recomendo os seguintes passos antes de começarem a codar:

1. **Dia 0 (Reunião de Alinhamento):**
* Definam o nome das pastas (ex: `screens`, `models`, `controllers`, `services`).
* Definam as cores do app e fontes.
* Modelem o banco de dados juntos (Como será a coleção "Users", "Vans", "Routes" no Firestore).
2. **Uso do Git/GitHub:** Cada um deve criar uma *branch* com o nome do seu módulo (ex: `feature/modulo-motorista`). Só juntem o código (merge) na `main` quando a tela estiver funcionando.
3. **Criação de Componentes Compartilhados:** A Pessoa 3 (ou quem for mais rápido) pode criar uma pasta `widgets` com um botão customizado e campos de texto. Assim as Telas 1, 2 e 3 ficarão com o mesmo visual, mesmo sendo feitas por pessoas diferentes.

Essa divisão deixa a carga de trabalho muito equilibrada, pois a **Pessoa 1** cuida da complexidade visual (Mapas), a **Pessoa 2** da complexidade de hardware (GPS/Sensores) e a **Pessoa 3** da complexidade de dados e arquitetura (CRUDs e Gestão).
