// lib/main.dart
//
// App demo de Firebase Realtime Database em Flutter (Repository Pattern).
// NÃO altera o firebase_options.dart. Em vez disso, forçamos o databaseURL
// criando uma instância explícita do RTDB com `FirebaseDatabase.instanceFor(...)`.
//
// Recursos do app:
// - Inicializa Firebase (via FlutterFire) e instancia RTDB com URL explícita
// - TODOs em /todos/{pushId} com push(), leitura em tempo real (Stream)
// - Badge de conexão (.info/connected)
// - Persistência offline somente onde é suportado (não Web)
// - Comentários explicando cada parte
//
// Regras (apenas para DEV):
// {
//   "rules": { ".read": true, ".write": true, ".indexOn": ["timestamp"] }
// }
// Em produção: use Authentication + regras restritivas.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'firebase_options.dart'; // gere com: flutterfire configure
import 'config/database_config.dart' as conf;
import 'data/models/todo_item.dart';
import 'data/repositories/todo_repository.dart';
import 'data/repositories/firebase_todo_repository.dart';

late final FirebaseDatabase rtdb;
late final TodoRepository todosRepo;

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

class RtdbDemoApp extends StatelessWidget {
  const RtdbDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase RTDB Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: TodoHomePage(repo: todosRepo),
    );
  }
}

class TodoHomePage extends StatefulWidget {
  final TodoRepository repo;
  const TodoHomePage({super.key, required this.repo});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  final _textCtrl = TextEditingController();

  late final Stream<List<TodoItem>> _todosStream;
  late final Stream<bool> _connStream;

  StreamSubscription<bool>? _connSub;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _todosStream = widget.repo.watchTodos(limit: 100);
    _connStream = widget.repo.watchConnection();
    _connSub = _connStream.listen((ok) {
      if (mounted) setState(() => _connected = ok);
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _connSub?.cancel();
    super.dispose();
  }

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

  Future<void> _toggleDone(TodoItem item) async {
    try {
      await widget.repo.toggleDone(item);
    } catch (e) {
      _snack('Falha ao atualizar: $e');
    }
  }

  Future<void> _remove(TodoItem item) async {
    try {
      await widget.repo.remove(item.key);
    } catch (e) {
      _snack('Falha ao remover: $e');
    }
  }

  Future<void> _clearAll() async {
    try {
      await widget.repo.clearAll();
    } catch (e) {
      _snack('Falha ao limpar: $e');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

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
}

/// Campo de entrada + botão "Adicionar"
class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final Future<void> Function() onSubmit;

  const _Composer({required this.controller, required this.onSubmit});

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
}

/// Badge simples de conexão (online/offline) com o RTDB
class _ConnectionBadge extends StatelessWidget {
  final bool connected;
  const _ConnectionBadge({required this.connected});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(connected ? Icons.wifi : Icons.wifi_off, size: 18),
      const SizedBox(width: 4),
      Text(connected ? 'online' : 'off-line'),
    ]);
  }
}

class _CenterMsg extends StatelessWidget {
  final String msg;
  const _CenterMsg(this.msg);

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
}
