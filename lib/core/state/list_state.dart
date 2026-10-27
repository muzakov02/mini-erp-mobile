import 'package:equatable/equatable.dart';

import '../errors/app_failure.dart';

enum LoadStatus { loading, success, failure }

class ListState<T> extends Equatable {
  const ListState({
    this.status = LoadStatus.loading,
    this.items = const <Never>[],
    this.failure,
  });

  final LoadStatus status;
  final List<T> items;
  final AppFailure? failure;

  @override
  List<Object?> get props => [status, items, failure];
}
