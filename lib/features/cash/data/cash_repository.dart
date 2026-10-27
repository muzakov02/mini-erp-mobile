import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/json_helpers.dart';
import 'cash_models.dart';

class CashRepository {
  CashRepository(this._dio);

  final Dio _dio;

  Future<Decimal> fetchBalance() {
    return guarded(() async {
      final response = await _dio.get<Map<String, dynamic>>('/cash/balance');
      return jsonDecimal(response.data!['balance']);
    });
  }

  Future<List<CashCategoryMeta>> fetchCategories() {
    return guarded(() async {
      final response = await _dio.get<List<dynamic>>('/cash/categories');
      return (response.data ?? const [])
          .map((item) => CashCategoryMeta.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  Future<List<CashOperation>> fetchOperations({String? category}) {
    return guarded(() async {
      final response = await _dio.get<List<dynamic>>(
        '/cash/operations',
        queryParameters: {'category': ?category},
      );
      return (response.data ?? const [])
          .map((item) => CashOperation.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> create(CashInput input) {
    return guarded(
      () => _dio.post<dynamic>('/cash/operations', data: input.toJson()),
    );
  }
}
