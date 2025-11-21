import 'package:dio/dio.dart';

import 'api_client.dart';

class TasksApi {
  final ApiClient client;

  TasksApi(this.client);

  Future<List<dynamic>> fetchAll() async {
    final Response<dynamic> response = await client.get('/tasks');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> create(
    Map<String, dynamic> body, {
    String? idempotencyKey,
  }) async {
    final headers = idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null;
    final Response<dynamic> response = await client.post('/tasks', body, headers: headers);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> body, {
    String? idempotencyKey,
  }) async {
    final headers = idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null;
    final Response<dynamic> response = await client.put('/tasks/$id', body, headers: headers);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteTask(
    String id, {
    String? idempotencyKey,
  }) async {
    final headers = idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null;
    await client.delete('/tasks/$id', headers: headers);
  }
}
