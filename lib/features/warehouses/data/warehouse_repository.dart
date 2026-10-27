import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import 'warehouse.dart';

class WarehouseRepository {
  WarehouseRepository(this._dio);

  final Dio _dio;

  Future<List<Warehouse>> fetchTree() {
    return guarded(() async {
      final response = await _dio.get<List<dynamic>>('/warehouses');
      return (response.data ?? const [])
          .map((item) => Warehouse.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> create(String name, {int? parentId}) {
    return guarded(
      () => _dio.post<dynamic>(
        '/warehouses',
        data: {'name': name, 'parentId': ?parentId},
      ),
    );
  }

  Future<void> rename(int id, String name) {
    return guarded(
      () => _dio.patch<dynamic>('/warehouses/$id', data: {'name': name}),
    );
  }

  Future<void> archive(int id) {
    return guarded(() => _dio.post<dynamic>('/warehouses/$id/archive'));
  }
}
