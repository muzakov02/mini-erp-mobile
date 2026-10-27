import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/state/list_state.dart';
import '../data/warehouse.dart';
import '../data/warehouse_repository.dart';

class WarehousesCubit extends Cubit<ListState<Warehouse>> {
  WarehousesCubit(this._repository) : super(const ListState());

  final WarehouseRepository _repository;

  Future<void> load() async {
    if (state.items.isEmpty) {
      emit(const ListState());
    }
    try {
      final items = await _repository.fetchTree();
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

  Future<AppFailure?> create(String name, {int? parentId}) {
    return _mutate(() => _repository.create(name, parentId: parentId));
  }

  Future<AppFailure?> rename(int id, String name) {
    return _mutate(() => _repository.rename(id, name));
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
