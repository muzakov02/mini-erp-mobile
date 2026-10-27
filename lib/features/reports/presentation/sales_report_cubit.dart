import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/state/list_state.dart';
import '../../../core/state/load_state.dart';
import '../data/report_models.dart';
import '../data/reports_repository.dart';

class SalesReportCubit extends Cubit<LoadState<SalesReport>> {
  SalesReportCubit(this._repository) : super(const LoadState());

  final ReportsRepository _repository;

  Future<void> load({String? from, String? to}) async {
    if (state.data == null) {
      emit(const LoadState());
    }
    try {
      final report = await _repository.fetchSales(from: from, to: to);
      if (isClosed) return;
      emit(LoadState(status: LoadStatus.success, data: report));
    } on AppFailure catch (failure) {
      if (isClosed) return;
      emit(
        LoadState(
          status: LoadStatus.failure,
          data: state.data,
          failure: failure,
        ),
      );
    }
  }
}
