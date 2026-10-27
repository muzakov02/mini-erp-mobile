import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/state/list_state.dart';
import '../data/cash_models.dart';
import '../data/cash_repository.dart';

class CashState extends Equatable {
  const CashState({
    this.list = const ListState(),
    this.balance,
    this.categories = const [],
    this.filter,
  });

  final ListState<CashOperation> list;
  final Decimal? balance;
  final List<CashCategoryMeta> categories;
  final String? filter;

  @override
  List<Object?> get props => [list, balance, categories, filter];
}

class CashCubit extends Cubit<CashState> {
  CashCubit(this._repository) : super(const CashState());

  final CashRepository _repository;
  int _token = 0;

  CashState _with({
    ListState<CashOperation>? list,
    Decimal? balance,
    List<CashCategoryMeta>? categories,
    String? Function()? filter,
  }) {
    return CashState(
      list: list ?? state.list,
      balance: balance ?? state.balance,
      categories: categories ?? state.categories,
      filter: filter != null ? filter() : state.filter,
    );
  }

  void selectFilter(String? category) {
    if (category == state.filter) return;
    emit(_with(list: const ListState(), filter: () => category));
    load();
  }

  Future<void> load() async {
    final token = ++_token;
    final filter = state.filter;
    if (state.list.items.isEmpty) {
      emit(_with(list: const ListState()));
    }
    try {
      final balance = await _repository.fetchBalance();
      final categories = state.categories.isEmpty
          ? await _repository.fetchCategories()
          : state.categories;
      final operations = await _repository.fetchOperations(category: filter);
      if (isClosed || token != _token) return;
      emit(
        _with(
          list: ListState(status: LoadStatus.success, items: operations),
          balance: balance,
          categories: categories,
        ),
      );
    } on AppFailure catch (failure) {
      if (isClosed || token != _token) return;
      emit(
        _with(
          list: ListState(
            status: LoadStatus.failure,
            items: state.list.items,
            failure: failure,
          ),
        ),
      );
    }
  }

  Future<AppFailure?> create(CashInput input) async {
    try {
      await _repository.create(input);
    } on AppFailure catch (failure) {
      return failure;
    }
    await load();
    return null;
  }
}
