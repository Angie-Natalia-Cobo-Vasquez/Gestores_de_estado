import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

import '../data/local/queue_dao.dart';
import '../data/local/tasks_dao.dart';
import '../data/remote/tasks_api.dart';
import '../models/task_model.dart';

class SyncService {
  final QueueDao queueDao;
  final TasksDao tasksDao;
  final TasksApi tasksApi;
  final uuid = const Uuid();

  bool _running = false;
  StreamSubscription<ConnectivityResult>? _connectivitySub;

  SyncService({
    required this.queueDao,
    required this.tasksDao,
    required this.tasksApi,
  });

  void startConnectivityListener() {
    _connectivitySub ??=
        Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        trySync();
      }
    });
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  Future<void> trySync() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;
    if (_running) return;

    _running = true;
    try {
      final pending = await queueDao.getPendingOperations();
      for (final op in pending) {
        await _processOp(op);
      }

      final remoteItems = await tasksApi.fetchAll();
      for (final item in remoteItems) {
        final remoteUpdated = DateTime.parse(
          item['updatedAt'] ?? item['updated_at'] as String,
        );
        final id = item['id'] as String;
        final local = await tasksDao.getById(id);
        final remoteDeleted = item['deleted'] == true || item['deleted'] == 1;
        if (local == null || remoteUpdated.isAfter(local.updatedAt)) {
          final model = TaskModel(
            id: id,
            title: item['title'] as String,
            completed: item['completed'] == true || item['completed'] == 1,
            updatedAt: remoteUpdated,
            deleted: remoteDeleted,
          );
          await tasksDao.upsert(model);
        }
      }
    } finally {
      _running = false;
    }
  }

  Future<void> _processOp(QueueOperation op) async {
    var attempts = op.attemptCount;

    try {
      switch (op.op) {
        case 'CREATE':
          final payload = TaskModel.fromJson(op.payload);
          await tasksApi.create(
            {
              'id': payload.id,
              'title': payload.title,
              'completed': payload.completed,
              'updatedAt': payload.updatedAt.toUtc().toIso8601String(),
            },
            idempotencyKey: op.id,
          );
          await queueDao.markSynced(op.id, syncedAt: DateTime.now().toUtc());
          break;
        case 'UPDATE':
          final payload = TaskModel.fromJson(op.payload);
          await tasksApi.update(
            payload.id,
            {
              'title': payload.title,
              'completed': payload.completed,
              'updatedAt': payload.updatedAt.toUtc().toIso8601String(),
            },
            idempotencyKey: op.id,
          );
          await queueDao.markSynced(op.id, syncedAt: DateTime.now().toUtc());
          break;
        case 'DELETE':
          final data = json.decode(op.payload) as Map<String, dynamic>;
          await tasksApi.deleteTask(data['id'] as String, idempotencyKey: op.id);
          await queueDao.markSynced(op.id, syncedAt: DateTime.now().toUtc());
          break;
      }
    } catch (error) {
      attempts += 1;
      await queueDao.updateAttempt(op.id, attempts, error.toString());
      final delay = _backoffDelay(attempts);
      await Future.delayed(Duration(milliseconds: delay));
    }
  }

  int _backoffDelay(int attempts) {
    const base = 1000;
    final expo = min(300000, base * pow(2, attempts).toInt());
    final jitter = Random().nextInt(500);
    return expo + jitter;
  }
}
