import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/state/list_state.dart';
import '../../../core/state/load_state.dart';
import '../data/report_models.dart';
import '../data/report_period.dart';
import '../data/reports_repository.dart';

class ReportsState extends Equatable {
  const ReportsState({
    this.period = const ReportPeriod(),
    this.pnl = const LoadState(),
  });

  final ReportPeriod period;
  final LoadState<PnlReport> pnl;

  @override
  List<Object?> get props => [period, pnl];
}

class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit(this._repository) : super(const ReportsState());

  final ReportsRepository _repository;
  int _token = 0;

  void selectPeriod(ReportPeriod period) {
    emit(ReportsState(period: period));
    load();
  }

  Future<void> load() async {
    final token = ++_token;
    final period = state.period;
    if (state.pnl.data == null) {
      emit(ReportsState(period: period));
    }
    try {
      final pnl = await _repository.fetchPnl(
        from: period.queryFrom,
        to: period.queryTo,
      );
      if (isClosed || token != _token) return;
      emit(
        ReportsState(
          period: period,
          pnl: LoadState(status: LoadStatus.success, data: pnl),
        ),
      );
    } on AppFailure catch (failure) {
      if (isClosed || token != _token) return;
      emit(
        ReportsState(
          period: period,
          pnl: LoadState(
            status: LoadStatus.failure,
            data: state.pnl.data,
            failure: failure,
          ),
        ),
      );
    }
  }
}
