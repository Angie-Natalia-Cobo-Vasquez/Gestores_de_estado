import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio;

  ApiClient(String baseUrl)
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(milliseconds: 5000),
            receiveTimeout: const Duration(milliseconds: 5000),
          ),
        );

  Dio get client => _dio;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) =>
      _dio.get(path, queryParameters: query);

  Future<Response<dynamic>> post(
    String path,
    dynamic data, {
    Map<String, String>? headers,
  }) =>
      _dio.post(path, data: data, options: Options(headers: headers));

  Future<Response<dynamic>> put(
    String path,
    dynamic data, {
    Map<String, String>? headers,
  }) =>
      _dio.put(path, data: data, options: Options(headers: headers));

  Future<Response<dynamic>> delete(
    String path, {
    Map<String, String>? headers,
  }) =>
      _dio.delete(path, options: Options(headers: headers));
}
