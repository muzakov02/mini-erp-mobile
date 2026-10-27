import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import 'report_models.dart';

class ReportsRepository {
  ReportsRepository(this._dio);

  final Dio _dio;

  Future<PnlReport> fetchPnl({String? from, String? to}) {
    return guarded(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/reports/pnl',
        queryParameters: {'from': ?from, 'to': ?to},
      );
      return PnlReport.fromJson(response.data!);
    });
  }

  Future<SalesReport> fetchSales({String? from, String? to}) {
    return guarded(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/reports/sales',
        queryParameters: {'from': ?from, 'to': ?to},
      );
      return SalesReport.fromJson(response.data!);
    });
  }

  Future<StockReport> fetchStock({int? warehouseId}) {
    return guarded(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/reports/stock',
        queryParameters: {'warehouseId': ?warehouseId},
      );
      return StockReport.fromJson(response.data!);
    });
  }
}
