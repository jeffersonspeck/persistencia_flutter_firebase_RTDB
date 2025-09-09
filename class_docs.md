# RTDB TODO App — Orientado a Funções

## Índice

- [Como ler](#como-ler)

- [lib/main.dart](#libmaindart)
  - [1) main() — ponto de entrada da aplicação](#1-main--ponto-de-entrada-da-aplicação)
  - [2) RtdbDemoApp.build — configuração do MaterialApp](#2-rtdbdemoappbuild--configuração-do-materialapp)
  - [3) TodoHomePage (construtor)](#3-todohomepage-construtor)
  - [4) _TodoHomePageState.initState — inicialização do estado e streams](#4-_todohomepagestateinitstate--inicialização-do-estado-e-streams)
  - [5) _TodoHomePageState.dispose — limpeza](#5-_todohomepagestatedispose--limpeza)
  - [6) _addTodo() — criação de item](#6-_addtodo--criação-de-item)
  - [7) _toggleDone(TodoItem) — alternar concluído](#7-_toggledonetodoitem--alternar-concluído)
  - [8) _remove(TodoItem) — excluir item](#8-_removetodoitem--excluir-item)
  - [9) _clearAll() — excluir todos os itens](#9-_clearall--excluir-todos-os-itens)
  - [10) _snack(String) — feedback de erro/ação](#10-_snackstring--feedback-de-erroação)
  - [11) _TodoHomePageState.build — layout da tela](#11-_todohomepagestatebuild--layout-da-tela)
  - [12) _Composer.build — entrada de texto](#12-_composerbuild--entrada-de-texto)
  - [13) _ConnectionBadge.build — status online/off-line](#13-_connectionbadgebuild--status-onlineoff-line)
  - [14) _CenterMsg.build — mensagem centralizada](#14-_centermsgbuild--mensagem-centralizada)

- [lib/data/models/todo_item.dart](#libdatamodelstodo_itemdart)
  - [15) Construtor imutável](#15-construtor-imutável)
  - [16) TodoItem.fromSnapshot — cria a partir do RTDB](#16-todoitemfromsnapshot--cria-a-partir-do-rtdb)
  - [17) TodoItem.fromMap — útil para testes/mocks](#17-todoitemfrommap--útil-para-testesmocks)
  - [18) toMap — serialização](#18-tomap--serialização)
  - [19) copyWith — imutabilidade ergonômica](#19-copywith--imutabilidade-ergonômica)

- [lib/data/repositories/todo_repository.dart (Contrato)](#libdatarepositoriestodo_repositorydart-contrato)
  - [20) Assinaturas do repositório](#20-assinaturas-do-repositório)

- [lib/data/repositories/firebase_todo_repository.dart (Implementação RTDB)](#libdatarepositoriesfirebase_todo_repositorydart-implementação-rtdb)
  - [21) Construtor — referências e keepSynced](#21-construtor--referências-e-keepsynced)
  - [22) watchTodos — stream da lista](#22-watchtodos--stream-da-lista)
  - [23) watchConnection — presença](#23-watchconnection--presença)
  - [24) addTodo — criação](#24-addtodo--criação)
  - [25) toggleDone — alternar concluído](#25-toggledone--alternar-concluído)
  - [26) remove — excluir por chave](#26-remove--excluir-por-chave)
  - [27) clearAll — apagar tudo](#27-clearall--apagar-tudo)

- [Observações finais (arquitetura e Flutter)](#observações-finais-arquitetura-e-flutter)

## Como ler

* Cada seção traz **o código da função/método** e, logo abaixo, a **explicação detalhada**.
* Também aponto **de onde vêm** tipos/constantes usados e **como** a função se relaciona com outras camadas.
* O caminho do **arquivo** fica no início de cada bloco.

---

## `lib/main.dart`

### 1) `main()` — ponto de entrada da aplicação

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Inicializa o Firebase (arquivo gerado pela FlutterFire CLI)
  final app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2) Cria a instância do RTDB *explicitando* a URL do seu banco.
  //    Isso evita editar o firebase_options.dart e resolve erros na Web.
  rtdb = FirebaseDatabase.instanceFor(
    app: app,
    databaseURL: conf.kRtdbUrl,
  );

  // 3) Persistência offline:
  //    - Android/iOS/Desktop: cache em disco suportado → opcional habilitar.
  //    - Web: cache é apenas em memória da sessão → NÃO chamar aqui.
  if (!kIsWeb) {
    try {
      rtdb.setPersistenceEnabled(true);
      // rtdb.setPersistenceCacheSizeBytes(20 * 1024 * 1024); // opcional
    } catch (e) {
      // Em algumas plataformas, repetir essa chamada lança erro (já habilitado).
      // Trate como "best effort" para não interromper o app.
    }
  }

  // 4) Injeta o repositório com a dependência do RTDB
  todosRepo = FirebaseTodoRepository(database: rtdb, defaultLimit: 100);

  runApp(const RtdbDemoApp());
}
```

**Arquivo:** `lib/main.dart`
**O que faz:** inicializa Flutter e Firebase, cria uma instância **explícita** do Realtime Database (RTDB) com URL vinda de `conf.kRtdbUrl`, configura **persistência offline** (quando suportado), instancia o **repositório** e roda o app.

**Elementos-chave e origens:**

* `WidgetsFlutterBinding.ensureInitialized()` (Flutter): garante bindings antes de operações async nativas.
* `Firebase.initializeApp(...)` (package `firebase_core`): lê credenciais geradas pela **FlutterFire CLI** em `firebase_options.dart` (classe `DefaultFirebaseOptions`).
* `FirebaseDatabase.instanceFor(...)` (package `firebase_database`): cria a instância do RTDB **sem** editar `firebase_options.dart`.

  * `databaseURL: conf.kRtdbUrl` vem de `lib/config/database_config.dart`.
* `kIsWeb` (de `package:flutter/foundation.dart`): detecta plataforma Web para **não** ligar persistência de disco no browser.
* `rtdb` e `todosRepo` são `late final` globais (definidos no topo do arquivo) para **injeção** nas camadas de UI.
* `FirebaseTodoRepository` (sua implementação do contrato `TodoRepository`) fica em `lib/data/repositories/firebase_todo_repository.dart`.

---

### 2) `RtdbDemoApp.build` — configuração do MaterialApp

```dart
@override
Widget build(BuildContext context) {
  return MaterialApp(
    title: 'Firebase RTDB Demo',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true),
    home: TodoHomePage(repo: todosRepo),
  );
}
```

**Arquivo:** `lib/main.dart` (classe `RtdbDemoApp` – `StatelessWidget`)
**O que faz:** devolve a raiz do app (`MaterialApp`) com tema **Material 3**, oculta o banner de debug e define a tela inicial (`home`) como `TodoHomePage`, recebendo o repositório `todosRepo`.

**Elementos:**

* `MaterialApp` (Flutter): configura navegação, tema e internacionalização.
* `ThemeData(useMaterial3: true)`: ativa tokens/estilos M3.
* `TodoHomePage(repo: todosRepo)`: **injeção de dependência** do repositório na UI principal.

---

### 3) `TodoHomePage` (construtor)

```dart
class TodoHomePage extends StatefulWidget {
  final TodoRepository repo;
  const TodoHomePage({super.key, required this.repo});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}
```

**Arquivo:** `lib/main.dart`
**O que faz:** expõe a página principal como `StatefulWidget`, recebendo um `TodoRepository`. O `State` associado é `_TodoHomePageState`.

**Elementos:**

* `TodoRepository` (interface): definida em `lib/data/repositories/todo_repository.dart`.
* `createState()`: padrão Flutter para widgets com estado.

---

### 4) `_TodoHomePageState.initState` — inicialização do estado e streams

```dart
@override
void initState() {
  super.initState();
  _todosStream = widget.repo.watchTodos(limit: 100);
  _connStream = widget.repo.watchConnection();
  _connSub = _connStream.listen((ok) {
    if (mounted) setState(() => _connected = ok);
  });
}
```

**Arquivo:** `lib/main.dart`
**O que faz:** cria as **streams** de TODOs e de **conexão** e assina a de conexão para atualizar o badge.

**Elementos:**

* `watchTodos(limit: 100)` e `watchConnection()` pertencem ao **contrato** `TodoRepository` e são implementados por `FirebaseTodoRepository`.
* `_connSub`: `StreamSubscription<bool>` que atualiza `_connected` via `setState` (apenas se o widget estiver `mounted`).
* Relacionamentos:

  * `FirebaseTodoRepository.watchTodos()` usa RTDB (`orderByChild('timestamp')`, etc.).
  * `FirebaseTodoRepository.watchConnection()` observa `/.info/connected`.

---

### 5) `_TodoHomePageState.dispose` — limpeza

```dart
@override
void dispose() {
  _textCtrl.dispose();
  _connSub?.cancel();
  super.dispose();
}
```

**Arquivo:** `lib/main.dart`
**O que faz:** encerra recursos nativos/streams para evitar vazamento de memória.

**Elementos:**

* `_textCtrl` é `TextEditingController` usado no `_Composer`.
* `_connSub` cancela a assinatura da stream de conexão.

---

### 6) `_addTodo()` — criação de item

```dart
Future<void> _addTodo() async {
  final text = _textCtrl.text.trim();
  if (text.isEmpty) return;

  _textCtrl.clear();
  FocusScope.of(context).unfocus();

  try {
    await widget.repo.addTodo(text);
  } catch (e) {
    _snack('Falha ao adicionar: $e');
  }
}
```

**Arquivo:** `lib/main.dart`
**O que faz:** lê o texto do input, valida, limpa o campo, fecha o teclado e chama `repo.addTodo(text)`.

**Elementos:**

* `TextEditingController` (`_textCtrl`): gerencia o valor do `TextField`.
* `FocusScope.of(context).unfocus()`: fecha o teclado.
* `TodoRepository.addTodo` → implementado por `FirebaseTodoRepository.addTodo`:

  * Usa `push().set({ text, done:false, timestamp: ServerValue.timestamp })` no RTDB.

---

### 7) `_toggleDone(TodoItem)` — alternar concluído

```dart
Future<void> _toggleDone(TodoItem item) async {
  try {
    await widget.repo.toggleDone(item);
  } catch (e) {
    _snack('Falha ao atualizar: $e');
  }
}
```

**Arquivo:** `lib/main.dart`
**O que faz:** chama o repositório para inverter o campo `done` do item.

**Relacionamento:** `FirebaseTodoRepository.toggleDone` → `update({'done': !item.done})` no caminho `/todos/{key}`.

---

### 8) `_remove(TodoItem)` — excluir item

```dart
Future<void> _remove(TodoItem item) async {
  try {
    await widget.repo.remove(item.key);
  } catch (e) {
    _snack('Falha ao remover: $e');
  }
}
```

**Arquivo:** `lib/main.dart`
**O que faz:** usa a chave `key` do `TodoItem` para remover o nó.

**Relacionamento:** `FirebaseTodoRepository.remove(key)` → `ref.child(key).remove()`.

---

### 9) `_clearAll()` — excluir todos os itens

```dart
Future<void> _clearAll() async {
  try {
    await widget.repo.clearAll();
  } catch (e) {
    _snack('Falha ao limpar: $e');
  }
}
```

**Arquivo:** `lib/main.dart`
**O que faz:** apaga **todo** o nó `/todos`.

**Relacionamento:** `FirebaseTodoRepository.clearAll()` → `ref.remove()` no caminho `/todos`.

> **Atenção**: função destrutiva — apenas para **demo**.

---

### 10) `_snack(String)` — feedback de erro/ação

```dart
void _snack(String msg) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
```

**Arquivo:** `lib/main.dart`
**O que faz:** mostra mensagem ao usuário via `SnackBar`.

**Elementos:** `ScaffoldMessenger` (Flutter) gerencia snackbars/dialogs dentro do `Scaffold`.

---

### 11) `_TodoHomePageState.build` — layout da tela

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Row(children: [
        const Text('RTDB — Todos'),
        const SizedBox(width: 12),
        _ConnectionBadge(connected: _connected),
      ]),
      actions: [
        IconButton(
          tooltip: 'Limpar todos',
          onPressed: _clearAll,
          icon: const Icon(Icons.delete_sweep),
        ),
      ],
    ),
    body: Column(
      children: [
        _Composer(controller: _textCtrl, onSubmit: _addTodo),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<List<TodoItem>>(
            stream: _todosStream,
            builder: (context, snap) {
              if (snap.hasError) return const _CenterMsg('Erro ao carregar.');
              if (!snap.hasData) return const _CenterMsg('Carregando...');

              final items = snap.data!;
              if (items.isEmpty) {
                return const _CenterMsg('Nenhum item. Adicione um acima.');
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final it = items[i];
                  final when = (it.timestamp != null)
                      ? DateTime.fromMillisecondsSinceEpoch(it.timestamp!).toLocal()
                      : null;

                  return ListTile(
                    leading: Checkbox(
                      value: it.done,
                      onChanged: (_) => _toggleDone(it),
                    ),
                    title: Text(
                      it.text,
                      style: it.done
                          ? const TextStyle(decoration: TextDecoration.lineThrough)
                          : null,
                    ),
                    subtitle: Text(
                      when != null ? when.toString() : '(aguardando servidor)',
                    ),
                    trailing: IconButton(
                      tooltip: 'Excluir',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _remove(it),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _addTodo,
      icon: const Icon(Icons.add),
      label: const Text('Adicionar'),
    ),
  );
}
```

**Arquivo:** `lib/main.dart`
**O que faz:** compõe toda a UI. O `StreamBuilder` reconstrói a lista **sempre** que a stream de `List<TodoItem>` emite novos valores (tempo real do RTDB).

**Elementos:**

* `Scaffold`, `AppBar`, `IconButton`, `FloatingActionButton` (Flutter Material).
* `_Composer`: input + botão para criar itens.
* `StreamBuilder<List<TodoItem>>`: observa `_todosStream` (vem do `repo.watchTodos`).
* `ListView.separated` + `ListTile`: lista de itens com `Checkbox` e botão excluir.
* Conversão de `timestamp` para `DateTime` local.

---

### 12) `_Composer.build` — entrada de texto

```dart
@override
Widget build(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(left: 16, right: 8, top: 12, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Novo item',
              hintText: 'Digite e pressione Enter',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => onSubmit(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: onSubmit,
          icon: const Icon(Icons.add),
          label: const Text('Adicionar'),
        ),
      ],
    ),
  );
}
```

**Arquivo:** `lib/main.dart` (classe `_Composer` – `StatelessWidget`)
**O que faz:** renderiza campo de texto com `Enter` ou botão para submeter.

**Elementos:**

* `TextEditingController controller`: vem do **pai** (`TodoHomePage`) para ler/limpar o texto.
* `onSubmit`: callback do pai que chama `_addTodo()`.

---

### 13) `_ConnectionBadge.build` — status online/offline

```dart
@override
Widget build(BuildContext context) {
  return Row(children: [
    Icon(connected ? Icons.wifi : Icons.wifi_off, size: 18),
    const SizedBox(width: 4),
    Text(connected ? 'online' : 'off-line'),
  ]);
}
```

**Arquivo:** `lib/main.dart` (`_ConnectionBadge`)
**O que faz:** exibe o status de conexão vinda de `/.info/connected`.

**Elementos:** recebe `connected` como `bool`, atualizado em `_connSub` no `initState`.

---

### 14) `_CenterMsg.build` — mensagem centralizada

```dart
@override
Widget build(BuildContext context) {
  return Center(
    child: Text(
      msg,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyLarge,
    ),
  );
}
```

**Arquivo:** `lib/main.dart` (`_CenterMsg`)
**O que faz:** mostra mensagens genéricas (“Carregando…”, “Erro…”, “Nenhum item…”).

---

## `lib/data/models/todo_item.dart`

### 15) Construtor imutável

```dart
const TodoItem({
  required this.key,
  required this.text,
  required this.done,
  required this.timestamp,
});
```

**O que faz:** cria a entidade **imutável** (usar `copyWith` para alterações).
**Elementos:** `key` é o `pushId` do RTDB; `timestamp` pode ser `null` até o servidor resolver.

---

### 16) `TodoItem.fromSnapshot` — cria a partir do RTDB

```dart
factory TodoItem.fromSnapshot(DataSnapshot s) {
  final raw = s.value;
  final map = (raw is Map) ? Map<Object?, Object?>.from(raw as Map) : const {};

  final text = (map['text'] ?? '').toString();
  final done = (map['done'] == true);

  int? ts;
  final tsRaw = map['timestamp'];
  if (tsRaw is int) ts = tsRaw;
  if (tsRaw is double) ts = tsRaw.toInt();
  if (tsRaw is num) ts = tsRaw.toInt();

  return TodoItem(
    key: s.key ?? '',
    text: text,
    done: done,
    timestamp: ts,
  );
}
```

**Arquivo:** `lib/data/models/todo_item.dart`
**O que faz:** converte `DataSnapshot` (RTDB) em `TodoItem`, sendo **tolerante** a tipos numéricos.

**Elementos/relacionamentos:**

* `DataSnapshot` (package `firebase_database`).
* `s.key` é a chave do nó (pushId).
* Lida com `timestamp` que pode chegar como `int/double/num`.

---

### 17) `TodoItem.fromMap` — útil para testes/mocks

```dart
factory TodoItem.fromMap(Map<String, Object?> map, {required String key}) {
  int? ts;
  final tsRaw = map['timestamp'];
  if (tsRaw is int) ts = tsRaw;
  if (tsRaw is double) ts = tsRaw.toInt();
  if (tsRaw is num) ts = tsRaw.toInt();

  return TodoItem(
    key: key,
    text: (map['text'] ?? '').toString(),
    done: map['done'] == true,
    timestamp: ts,
  );
}
```

**Arquivo:** `lib/data/models/todo_item.dart`
**O que faz:** monta `TodoItem` a partir de um `Map` (sem depender do RTDB).
**Útil para:** testes unitários, fixtures, repositórios “fake”.

---

### 18) `toMap` — serialização

```dart
Map<String, Object?> toMap() => {
  'text': text,
  'done': done,
  'timestamp': timestamp,
};
```

**O que faz:** transforma o modelo em `Map` para persistir ou trafegar.

---

### 19) `copyWith` — imutabilidade ergonômica

```dart
TodoItem copyWith({
  String? key,
  String? text,
  bool? done,
  int? timestamp,
}) {
  return TodoItem(
    key: key ?? this.key,
    text: text ?? this.text,
    done: done ?? this.done,
    timestamp: timestamp ?? this.timestamp,
  );
}
```

**O que faz:** gera um novo `TodoItem` alterando apenas os campos necessários.

---

## `lib/data/repositories/todo_repository.dart` (Contrato)

### 20) Assinaturas do repositório

```dart
abstract class TodoRepository {
  Stream<List<TodoItem>> watchTodos({int limit});
  Stream<bool> watchConnection();
  Future<void> addTodo(String text);
  Future<void> toggleDone(TodoItem item);
  Future<void> remove(String key);
  Future<void> clearAll();
}
```

**O que faz:** define o **contrato** que a UI usa, **sem conhecer** o backend.
**Relacionamento:** implementado por `FirebaseTodoRepository` (outra fonte de dados no futuro, se quiser).

---

## `lib/data/repositories/firebase_todo_repository.dart` (Implementação RTDB)

### 21) Construtor — referências e keepSynced

```dart
FirebaseTodoRepository({
  required FirebaseDatabase database,
  int defaultLimit = 100,
})  : _db = database,
      _todosRef = database.ref('todos'),
      _connectedRef = database.ref('.info/connected') {
  if (!kIsWeb) {
    try {
      _todosRef.keepSynced(true);
    } catch (_) {}
  }
}
```

**O que faz:** guarda referências aos caminhos `/todos` e `/.info/connected`, e tenta manter `/todos` sincronizado **fora da Web** (cache em disco, melhor latência).

**Elementos:**

* `FirebaseDatabase` (injeção a partir do `main()`).
* `keepSynced(true)`: faz pré-busca e mantém **hot cache** do nó.

---

### 22) `watchTodos` — stream da lista

```dart
@override
Stream<List<TodoItem>> watchTodos({int limit = 100}) {
  final q = _db.ref('todos').orderByChild('timestamp').limitToLast(limit);
  return q.onValue.map((event) {
    final root = event.snapshot;
    final items = <TodoItem>[
      for (final child in root.children) TodoItem.fromSnapshot(child),
    ];
    items.sort((a, b) => (a.timestamp ?? 0).compareTo(b.timestamp ?? 0));
    return items;
  });
}
```

**O que faz:** monta uma `Query` (`orderByChild('timestamp') + limitToLast`) e converte cada atualização (`onValue`) em `List<TodoItem>` **ordenada** por `timestamp` ascendente.

**Elementos/relacionamentos:**

* `onValue` (RTDB): stream de **árvore inteira** do nó.
* `TodoItem.fromSnapshot(child)`: converte cada item.
* Ordenação é feita **na memória** para exibir do mais antigo ao mais novo.

---

### 23) `watchConnection` — presença

```dart
@override
Stream<bool> watchConnection() =>
    _connectedRef.onValue.map((e) => e.snapshot.value == true);
```

**O que faz:** observa `/.info/connected` e emite `true/false`.

---

### 24) `addTodo` — criação

```dart
@override
Future<void> addTodo(String text) async {
  final newRef = _todosRef.push();
  await newRef.set({
    'text': text,
    'done': false,
    'timestamp': ServerValue.timestamp, // resolvido no servidor
  });
}
```

**O que faz:** usa `push()` (gera `pushId` único) e `set` com `ServerValue.timestamp`.

**Por que `ServerValue.timestamp`?**
Evita depender do relógio do dispositivo e padroniza horário.

---

### 25) `toggleDone` — alternar concluído

```dart
@override
Future<void> toggleDone(TodoItem item) =>
    _todosRef.child(item.key).update({'done': !item.done});
```

**O que faz:** atualiza **apenas** o campo `done` no nó do item.

---

### 26) `remove` — excluir por chave

```dart
@override
Future<void> remove(String key) => _todosRef.child(key).remove();
```

**O que faz:** apaga o nó `/todos/{key}`.

---

### 27) `clearAll` — apagar tudo

```dart
@override
Future<void> clearAll() => _todosRef.remove();
```

**O que faz:** remove **todos** os itens (`/todos`).

> Use com cuidado (demo).

---

# Observações finais (arquitetura e Flutter)

* **Stateful vs Stateless**:

  * `RtdbDemoApp` é `StatelessWidget` pois só configura `MaterialApp`.
  * `TodoHomePage` é `StatefulWidget` porque gerencia **streams**, **controladores** e **estado** visual (`_connected`).
* **Streams e UI reativa**:
  `StreamBuilder` reconstrói a UI **automaticamente** quando o RTDB emite eventos. Ideal para **tempo real**.
* **Repository Pattern**:
  A UI depende **apenas** de `TodoRepository`. Trocar de RTDB para “Mock” ou outro backend não muda a UI — só a implementação.
* **Persistência offline**:
  Ativada fora da Web para reduzir latência e suportar **modo off-line** com fila de escritas.
* **Erros**:
  Tratados localmente com `_snack`. Em apps reais, considere camadas de **result**/`Either` ou `sealed classes` para erros de domínio.
