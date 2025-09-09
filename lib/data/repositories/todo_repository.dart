// lib/data/repositories/todo_repository.dart
//
// Contrato do repositório: a UI depende só desta interface.
// Facilita testes, mocks e troca de backend (RTDB, memória, etc.).

import '../../data/models/todo_item.dart';

abstract class TodoRepository {
  /// Stream em tempo real da lista (ordenada por timestamp ascendente).
  Stream<List<TodoItem>> watchTodos({int limit});

  /// Stream do estado de conexão (/.info/connected).
  Stream<bool> watchConnection();

  /// Cria novo TODO (texto obrigatório).
  Future<void> addTodo(String text);

  /// Alterna "done".
  Future<void> toggleDone(TodoItem item);

  /// Remove um TODO por chave.
  Future<void> remove(String key);

  /// Remove todos os TODOs.
  Future<void> clearAll();
}
