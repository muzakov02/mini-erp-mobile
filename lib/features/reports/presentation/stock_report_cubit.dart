import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/state/list_state.dart';
import '../../../core/state/load_state.dart';
import '../data/report_models.dart';
import '../data/reports_repository.dart';

class StockReportState extends Equatable {
  const StockReportState({this.warehouseId, this.report = const LoadState()});

  final int? warehouseId;
  final LoadState<StockReport> report;

  @override
  List<Object?> get props => [warehouseId, report];
}

class StockReportCubit extends Cubit<StockReportState> {
  StockReportCubit(this._repository) : super(const StockReportState());

  final ReportsRepository _repository;
  int _token = 0;

  void selectWarehouse(int? warehouseId) {
    if (warehouseId == state.warehouseId) return;
    emit(StockReportState(warehouseId: warehouseId));
    load();
  }

  Future<void> load() async {
    final token = ++_token;
    final warehouseId = state.warehouseId;
    if (state.report.data == null) {
      emit(StockReportState(warehouseId: warehouseId));
    }
    try {
      final report = await _repository.fetchStock(warehouseId: warehouseId);
      if (isClosed || token != _token) return;
      emit(
        StockReportState(
          warehouseId: warehouseId,
          report: LoadState(status: LoadStatus.success, data: report),
        ),
      );
    } on AppFailure catch (failure) {
      if (isClosed || token != _token) return;
      emit(
        StockReportState(
          warehouseId: warehouseId,
          report: LoadState(
            status: LoadStatus.failure,
            data: state.report.data,
            failure: failure,
          ),
        ),
      );
    }
  }
}
