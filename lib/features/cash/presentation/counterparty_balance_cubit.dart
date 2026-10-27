import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_failure.dart';
import '../../counterparties/data/counterparty_repository.dart';

class CounterpartyBalanceState extends Equatable {
  const CounterpartyBalanceState({
    this.loading = false,
    this.balance,
    this.failure,
  });

  final bool loading;
  final Decimal? balance;
  final AppFailure? failure;

  @override
  List<Object?> get props => [loading, balance, failure];
}

class CounterpartyBalanceCubit extends Cubit<CounterpartyBalanceState> {
  CounterpartyBalanceCubit(this._repository)
    : super(const CounterpartyBalanceState());

  final CounterpartyRepository _repository;
  int _token = 0;

  void clear() {
    _token++;
    emit(const CounterpartyBalanceState());
  }

  Future<void> load(int counterpartyId) async {
    final token = ++_token;
    emit(const CounterpartyBalanceState(loading: true));
    try {
      final counterparty = await _repository.fetchOne(counterpartyId);
      if (isClosed || token != _token) return;
      emit(CounterpartyBalanceState(balance: counterparty.balance));
    } on AppFailure catch (failure) {
      if (isClosed || token != _token) return;
      emit(CounterpartyBalanceState(failure: failure));
    }
  }
}
