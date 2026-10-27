import 'package:equatable/equatable.dart';

import '../errors/app_failure.dart';
import 'list_state.dart';

class LoadState<T> extends Equatable {
  const LoadState({
    this.status = LoadStatus.loading,
    this.data,
    this.failure,
  });

  final LoadStatus status;
  final T? data;
  final AppFailure? failure;

  @override
  List<Object?> get props => [status, data, failure];
}
