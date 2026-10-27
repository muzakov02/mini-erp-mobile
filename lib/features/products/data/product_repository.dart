import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import 'product.dart';

class ProductRepository {
  ProductRepository(this._dio);

  final Dio _dio;

  Future<List<Product>> fetchAll() {
    return guarded(() async {
      final response = await _dio.get<List<dynamic>>('/products');
      return (response.data ?? const [])
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> create(ProductInput input) {
    return guarded(() => _dio.post<dynamic>('/products', data: input.toJson()));
  }

  Future<void> update(int id, ProductInput input) {
    return guarded(
      () => _dio.patch<dynamic>('/products/$id', data: input.toJson()),
    );
  }

  Future<void> archive(int id) {
    return guarded(() => _dio.post<dynamic>('/products/$id/archive'));
  }
}
