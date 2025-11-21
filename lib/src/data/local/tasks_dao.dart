import 'package:sqflite/sqflite.dart';

import '../../models/task_model.dart';
import 'db_helper.dart';

class TasksDao {
  final dbHelper = DBHelper.instance;

  Future<List<TaskModel>> getAll() async {
    final db = await dbHelper.database;
    final rows = await db.query(
      'tasks',
      where: 'deleted = 0',
      orderBy: 'updated_at DESC',
    );
    return rows.map(TaskModel.fromMap).toList();
  }

  Future<TaskModel?> getById(String id) async {
    final db = await dbHelper.database;
    final rows = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return TaskModel.fromMap(rows.first);
  }

  Future<void> upsert(TaskModel task) async {
    final db = await dbHelper.database;
    await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertBulk(List<TaskModel> tasks) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    for (final task in tasks) {
      batch.insert(
        'tasks',
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> markDeleted(String id, DateTime updatedAt) async {
    final db = await dbHelper.database;
    await db.update(
      'tasks',
      {
        'deleted': 1,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
