import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/state/list_state.dart';
import '../data/document_enums.dart';
import '../data/documents_repository.dart';

class DocumentRow extends Equatable {
  const DocumentRow({
    required this.kind,
    required this.id,
    required this.date,
    required this.subtitle,
    required this.status,
    this.amount,
  });

  final DocumentKind kind;
  final int id;
  final String date;
  final String subtitle;
  final DocumentStatus status;
  final Decimal? amount;

  @override
  List<Object?> get props => [kind, id, date, subtitle, status, amount];
}

class DocumentsListState extends Equatable {
  const DocumentsListState({
    this.kind = DocumentKind.sale,
    this.filter,
    this.list = const ListState(),
  });

  final DocumentKind kind;
  final DocumentStatus? filter;
  final ListState<DocumentRow> list;

  @override
  List<Object?> get props => [kind, filter, list];
}

class DocumentsCubit extends Cubit<DocumentsListState> {
  DocumentsCubit(this._repository) : super(const DocumentsListState());

  final DocumentsRepository _repository;
  int _token = 0;

  void selectKind(DocumentKind kind) {
    if (kind == state.kind) return;
    emit(DocumentsListState(kind: kind, filter: state.filter));
    load();
  }

  void selectFilter(DocumentStatus? filter) {
    if (filter == state.filter) return;
    emit(DocumentsListState(kind: state.kind, filter: filter));
    load();
  }

  Future<void> load() async {
    final kind = state.kind;
    final filter = state.filter;
    final token = ++_token;
    if (state.list.items.isEmpty) {
      emit(DocumentsListState(kind: kind, filter: filter));
    }
    try {
      final rows = await _fetch(kind, filter);
      if (isClosed || token != _token) return;
      emit(
        DocumentsListState(
          kind: kind,
          filter: filter,
          list: ListState(status: LoadStatus.success, items: rows),
        ),
      );
    } on AppFailure catch (failure) {
      if (isClosed || token != _token) return;
      emit(
        DocumentsListState(
          kind: kind,
          filter: filter,
          list: ListState(
            status: LoadStatus.failure,
            items: state.list.items,
            failure: failure,
          ),
        ),
      );
    }
  }

  Future<List<DocumentRow>> _fetch(
    DocumentKind kind,
    DocumentStatus? filter,
  ) async {
    switch (kind) {
      case DocumentKind.sale:
      case DocumentKind.purchase:
        final tradeKind = kind == DocumentKind.sale
            ? TradeKind.sale
            : TradeKind.purchase;
        final items = await _repository.fetchTrades(tradeKind, status: filter);
        return items
            .map(
              (item) => DocumentRow(
                kind: kind,
                id: item.id,
                date: item.date,
                subtitle: item.counterpartyName ?? 'Kontragentsiz',
                status: item.status,
                amount: item.totalAmount,
              ),
            )
            .toList();
      case DocumentKind.inventory:
        final items = await _repository.fetchInventories(status: filter);
        return items
            .map(
              (item) => DocumentRow(
                kind: kind,
                id: item.id,
                date: item.date,
                subtitle: '${item.warehouseName} · ${item.type.label}',
                status: item.status,
                amount: item.totalDiffAmount,
              ),
            )
            .toList();
    }
  }
}
