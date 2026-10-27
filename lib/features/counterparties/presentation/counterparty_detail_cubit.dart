import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/state/list_state.dart';
import '../data/counterparty.dart';
import '../data/counterparty_entry.dart';
import '../data/counterparty_repository.dart';

class CounterpartyDetailState extends Equatable {
  const CounterpartyDetailState({
    this.status = LoadStatus.loading,
    this.counterparty,
    this.entries = const [],
    this.failure,
  });

  final LoadStatus status;
  final Counterparty? counterparty;
  final List<CounterpartyEntry> entries;
  final AppFailure? failure;

  @override
  List<Object?> get props => [status, counterparty, entries, failure];
}

class CounterpartyDetailCubit extends Cubit<CounterpartyDetailState> {
  CounterpartyDetailCubit(this._repository)
    : super(const CounterpartyDetailState());

  final CounterpartyRepository _repository;

  Future<void> load(int id) async {
    if (state.counterparty == null) {
      emit(const CounterpartyDetailState());
    }
    try {
      final results = await Future.wait([
        _repository.fetchOne(id),
        _repository.fetchEntries(id),
      ]);
      if (isClosed) return;
      emit(
        CounterpartyDetailState(
          status: LoadStatus.success,
          counterparty: results[0] as Counterparty,
          entries: results[1] as List<CounterpartyEntry>,
        ),
      );
    } on AppFailure catch (failure) {
      if (isClosed) return;
      emit(
        CounterpartyDetailState(
          status: LoadStatus.failure,
          counterparty: state.counterparty,
          entries: state.entries,
          failure: failure,
        ),
      );
    }
  }
}
