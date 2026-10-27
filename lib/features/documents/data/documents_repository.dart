import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import 'document_enums.dart';
import 'inventory_document.dart';
import 'stock_availability.dart';
import 'trade_document.dart';

class DocumentsRepository {
  DocumentsRepository(this._dio);

  final Dio _dio;

  Future<List<TradeSummary>> fetchTrades(
    TradeKind kind, {
    DocumentStatus? status,
  }) {
    return guarded(() async {
      final response = await _dio.get<List<dynamic>>(
        '/${kind.path}',
        queryParameters: {if (status != null) 'status': status.value},
      );
      return (response.data ?? const [])
          .map((item) => TradeSummary.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  Future<TradeDocument> fetchTrade(TradeKind kind, int id) {
    return guarded(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/${kind.path}/$id',
      );
      return TradeDocument.fromJson(response.data!);
    });
  }

  Future<TradeDocument> createTrade(TradeKind kind, TradeInput input) {
    return guarded(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/${kind.path}',
        data: input.toJson(),
      );
      return TradeDocument.fromJson(response.data!);
    });
  }

  Future<TradeDocument> replaceTrade(
    TradeKind kind,
    int id,
    TradeInput input,
  ) {
    return guarded(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/${kind.path}/$id',
        data: input.toJson(),
      );
      return TradeDocument.fromJson(response.data!);
    });
  }

  Future<void> deleteTrade(TradeKind kind, int id) {
    return guarded(() => _dio.delete<dynamic>('/${kind.path}/$id'));
  }

  Future<TradeDocument> postTrade(TradeKind kind, int id) {
    return guarded(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/${kind.path}/$id/post',
      );
      return TradeDocument.fromJson(response.data!);
    });
  }

  Future<List<InventorySummary>> fetchInventories({DocumentStatus? status}) {
    return guarded(() async {
      final response = await _dio.get<List<dynamic>>(
        '/inventories',
        queryParameters: {if (status != null) 'status': status.value},
      );
      return (response.data ?? const [])
          .map(
            (item) => InventorySummary.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    });
  }

  Future<InventoryDocument> fetchInventory(int id) {
    return guarded(() async {
      final response = await _dio.get<Map<String, dynamic>>('/inventories/$id');
      return InventoryDocument.fromJson(response.data!);
    });
  }

  Future<InventoryDocument> createInventory(InventoryInput input) {
    return guarded(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/inventories',
        data: input.toJson(),
      );
      return InventoryDocument.fromJson(response.data!);
    });
  }

  Future<InventoryDocument> replaceInventory(int id, InventoryInput input) {
    return guarded(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/inventories/$id',
        data: input.toJson(),
      );
      return InventoryDocument.fromJson(response.data!);
    });
  }

  Future<void> deleteInventory(int id) {
    return guarded(() => _dio.delete<dynamic>('/inventories/$id'));
  }

  Future<InventoryDocument> postInventory(int id) {
    return guarded(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/inventories/$id/post',
      );
      return InventoryDocument.fromJson(response.data!);
    });
  }

  Future<StockAvailability> fetchStockAvailability() {
    return guarded(() async {
      final response = await _dio.get<Map<String, dynamic>>('/reports/stock');
      return StockAvailability.fromJson(response.data!);
    });
  }
}
