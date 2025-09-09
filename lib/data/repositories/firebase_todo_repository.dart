// lib/data/repositories/firebase_todo_repository.dart
//
// Implementação do repositório usando Firebase Realtime Database.
// Isola a dependência do Firebase da UI (Repository Pattern).

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_database/firebase_database.dart';

import '../models/todo_item.dart';
import 'todo_repository.dart';

class FirebaseTodoRepository implements TodoRepository {
  final FirebaseDatabase _db;
  final DatabaseReference _todosRef;
  final DatabaseReference _connectedRef;

  FirebaseTodoRepository({
    required FirebaseDatabase database,
    int defaultLimit = 100,
  })  : _db = database,
        _todosRef = database.ref('todos'),
        _connectedRef = database.ref('.info/connected') {
    // Mantém /todos sincronizado (Web não precisa / pode não suportar)
    if (!kIsWeb) {
      try {
        _todosRef.keepSynced(true);
      } catch (_) {}
    }
  }

  @override
  Stream<List<TodoItem>> watchTodos({int limit = 100}) {
    final q = _db.ref('todos').orderByChild('timestamp').limitToLast(limit);
    return q.onValue.map((event) {
      final root = event.snapshot;
      final items = <TodoItem>[
        for (final child in root.children) TodoItem.fromSnapshot(child),
      ];
      // Ordena ascendente por timestamp
      items.sort((a, b) => (a.timestamp ?? 0).compareTo(b.timestamp ?? 0));
      return items;
    });
  }

  @override
  Stream<bool> watchConnection() =>
      _connectedRef.onValue.map((e) => e.snapshot.value == true);

  @override
  Future<void> addTodo(String text) async {
    final newRef = _todosRef.push();
    await newRef.set({
      'text': text,
      'done': false,
      'timestamp': ServerValue.timestamp, // resolvido no servidor
    });
  }

  @override
  Future<void> toggleDone(TodoItem item) =>
      _todosRef.child(item.key).update({'done': !item.done});

  @override
  Future<void> remove(String key) => _todosRef.child(key).remove();

  @override
  Future<void> clearAll() => _todosRef.remove();
}
