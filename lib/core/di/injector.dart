import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../features/cash/data/cash_repository.dart';
import '../../features/cash/presentation/cash_cubit.dart';
import '../../features/cash/presentation/counterparty_balance_cubit.dart';
import '../../features/reports/data/reports_repository.dart';
import '../../features/reports/presentation/reports_cubit.dart';
import '../../features/reports/presentation/sales_report_cubit.dart';
import '../../features/reports/presentation/stock_report_cubit.dart';
import '../../features/counterparties/data/counterparty_repository.dart';
import '../../features/counterparties/presentation/counterparties_cubit.dart';
import '../../features/counterparties/presentation/counterparty_detail_cubit.dart';
import '../../features/documents/data/documents_repository.dart';
import '../../features/documents/presentation/documents_cubit.dart';
import '../../features/documents/presentation/inventory_form_cubit.dart';
import '../../features/products/data/product_repository.dart';
import '../../features/products/presentation/products_cubit.dart';
import '../../features/warehouses/data/warehouse_repository.dart';
import '../../features/warehouses/presentation/warehouses_cubit.dart';
import '../network/dio_client.dart';

final GetIt getIt = GetIt.instance;

void setupDependencies() {
  getIt
    ..registerLazySingleton<Dio>(createDio)
    ..registerLazySingleton(() => ProductRepository(getIt()))
    ..registerLazySingleton(() => WarehouseRepository(getIt()))
    ..registerLazySingleton(() => CounterpartyRepository(getIt()))
    ..registerLazySingleton(() => CashRepository(getIt()))
    ..registerLazySingleton(() => ReportsRepository(getIt()))
    ..registerFactory(() => CashCubit(getIt()))
    ..registerFactory(() => CounterpartyBalanceCubit(getIt()))
    ..registerFactory(() => ReportsCubit(getIt()))
    ..registerFactory(() => SalesReportCubit(getIt()))
    ..registerFactory(() => StockReportCubit(getIt()))
    ..registerLazySingleton(() => DocumentsRepository(getIt()))
    ..registerFactory(() => DocumentsCubit(getIt()))
    ..registerFactory(() => InventoryFormCubit(getIt()))
    ..registerFactory(() => ProductsCubit(getIt()))
    ..registerFactory(() => WarehousesCubit(getIt()))
    ..registerFactory(() => CounterpartiesCubit(getIt()))
    ..registerFactory(() => CounterpartyDetailCubit(getIt()));
}
