import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../domain/repositories/tasks_repository.dart';
import '../../models/task_model.dart';
import '../local/queue_dao.dart';
import '../local/tasks_dao.dart';
import '../remote/tasks_api.dart';

class TasksRepositoryImpl implements TasksRepository {
  final TasksDao tasksDao;
  final QueueDao queueDao;
  final TasksApi tasksApi;
  final uuid = const Uuid();

  TasksRepositoryImpl({
    required this.tasksDao,
    required this.queueDao,
    required this.tasksApi,
  });

  @override
  Future<List<TaskModel>> getAllLocal() => tasksDao.getAll();

  @override
  Future<void> createLocal(TaskModel task) async {
    await tasksDao.upsert(task);
    final op = QueueOperation(
      id: uuid.v4(),
      entity: 'task',
      entityId: task.id,
      op: 'CREATE',
      payload: task.toJson(),
      createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
    );
    await queueDao.addOperation(op);
  }

  @override
  Future<void> updateLocal(TaskModel task) async {
    await tasksDao.upsert(task);
    final op = QueueOperation(
      id: uuid.v4(),
      entity: 'task',
      entityId: task.id,
      op: 'UPDATE',
      payload: task.toJson(),
      createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
    );
    await queueDao.addOperation(op);
  }

  @override
  Future<void> deleteLocal(String id, DateTime updatedAt) async {
    await tasksDao.markDeleted(id, updatedAt);
    final op = QueueOperation(
      id: uuid.v4(),
      entity: 'task',
      entityId: id,
      op: 'DELETE',
      payload: json.encode({'id': id}),
      createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
    );
    await queueDao.addOperation(op);
  }

  bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  String _readUpdatedAt(Map<String, dynamic> item) {
    return (item['updatedAt'] ?? item['updated_at']) as String;
  }

  @override
  Future<List<TaskModel>> fetchRemoteAll() async {
    final list = await tasksApi.fetchAll();
    return list.map((item) {
      return TaskModel(
        id: item['id'] as String,
        title: item['title'] as String,
        completed: _parseBool(item['completed']),
        updatedAt: DateTime.parse(_readUpdatedAt(item as Map<String, dynamic>)),
        deleted: _parseBool(item['deleted']),
      );
    }).toList();
  }

  @override
  Future<TaskModel> createRemote(TaskModel task, {String? idempotencyKey}) async {
    final response = await tasksApi.create(
      {
        'id': task.id,
        'title': task.title,
        'completed': task.completed,
        'updatedAt': task.updatedAt.toUtc().toIso8601String(),
      },
      idempotencyKey: idempotencyKey,
    );

    return TaskModel(
      id: response['id'] as String,
      title: response['title'] as String,
      completed: _parseBool(response['completed']),
      updatedAt: DateTime.parse(_readUpdatedAt(response)),
    );
  }

  @override
  Future<TaskModel> updateRemote(TaskModel task, {String? idempotencyKey}) async {
    final response = await tasksApi.update(
      task.id,
      {
        'title': task.title,
        'completed': task.completed,
        'updatedAt': task.updatedAt.toUtc().toIso8601String(),
      },
      idempotencyKey: idempotencyKey,
    );

    return TaskModel(
      id: response['id'] as String,
      title: response['title'] as String,
      completed: _parseBool(response['completed']),
      updatedAt: DateTime.parse(_readUpdatedAt(response)),
    );
  }

  @override
  Future<void> deleteRemote(String id, {String? idempotencyKey}) async {
    await tasksApi.deleteTask(id, idempotencyKey: idempotencyKey);
  }
}
