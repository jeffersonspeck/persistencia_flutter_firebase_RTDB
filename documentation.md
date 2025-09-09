# Firebase RTDB — TODO App (Repository Pattern)

Este projeto é um aplicativo de demonstração em Flutter que implementa uma lista de tarefas (TODOs) usando o **Firebase Realtime Database (RTDB)** como backend e o **Repository Pattern** para organizar as camadas de código.

O foco do projeto é **ensinar conceitos essenciais** de Flutter (widgets, estado, streams, futures), Firebase (RTDB, persistência offline, regras, streaming de dados em tempo real) e boas práticas arquiteturais (injeção de dependência, separação de responsabilidades).

---

## Sumário

1. [Visão geral da arquitetura](#visão-geral-da-arquitetura)
2. [Fluxo principal do app](#fluxo-principal-do-app)
3. [Estrutura de arquivos](#estrutura-de-arquivos)
4. [Explicação classe a classe](#explicação-classe-a-classe)

   * [TodoItem (model)](#todoitem-model)
   * [TodoRepository (interface)](#todorepository-interface)
   * [FirebaseTodoRepository (implementação)](#firebasetodorepository-implementação)
   * [main.dart](#maindart)
   * [Widgets de UI](#widgets-de-ui)
5. [Regras de segurança do RTDB](#regras-de-segurança-do-rtdb)
6. [Boas práticas e observações](#boas-práticas-e-observações)

---

## Visão geral da arquitetura

O app é dividido em **três camadas principais**:

1. **Configuração**
   Centraliza variáveis como `kRtdbUrl` (URL do banco), mantendo o `firebase_options.dart` intacto.

2. **Camada de dados (Data Layer)**
   Contém:

   * **Model**: classe `TodoItem`, que representa cada registro no RTDB.
   * **Repository**: contrato (`TodoRepository`) e implementação (`FirebaseTodoRepository`) que isolam a lógica de acesso ao banco.

   → Esse padrão é conhecido como **Repository Pattern**: a UI nunca fala diretamente com o Firebase, mas sim com um repositório que abstrai a fonte de dados.

3. **Camada de apresentação (UI Layer)**
   Widgets Flutter (`TodoHomePage`, `_Composer`, `_ConnectionBadge`, etc.) que consomem os repositórios, exibem dados e recebem interações do usuário.

---

## Fluxo principal do app

1. **Inicialização**

   * O Flutter é inicializado com `WidgetsFlutterBinding.ensureInitialized()`.
   * O Firebase é inicializado com `Firebase.initializeApp()`.
   * Criamos uma instância explícita do RTDB com `FirebaseDatabase.instanceFor(app, databaseURL: kRtdbUrl)`.

2. **Persistência Offline**

   * Em Android/iOS/Desktop: habilitamos `setPersistenceEnabled(true)` para cache em disco.
   * Em Web: não habilitamos (na Web o cache é apenas em memória da aba).

3. **Repository**

   * `FirebaseTodoRepository` é injetado na UI como `todosRepo`.

4. **UI**

   * `TodoHomePage` consome streams (`watchTodos`, `watchConnection`) para exibir lista e status de conexão.
   * Ações do usuário (`Adicionar`, `Marcar concluído`, `Excluir`, `Limpar todos`) chamam métodos do repositório, que refletem imediatamente no RTDB e disparam eventos em tempo real para atualizar a UI.

---

## Estrutura de arquivos

```
lib/
├─ config/
│  └─ database_config.dart         # URL do RTDB
├─ data/
│  ├─ models/
│  │  └─ todo_item.dart            # classe TodoItem
│  └─ repositories/
│     ├─ todo_repository.dart      # interface TodoRepository
│     └─ firebase_todo_repository.dart # implementação com RTDB
└─ main.dart                        # inicialização Firebase + UI principal
```

---

## Explicação classe a classe

### TodoItem (model)

Representa um **registro da lista de TODOs** no RTDB.

* `key`: identificador único (pushId gerado pelo Firebase).
* `text`: texto da tarefa.
* `done`: booleano indicando se a tarefa foi concluída.
* `timestamp`: data/hora em milissegundos desde 1970, fornecida pelo servidor (`ServerValue.timestamp`).

Métodos auxiliares:

* `fromMap(Map)`: converte um `Map` (como vem do RTDB) para um objeto `TodoItem`.
* `toMap()`: converte um `TodoItem` em `Map<String, dynamic>` para salvar no banco.

Esse padrão é chamado de **DTO (Data Transfer Object)**: permite converter dados crus em objetos tipados do Dart.

---

### TodoRepository (interface)

Um **contrato** que define as operações que qualquer repositório de TODOs deve oferecer, sem se preocupar com a tecnologia usada no backend.

* `Stream<List<TodoItem>> watchTodos(int limit)`: stream em tempo real da lista de tarefas.
* `Stream<bool> watchConnection()`: stream booleana que indica se há conexão com o RTDB.
* `Future<void> addTodo(String text)`: adiciona um novo TODO.
* `Future<void> toggleDone(TodoItem item)`: alterna o status concluído.
* `Future<void> remove(String key)`: remove um item pelo ID.
* `Future<void> clearAll()`: limpa toda a lista.

Essa interface garante **desacoplamento**: a UI só conhece o contrato, não a implementação.

---

### FirebaseTodoRepository (implementação)

Implementa `TodoRepository` usando `FirebaseDatabase`.

* **Campos:**

  * `FirebaseDatabase database`: instância do RTDB.
  * `int defaultLimit`: limite padrão de resultados.

* **Métodos públicos:**

  * `watchTodos(limit)`: observa o nó `/todos`, ordena por `timestamp`, limita, converte snapshots em `List<TodoItem>`.
  * `watchConnection()`: observa o nó especial `/.info/connected`.
  * `addTodo(text)`: cria um novo nó com `push().set({...})`.
  * `toggleDone(item)`: atualiza o campo `done` do item.
  * `remove(key)`: remove o nó `/todos/{key}`.
  * `clearAll()`: remove todos os nós em `/todos`.

Esse repositório é **state-less**: não guarda estado, apenas acessa e transforma dados.

---

### main.dart

#### Função `main()`

1. **`WidgetsFlutterBinding.ensureInitialized()`**
   Garante que o Flutter esteja pronto para chamadas assíncronas antes do `runApp`.

2. **`Firebase.initializeApp()`**
   Inicializa o Firebase com as opções geradas pela CLI (`firebase_options.dart`).

3. **`FirebaseDatabase.instanceFor(app, databaseURL: kRtdbUrl)`**
   Cria a instância explícita do RTDB (não editamos `firebase_options.dart`).

4. **Persistência Offline**
   Se não for Web, chama `setPersistenceEnabled(true)`.

5. **Injeção do repositório**
   `todosRepo = FirebaseTodoRepository(database: rtdb, defaultLimit: 100);`

6. **`runApp(RtdbDemoApp())`**
   Inicia a árvore de widgets.

---

### Widgets de UI

#### `RtdbDemoApp` (StatelessWidget)

* Raiz do app.
* Retorna `MaterialApp` com tema M3 e `TodoHomePage` como tela inicial.

---

#### `TodoHomePage` (StatefulWidget)

* Tela principal do app.
* Recebe um `TodoRepository` por injeção de dependência.

##### Estado (`_TodoHomePageState`)

* **Streams:**

  * `_todosStream`: stream da lista de tarefas.
  * `_connStream`: stream de conexão.
* **Subscrição:**

  * `_connSub`: guarda listener de `_connStream`.
  * `_connected`: bool usado no `_ConnectionBadge`.
* **Controladores:**

  * `_textCtrl`: controla o campo de texto.

##### Métodos

* `_addTodo()`: adiciona um novo item (chama repo).
* `_toggleDone(item)`: inverte status concluído.
* `_remove(item)`: exclui item pelo ID.
* `_clearAll()`: remove todos os itens.
* `_snack(msg)`: exibe `SnackBar`.

##### Build

* `AppBar`: título + `_ConnectionBadge` + botão “Limpar todos”.
* Corpo:

  * `_Composer` (campo + botão “Adicionar”).
  * `StreamBuilder<List<TodoItem>>`: exibe lista em tempo real.

    * Vazio → `_CenterMsg("Nenhum item")`.
    * Erro → `_CenterMsg("Erro")`.
    * Caso contrário → `ListView` com `Checkbox`, título, timestamp, botão excluir.
* `FloatingActionButton`: atalho para adicionar tarefa.

---

#### `_Composer` (StatelessWidget)

* Campo de texto + botão “Adicionar”.
* Usa `TextEditingController` para capturar entrada.
* Submete no Enter (`onSubmitted`) ou no clique do botão.

Mostra como encapsular pedaços da UI em widgets reaproveitáveis.

---

#### `_ConnectionBadge` (StatelessWidget)

* Recebe `bool connected`.
* Renderiza ícone + texto “online/off-line”.
* Demonstra uso simples de **props em widgets**.

---

#### `_CenterMsg` (StatelessWidget)

* Mostra uma mensagem centralizada (ex.: carregando, vazio, erro).
* Demonstra uso de estilos via `Theme.of(context)`.

---

## Regras de segurança do RTDB

**Para desenvolvimento (abertas):**

```json
{
  "rules": {
    ".read": true,
    ".write": true,
    ".indexOn": ["timestamp"]
  }
}
```

**Para produção:**

* Use autenticação (`auth != null`).
* Restringa acesso a `/todos/{uid}`.
* Valide formatos (texto obrigatório, timestamp válido, etc.).

---

## Boas práticas e observações

* **Repository Pattern**: separa a lógica de dados da UI.
* **Streams + StreamBuilder**: UI reativa em tempo real.
* **Persistência offline**: apenas fora da Web.
* **Erros**: tratados com SnackBars na UI.
* **Indexação**: `.indexOn` sempre que usar `orderByChild`.
* **Não editar `firebase_options.dart`**: mantenha sempre gerado pela CLI.
* **Uso didático**: `clearAll()` é útil aqui, mas perigoso em apps reais.

---