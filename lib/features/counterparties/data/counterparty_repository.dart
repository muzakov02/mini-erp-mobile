import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import 'counterparty.dart';
import 'counterparty_entry.dart';

class CounterpartyRepository {
  CounterpartyRepository(this._dio);

  final Dio _dio;

  Future<List<Counterparty>> fetchAll() {
    return guarded(() async {
      final response = await _dio.get<List<dynamic>>('/counterparties');
      return (response.data ?? const [])
          .map((item) => Counterparty.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  Future<Counterparty> fetchOne(int id) {
    return guarded(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/counterparties/$id',
      );
      return Counterparty.fromJson(response.data!);
    });
  }

  Future<List<CounterpartyEntry>> fetchEntries(int id) {
    return guarded(() async {
      final response = await _dio.get<List<dynamic>>(
        '/counterparties/$id/entries',
      );
      return (response.data ?? const [])
          .map(
            (item) => CounterpartyEntry.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    });
  }

  Future<void> create(CounterpartyInput input) {
    return guarded(
      () => _dio.post<dynamic>('/counterparties', data: input.toCreateJson()),
    );
  }

  Future<void> update(int id, CounterpartyInput input) {
    return guarded(
      () => _dio.patch<dynamic>(
        '/counterparties/$id',
        data: input.toUpdateJson(),
      ),
    );
  }

  Future<void> archive(int id) {
    return guarded(() => _dio.post<dynamic>('/counterparties/$id/archive'));
  }
}
