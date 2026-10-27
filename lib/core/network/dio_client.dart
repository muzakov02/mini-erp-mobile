import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../errors/app_failure.dart';

Dio createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(_FailureInterceptor());
  return dio;
}

class _FailureInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err.copyWith(error: AppFailure.fromDioException(err)));
  }
}

Future<T> guarded<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (exception) {
    final error = exception.error;
    throw error is AppFailure ? error : AppFailure.fromDioException(exception);
  } on AppFailure {
    rethrow;
  } catch (_) {
    throw const AppFailure.unknown();
  }
}
