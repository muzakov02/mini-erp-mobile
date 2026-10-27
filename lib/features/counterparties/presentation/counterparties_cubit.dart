import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/state/list_state.dart';
import '../data/counterparty.dart';
import '../data/counterparty_repository.dart';

class CounterpartiesCubit extends Cubit<ListState<Counterparty>> {
  CounterpartiesCubit(this._repository) : super(const ListState());

  final CounterpartyRepository _repository;

  Future<void> load() async {
    if (state.items.isEmpty) {
      emit(const ListState());
    }
    try {
      final items = await _repository.fetchAll();
      if (isClosed) return;
      emit(ListState(status: LoadStatus.success, items: items));
    } on AppFailure catch (failure) {
      if (isClosed) return;
      emit(
        ListState(
          status: LoadStatus.failure,
          items: state.items,
          failure: failure,
        ),
      );
    }
  }

  Future<AppFailure?> save(CounterpartyInput input, {int? id}) {
    return _mutate(
      () => id == null
          ? _repository.create(input)
          : _repository.update(id, input),
    );
  }

  Future<AppFailure?> archive(int id) => _mutate(() => _repository.archive(id));

  Future<AppFailure?> _mutate(Future<void> Function() action) async {
    try {
      await action();
    } on AppFailure catch (failure) {
      return failure;
    }
    await load();
    return null;
  }
}
