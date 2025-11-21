import 'package:sqflite/sqflite.dart';

import 'db_helper.dart';

class QueueOperation {
  final String id;
  final String entity;
  final String entityId;
  final String op;
  final String payload;
  final int createdAt;
  final int attemptCount;
  final String? lastError;
  final int? syncedAt;

  QueueOperation({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.op,
    required this.payload,
    required this.createdAt,
    this.attemptCount = 0,
    this.lastError,
    this.syncedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'entity': entity,
        'entity_id': entityId,
        'op': op,
        'payload': payload,
        'created_at': createdAt,
        'attempt_count': attemptCount,
        'last_error': lastError,
        'synced_at': syncedAt,
      };

  factory QueueOperation.fromMap(Map<String, dynamic> map) => QueueOperation(
        id: map['id'] as String,
        entity: map['entity'] as String,
        entityId: map['entity_id'] as String,
        op: map['op'] as String,
        payload: map['payload'] as String,
        createdAt: map['created_at'] as int,
        attemptCount: map['attempt_count'] as int? ?? 0,
        lastError: map['last_error'] as String?,
        syncedAt: map['synced_at'] as int?,
      );
}

class QueueDao {
  final dbHelper = DBHelper.instance;

  Future<void> addOperation(QueueOperation op) async {
    final db = await dbHelper.database;
    await db.insert('queue_operations', op.toMap());
  }

  Future<List<QueueOperation>> getPendingOperations({int limit = 50}) async {
    final db = await dbHelper.database;
    final rows = await db.query(
      'queue_operations',
      where: 'synced_at IS NULL',
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return rows.map(QueueOperation.fromMap).toList();
  }

  Future<void> deleteOperation(String id) async {
    final db = await dbHelper.database;
    await db.delete('queue_operations', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateAttempt(String id, int attempts, String? lastError) async {
    final db = await dbHelper.database;
    await db.update(
      'queue_operations',
      {
        'attempt_count': attempts,
        'last_error': lastError,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markSynced(String id, {required DateTime syncedAt}) async {
    final db = await dbHelper.database;
    await db.update(
      'queue_operations',
      {
        'synced_at': syncedAt.millisecondsSinceEpoch,
        'last_error': null,
        'attempt_count': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
