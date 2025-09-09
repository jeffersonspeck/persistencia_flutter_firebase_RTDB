# Projeto Estudo Dirigido: Introdução ao Firebase Realtime Database

[Crie conta aqui e um projeto](https://console.firebase.google.com/)

Este repositório é um **guia prático** que demonstra como **inicializar** e usar o **Firebase Realtime Database (RTDB)** em um projeto. Através de um aplicativo de exemplo, você aprenderá a realizar operações essenciais (CRUD), trabalhar com dados em tempo real, gerenciar regras de segurança e otimizar o uso offline.

---

## Sumário

# Sumário

1. [Visão Geral do Projeto e Caso de Estudo](#visão-geral-do-projeto-e-caso-de-estudo)
2. [Fundamentos: O que é Firebase, RTDB e Firestore](#fundamentos-o-que-é-firebase-rtdb-e-firestore)  
    2.1 [O que é o Firebase](#o-que-é-o-firebase)  
    2.2 [Entendendo o Firebase Realtime Database (RTDB)](#entendendo-o-firebase-realtime-database-rtdb)  
    2.3 [O que é o Cloud Firestore](#o-que-é-o-cloud-firestore)  
    2.4 [Por que não usamos o Firestore neste projeto](#por-que-não-estamos-usando-o-firestore-neste-projeto)
3. [Decisões de Arquitetura Adotadas](#decisões-adotadas-neste-projeto-e-por-quê)
4. [Documentação Oficial Utilizada (PT-BR)](#documentação-oficial-utilizada-pt-br)
5. [Utilizando o Projeto](#utilizando-o-projeto)  
    5.1 [Pré-requisitos](#1-pré-requisitos)  
    5.2 [Criar o banco e escolher o modo](#2-criar-o-banco-e-escolher-o-modo)  
    5.3 [Configuração do projeto Flutter](#3-configuração-do-projeto-flutter)  
    5.4 [Inicializar no código e rodar](#34-inicializar-no-código-e-rodar)  
    5.5 [Problemas comuns (e correções rápidas)](#35-problemas-comuns-e-correções-rápidas)  
    5.6 [Links úteis (oficiais)](#links-úteis-oficiais)
6. [Modelagem de Dados no RTDB (JSON) e Boas Práticas](#4-estrutura-de-dados-json-e-boas-práticas)  
    6.1 [Push IDs, desnormalização e consistência](#como-funciona-o-pushid-gerado-por-push--desnormalização-índices-e-consistência)  
    6.2 [Índices, consultas e paginação](#índices-e-consultas--paginação)  
    6.3 [Chaves, tipos e limites importantes + Checklist](#chaves-tipos-e-limites-importantes--checklist-de-modelagem)
7. [Regras de Segurança (exemplos)](#5-regras-de-segurança-exemplos)
8. [Operações de Leitura e Escrita](#6-leitura-e-escrita)  
    8.1 [Referências, set/push, update, remove, get, streams](#61-referências--set--push--update--remover--get--stream)  
    8.2 [Ordenação, filtros e índices](#67-como-ordenar--combinar-com-filtros--índices-para-performance)
9. [Recursos Off-line e Presença](#8-recursos-off-line)
10. [Sync vs Async no Flutter/Dart](#9-diferença-entre-síncrono-sync-e-assíncrono-async-no-flutterdart)
11. [JSON e modelagem: reforço conceitual](#10-json-e-modelagem)
12. [Material da Aula e Passos Rápidos](#material-da-aula)

# Documentação do Projeto
  - [Documentação do Projeto](documentation.md)
  - [Documentação do Projeto Orientado a Funções](class_docs.md)
---

## Visão Geral do Projeto e Caso de Estudo

### Nosso Caso de Estudo: Um App de TODOs

O projeto utiliza um aplicativo de lista de tarefas para ilustrar os principais conceitos. Veja o que você vai aprender:

* **Operações CRUD:**

  * **Criação:** Usando `push().set` para adicionar novas tarefas.
  * **Leitura em tempo real:** Com `Query.onValue`, o app se mantém sincronizado com o banco de dados.
  * **Atualização e Exclusão:** Métodos `update` e `remove` para modificar e apagar tarefas.
* **Funcionalidades Avançadas:**

  * **Persistência Offline:** Entenda como o app funciona mesmo sem conexão, com `keepSynced(true)`.
  * **Monitoramento de Conexão:** Saiba como usar o caminho `/.info/connected` para verificar o status da conexão do Firebase.

---

## Fundamentos: O que é Firebase, RTDB e Firestore

### O que é o Firebase

O **Firebase** é uma plataforma de **back-end como serviço (BaaS)** da Google, projetada para acelerar o desenvolvimento de aplicativos web e mobile. Ele oferece um conjunto de serviços gerenciados, como autenticação, bancos de dados, armazenamento de arquivos, hospedagem e análise, permitindo que os desenvolvedores foquem no código do aplicativo, sem se preocuparem com a infraestrutura.

**Por que usar o Firebase?**

* **Sem Gerenciamento de Infraestrutura:** O Firebase cuida da escalabilidade e alta disponibilidade para você.
* **SDKs Integrados:** Ferramentas prontas para uso que se conectam facilmente ao seu código.
* **Testes e Análise:** Oferece um pacote de emuladores para desenvolvimento local e ferramentas de observabilidade para monitorar o desempenho do app.

---

### Entendendo o Firebase Realtime Database (RTDB)

O **Realtime Database** é um banco de dados **NoSQL** hospedado na nuvem, que armazena os dados como uma grande **árvore JSON**. Sua principal característica é a **sincronização em tempo real**, onde qualquer alteração no banco de dados é instantaneamente refletida em todos os clientes conectados.

**Principais Características:**

* **Modelo de Dados Simples:** A estrutura em árvore JSON é ideal para dados que não exigem consultas complexas com `joins` ou relações intrincadas.
* **Sincronização em Tempo Real:** Escute eventos para ser notificado imediatamente sobre qualquer mudança em um nó do banco de dados.
* **Consultas Básicas:** Utilize `orderBy*()` e filtros para realizar consultas simples e diretas.
* **Regras de Segurança:** Defina regras declarativas (`.read` e `.write`) para controlar o acesso aos seus dados.
* **Suporte Offline:** O RTDB mantém um cache local e uma fila de escritas, garantindo que as operações continuem funcionando mesmo sem conexão.

> **Nota:** O RTDB é diferente do **Cloud Firestore**. Enquanto o RTDB é ideal para latência muito baixa e sincronização contínua de dados simples, o Firestore oferece um modelo de documentos e coleções mais flexível e consultas mais avançadas.

---

### O que é o Cloud Firestore

O **Cloud Firestore** é um banco de dados **NoSQL** flexível e escalável, desenvolvido pela Google e integrado ao Firebase e ao Google Cloud Platform. Ele armazena os dados em um modelo de **documentos e coleções**, o que o torna ideal para organizar dados complexos em uma estrutura hierárquica.

Assim como o Realtime Database, o Firestore também oferece sincronização em tempo real. No entanto, sua arquitetura é otimizada para consultas mais poderosas e eficientes, permitindo que você filtre, ordene e pagine dados com mais facilidade. Além disso, a cobrança é baseada no número de operações (leituras, escritas, exclusões), o que pode ser mais vantajoso em muitos cenários.

---

### Por que não estamos usando o Firestore neste projeto?

Embora o Cloud Firestore seja uma ferramenta excelente e poderosa, optamos por focar no **Firebase Realtime Database (RTDB)** neste estudo dirigido por razões didáticas e de escopo.

1. **Modelo de Dados Simples:** O RTDB, com sua estrutura de árvore JSON, é perfeito para o nosso aplicativo de lista de TODOs. Ele nos permite demonstrar os conceitos básicos de sincronização em tempo real de uma forma mais direta e fácil de entender.
2. **Foco nos Fundamentos:** O objetivo deste projeto é introduzir os conceitos de back-end como serviço (BaaS) e operações de dados em tempo real. O RTDB é uma porta de entrada ideal para isso, pois seu modelo de dados e consultas são mais simples de absorver para quem está começando.
3. **Cenário de Uso Específico:** Para a nossa aplicação de exemplo, que lida com dados relativamente simples e com alta taxa de atualizações, o RTDB é a escolha mais adequada. Seu modelo de eventos em tempo real é altamente otimizado para esse tipo de cenário.

Em resumo, a escolha pelo RTDB não é uma desvalorização do Firestore, mas sim uma decisão estratégica para focar na simplicidade e nos fundamentos necessários para um estudo dirigido inicial.

---

## Decisões adotadas neste projeto (e por quê)

1. **adicione `firebase_options.dart`**

```dart
  const String kRtdbUrl = 'https://<SEU-BANCO>.firebaseio.com';
  //CRIE SEU RTDB NO CONSOLE DO FIREBASE https://console.firebase.google.com/
```

2. **Estrutura e caminhos**

   * Nó principal: `/todos/{pushId}` (chave única de `push()`).
   * Formato de cada item:

     ```json
     {
       "text": "Comprar café",
       "done": false,
       "timestamp": 1725800000000
     }
     ```
   * `timestamp` usa **`ServerValue.timestamp`** (servidor preenche o horário).

3. **Leitura em tempo real & consultas**

   * Listener com `Query.onValue`.
   * Consulta: `orderByChild('timestamp').limitToLast(100)`; UI ordena em memória.

4. **Indicador de conexão**

   * Usa o nó especial `/.info/connected` (booleano) para exibir online/off-line.

5. **Off-line (por plataforma)**

   * **Android/iOS/Desktop**: habilita `setPersistenceEnabled(true)` (cache em disco, fila de escritas).
   * **Web**: não habilita persistência em disco (cache é de **sessão**).
   * `keepSynced(true)` em `/todos` para manter esse nó no cache enquanto o app está aberto.

---

## Documentação oficial utilizada (PT-BR)

* **Visão geral do Realtime Database**
  [https://firebase.google.com/docs/database?hl=pt-br](https://firebase.google.com/docs/database?hl=pt-br)
* **Começar com RTDB (Flutter)**
  [https://firebase.google.com/docs/database/flutter/start?hl=pt-br](https://firebase.google.com/docs/database/flutter/start?hl=pt-br)
* **Estruturar dados (JSON)**
  [https://firebase.google.com/docs/database/flutter/structure-data?hl=pt-br](https://firebase.google.com/docs/database/flutter/structure-data?hl=pt-br)
* **Ler & gravar dados**
  [https://firebase.google.com/docs/database/flutter/read-and-write?hl=pt-br](https://firebase.google.com/docs/database/flutter/read-and-write?hl=pt-br)
* **Listas & consultas**
  [https://firebase.google.com/docs/database/flutter/lists-of-data?hl=pt-br](https://firebase.google.com/docs/database/flutter/lists-of-data?hl=pt-br)
* **Recursos off-line**
  [https://firebase.google.com/docs/database/flutter/offline-capabilities?hl=pt-br](https://firebase.google.com/docs/database/flutter/offline-capabilities?hl=pt-br)

---

## Utilizando o Projeto

### 1) Pré-requisitos

* Flutter instalado (3.x ou superior).
* Conta no Firebase com um projeto criado.
* Acesso ao Console do Firebase.

---

### 2) Criar o banco e escolher o modo

No **Console do Firebase**:

1. Realtime Database → **Criar banco de dados**.
2. **Modo de teste** (apenas para começar).
   Atenção: após o período de teste, as regras expiram e passam a negar solicitações por padrão.
3. **Região** do banco (define o `databaseURL`).
4. Concluir.

> Produção: use **modo bloqueado** + regras adequadas (ver seção **Regras**).

---

### 3) Configuração do projeto Flutter

#### 3.1 Dependências (Flutter)

```bash
flutter pub add firebase_core firebase_database
```

#### 3.2 Ferramentas de linha de comando necessárias

Para o `flutterfire configure` funcionar (ele é quem **gera o `lib/firebase_options.dart`**), você precisa ter:

1. **Firebase CLI** instalado **e logado**
2. **FlutterFire CLI** instalado (via `dart pub global`)
3. O **PATH** configurado para você poder chamar `flutterfire` de qualquer terminal

##### 3.2.1 Instalar o Firebase CLI (Windows)

**Opção A) Standalone (sem Node)**

1. Baixe o binário: [https://firebase.tools](https://firebase.tools)
2. `firebase --version`
3. `firebase login`

**Opção B) Via npm (requer Node.js ≥ 18)**

1. Instale Node.js LTS: [https://nodejs.org/en/download/](https://nodejs.org/en/download/)
2. `npm install -g firebase-tools`
3. `firebase --version` e `firebase login`

##### 3.2.2 Instalar o FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

No **Windows**, adicione **`%LOCALAPPDATA%\Pub\Cache\bin`** ao **Path** do sistema.
Cheque:

```bash
where flutterfire
flutterfire --version
```

#### 3.3 Vincular seu app ao Firebase (gera `firebase_options.dart`)

Na **raiz do projeto Flutter**:

```bash
flutterfire configure
```

Selecione o projeto, marque plataformas (inclua **Web** se usar `-d edge`/`-d chrome`) e gere/atualize `lib/firebase_options.dart`.

#### 3.4 Inicializar no código e rodar

```bash
flutter run
```

Para Web:

```bash
flutter config --enable-web
flutter run -d edge
```

#### 3.5 Problemas comuns (e correções rápidas)

* **`firebase` não é reconhecido** → Instale o Firebase CLI (Standalone ou npm) e teste `firebase --version`.
* **`flutterfire` não é reconhecido** → Ative via `dart pub global` e adicione `%LOCALAPPDATA%\Pub\Cache\bin` ao **Path**; abra um novo terminal e teste `where flutterfire`.
* **`lib/firebase_options.dart` ausente** → Rode `flutterfire configure` na raiz do projeto.
* **Web não conecta** → Confirme que a plataforma Web foi marcada no `flutterfire configure` e que o projeto correto foi selecionado.

#### Links úteis (oficiais)

* Setup Flutter + Firebase: [https://firebase.google.com/docs/flutter/setup](https://firebase.google.com/docs/flutter/setup)
* Firebase CLI: [https://firebase.google.com/docs/cli](https://firebase.google.com/docs/cli) — download direto: [https://firebase.tools](https://firebase.tools)
* Node.js (para instalar CLI via npm): [https://nodejs.org/en/download/](https://nodejs.org/en/download/)
* `dart pub global` (PATH): [https://dart.dev/tools/pub/cmd/pub-global](https://dart.dev/tools/pub/cmd/pub-global)

---

## 4) Estrutura de dados (JSON) e boas práticas

O **Realtime Database (RTDB)** guarda tudo em **uma árvore JSON**. Você modela os nós (chaves) e valores, pensando **como vai ler** e **como vai escrever** os dados — isso é o que mais influencia performance e custo.

### Exemplo mínimo (este app)

```json
{
  "todos": {
    "-NrX12...": { "text": "Estudar RTDB", "done": false, "timestamp": 1700000000000 },
    "-NrX9a...": { "text": "Implementar app", "done": true,  "timestamp": 1700000100000 }
  }
}
```

### Como funciona o `{pushId}` gerado por `push()`

No RTDB, quando você chama `ref.push()`, o Firebase cria **uma chave única** baseada em **timestamp + entropia aleatória**.
Isso garante que:

* não haja colisão mesmo com vários usuários escrevendo ao mesmo tempo,
* os registros fiquem **ordenáveis cronologicamente** pela própria chave.

#### Exemplo visual

```json
{
  "todos": {
    "-Nabc123xy": { "text": "Comprar pão",   "done": false, "timestamp": 1700000000001 },
    "-Nabc124jk": { "text": "Estudar RTDB",  "done": false, "timestamp": 1700000005000 },
    "-Nabc125mn": { "text": "Implementar app", "done": true, "timestamp": 1700000010000 }
  }
}
```

#### Comparando com IDs fixos

Se você usasse seus próprios IDs (ex.: `todo1`, `todo2`), poderia haver conflito. Com `pushId`, cada cliente obtém uma chave única sem sobrescrever dados.

---

### Desnormalização, índices e consistência

**1) Listas rápidas**
Mantenha coleções enxutas para carregar pouco dado e listar rápido.

**2) Relacionamentos (N↔N)**
Modele com mapas índice `{ id: true }`, ex.: `/user-todos/{userId}/{todoId}: true`.

**3) Consistência (atualização atômica)**
Se duplicar dados, use `update()` com **múltiplos caminhos** para manter tudo em sincronia:

```dart
final updates = {
  "/todos/-NrX12/text": "Novo título",
  "/user-todos/user123/-NrX12/text": "Novo título"
};
await rtdb.ref().update(updates);
```

---

### Índices e consultas  |  Paginação

**Regras (DEV, exemplo didático)**

```json
{
  "rules": {
    "todos": {
      ".read": true,
      ".write": true,
      ".indexOn": ["timestamp", "text_lc"]
    }
  }
}
```

**Consultas comuns**

```dart
// últimos 100 pelo timestamp
rtdb.ref('todos').orderByChild('timestamp').limitToLast(100);

// prefix search (campo normalizado "text_lc")
final q = rtdb.ref('todos')
  .orderByChild('text_lc')
  .startAt('estu')
  .endAt('estu\uf8ff');
```

**Paginação**
Use `limitToLast(N)` e combine com `endAt(...)` para paginação para trás (mais recentes primeiro).

---

### Chaves, tipos e limites importantes  |  Checklist de modelagem

**Chaves próprias (se não usar `push()`)**

* UTF-8 até **768 bytes**; não pode conter `. $ # [ ] /` nem ASCII 0–31 e 127.

**Ordenação por tipo**
`null` → `false` → `true` → números → strings → objetos.

**Timestamps confiáveis**
Prefira `ServerValue.timestamp`.

**Checklist**

* [ ] Dados planos, poucos níveis
* [ ] `push()` para listas concorrentes
* [ ] Campos normalizados (ex.: `text_lc`)
* [ ] `.indexOn` nos campos usados em consultas
* [ ] `update` multi-local em dados duplicados
* [ ] `timestamp` do servidor
* [ ] Relacionamentos via mapas-índice `{ id: true }`

---

## 5) Regras de segurança (exemplos)

### 5.1 Regras para teste (temporárias)

```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

### 5.2 Regras mais restritivas (exigem auth)

```json
{
  "rules": {
    "todos": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["timestamp"]
    }
  }
}
```

---

## 6) Leitura e escrita

### 6.1 Referências  |  set / push  |  update  |  remover  |  get  |  stream

```dart
final ref = FirebaseDatabase.instance.ref();      // raiz
final todosRef = FirebaseDatabase.instance.ref('todos');

// Criar (push + set)
final newRef = todosRef.push();
await newRef.set({
  'text': 'Novo item',
  'done': false,
  'timestamp': ServerValue.timestamp,
});

// Atualizar parcialmente
await todosRef.child('<pushId>').update({'done': true});

// Remover
await todosRef.child('<pushId>').remove();

// Ler uma vez
final snap = await todosRef.get();
if (snap.exists) {
  // processa snap.value
}

// Ler em tempo real
final q = todosRef.orderByChild('timestamp').limitToLast(100);
q.onValue.listen((DatabaseEvent e) {
  // e.snapshot.children
});
```

### 6.7 Como ordenar  |  Combinar com filtros  |  Índices para performance

**Ordenação**

1. `orderByChild("campo")`
2. `orderByKey()`
3. `orderByValue()`

**Filtros após ordenar**
`limitToFirst`, `limitToLast`, `startAt`, `endAt`, `equalTo`.

**Índices nas regras**
Para qualquer campo usado com `orderByChild`, inclua em `.indexOn`.

---

## 8) Recursos off-line

```dart
FirebaseDatabase.instance.setPersistenceEnabled(true);
```

* `keepSynced(true)` mantém um caminho sincronizado:

```dart
final scoresRef = FirebaseDatabase.instance.ref('scores');
scoresRef.keepSynced(true);
```

**Conexão (`/.info/connected`)**:

```dart
final connectedRef = FirebaseDatabase.instance.ref('.info/connected');
connectedRef.onValue.listen((e) {
  final online = e.snapshot.value == true;
});
```

**onDisconnect**:

```dart
final presenceRef = FirebaseDatabase.instance.ref('users/joe/lastOnline');
presenceRef.onDisconnect().set(ServerValue.timestamp);
```

---

## 9) Diferença entre **síncrono (sync)** e **assíncrono (async)** no Flutter/Dart

* **Sync**: imediato; bom para memória/cálculos rápidos.
* **Async**: rede/disco; usa `Future` e `Stream`; não bloqueia UI.
* Utilize `async/await`, `FutureBuilder` (resultado único) e `StreamBuilder` (eventos contínuos).

**Exemplo no app (RTDB)**

```dart
await Firebase.initializeApp(); // async

await rtdb.ref('todos').push().set({
  'text': 'Item',
  'done': false,
  'timestamp': ServerValue.timestamp,
});

StreamBuilder<DatabaseEvent>(
  stream: rtdb.ref('todos').onValue,
  builder: (context, snapshot) {
    if (!snapshot.hasData) return Text("Carregando...");
    final dados = snapshot.data!.snapshot.value;
    return Text(dados.toString());
  },
);
```

---

## 10) JSON e modelagem

* RTDB é uma **árvore JSON**.
* Evite aninhamentos profundos, **desnormalize** quando necessário.
* Estruture chaves e índices para acessos comuns (ex.: `timestamp`, `userId`).

---

# Material da Aula

```
rtdb_todos/
├─ pubspec.yaml
├─ README.md
└─ lib/
   ├─ config/
   │  └─ database_config.dart        // kRtdbUrl centralizado
   ├─ data/
   │  ├─ models/
   │  │  └─ todo_item.dart           // fromMap, toMap, copyWith, fromSnapshot
   │  └─ repositories/
   │     ├─ todo_repository.dart     // contrato
   │     └─ firebase_todo_repository.dart // implementação RTDB
   └─ main.dart                      // init Firebase + instanceFor(databaseURL) + DI
```

## Passos rápidos

1. Instale dependências e gere o `firebase_options.dart`:

```bash
flutter pub get
dart pub global activate flutterfire_cli
flutterfire configure
```

2. Ajuste a URL no `lib/config/database_config.dart` se precisar (Se não existir o arquivo CRIE):

```dart
const String kRtdbUrl = 'https://<sua-url>.firebaseio.com';
```

3. Rode:

```bash
flutter run -d edge
```