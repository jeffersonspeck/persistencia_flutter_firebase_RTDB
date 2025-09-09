// lib/data/models/todo_item.dart
//
// Modelo imutável do TODO (Domain Model) com:
// - fromMap / toMap (serialização segura)
// - copyWith (imutabilidade com ergonomia)
// - fromSnapshot (helper para RTDB, robusto a tipos dinâmicos)

import 'package:firebase_database/firebase_database.dart';

class TodoItem {
  final String key;        // pushId
  final String text;       // conteúdo
  final bool done;         // concluído
  final int? timestamp;    // epoch ms (pode ser null até o servidor resolver)

  const TodoItem({
    required this.key,
    required this.text,
    required this.done,
    required this.timestamp,
  });

  /// Cria a partir de um DataSnapshot (RTDB). Robusto a tipos dinâmicos.
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

  /// Cria a partir de um Map comum (útil para testes / mocks).
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

  /// Converte para Map de domínio (sem ServerValue).
  Map<String, Object?> toMap() => {
        'text': text,
        'done': done,
        'timestamp': timestamp,
      };

  /// Imutabilidade com praticidade.
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
}
