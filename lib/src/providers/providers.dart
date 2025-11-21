import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/queue_dao.dart';
import '../data/local/tasks_dao.dart';
import '../data/remote/api_client.dart';
import '../data/remote/tasks_api.dart';
import '../data/repositories/tasks_repository_impl.dart';
import '../domain/repositories/tasks_repository.dart';
import '../models/task_model.dart';
import '../services/sync_service.dart';

enum TaskFilter { all, pending, completed }

extension TaskFilterX on TaskFilter {
  String get label {
    switch (this) {
      case TaskFilter.all:
        return 'Todas';
      case TaskFilter.pending:
        return 'Pendientes';
      case TaskFilter.completed:
        return 'Completadas';
    }
  }
}

final apiBaseProvider = Provider<String>((ref) => 'http://localhost:3000');

final apiClientProvider = Provider<ApiClient>((ref) {
  final baseUrl = ref.watch(apiBaseProvider);
  return ApiClient(baseUrl);
});

final tasksApiProvider = Provider<TasksApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return TasksApi(client);
});

final tasksDaoProvider = Provider<TasksDao>((ref) => TasksDao());
final queueDaoProvider = Provider<QueueDao>((ref) => QueueDao());

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return TasksRepositoryImpl(
    tasksDao: ref.watch(tasksDaoProvider),
    queueDao: ref.watch(queueDaoProvider),
    tasksApi: ref.watch(tasksApiProvider),
  );
});

final tasksListProvider = FutureProvider<List<TaskModel>>((ref) async {
  final repository = ref.watch(tasksRepositoryProvider);
  return repository.getAllLocal();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    queueDao: ref.watch(queueDaoProvider),
    tasksDao: ref.watch(tasksDaoProvider),
    tasksApi: ref.watch(tasksApiProvider),
  );
  service.startConnectivityListener();
  ref.onDispose(service.dispose);
  return service;
});

final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);
