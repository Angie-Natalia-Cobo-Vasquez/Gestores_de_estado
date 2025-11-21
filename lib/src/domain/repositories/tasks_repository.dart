import '../../models/task_model.dart';

abstract class TasksRepository {
  Future<List<TaskModel>> getAllLocal();
  Future<void> createLocal(TaskModel task);
  Future<void> updateLocal(TaskModel task);
  Future<void> deleteLocal(String id, DateTime updatedAt);

  Future<List<TaskModel>> fetchRemoteAll();
  Future<TaskModel> createRemote(TaskModel task, {String? idempotencyKey});
  Future<TaskModel> updateRemote(TaskModel task, {String? idempotencyKey});
  Future<void> deleteRemote(String id, {String? idempotencyKey});
}
