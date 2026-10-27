import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/format/formatters.dart';
import '../data/document_enums.dart';
import '../data/documents_repository.dart';
import '../data/stock_availability.dart';
import '../data/trade_document.dart';

enum FormPhase { loading, ready, failure }

class TradeFormState extends Equatable {
  const TradeFormState({
    this.phase = FormPhase.loading,
    this.failure,
    this.documentId,
    this.status = DocumentStatus.draft,
    this.date = '',
    this.counterparty,
    this.items = const [],
    this.paid,
    this.note,
    this.totalCost,
    this.busy = false,
    this.availability,
  });

  final FormPhase phase;
  final AppFailure? failure;
  final int? documentId;
  final DocumentStatus status;
  final String date;
  final CounterpartyRef? counterparty;
  final List<TradeLine> items;
  final Decimal? paid;
  final String? note;
  final Decimal? totalCost;
  final bool busy;
  final StockAvailability? availability;

  bool get isPosted => status == DocumentStatus.posted;

  Decimal get total =>
      items.fold(Decimal.zero, (sum, line) => sum + line.amount);

  Decimal get paidAmount => paid ?? Decimal.zero;

  Decimal get unpaid => total - paidAmount;

  bool get overpaid => paidAmount > total;

  TradeFormState copyWith({
    FormPhase? phase,
    AppFailure? Function()? failure,
    int? documentId,
    DocumentStatus? status,
    String? date,
    CounterpartyRef? Function()? counterparty,
    List<TradeLine>? items,
    Decimal? paid,
    String? Function()? note,
    Decimal? Function()? totalCost,
    bool? busy,
    StockAvailability? availability,
  }) {
    return TradeFormState(
      phase: phase ?? this.phase,
      failure: failure != null ? failure() : this.failure,
      documentId: documentId ?? this.documentId,
      status: status ?? this.status,
      date: date ?? this.date,
      counterparty: counterparty != null ? counterparty() : this.counterparty,
      items: items ?? this.items,
      paid: paid ?? this.paid,
      note: note != null ? note() : this.note,
      totalCost: totalCost != null ? totalCost() : this.totalCost,
      busy: busy ?? this.busy,
      availability: availability ?? this.availability,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    failure,
    documentId,
    status,
    date,
    counterparty,
    items,
    paid,
    note,
    totalCost,
    busy,
    availability,
  ];
}

class TradeFormCubit extends Cubit<TradeFormState> {
  TradeFormCubit(this._repository, this.kind) : super(const TradeFormState());

  final DocumentsRepository _repository;
  final TradeKind kind;

  Future<void> init({int? id}) async {
    emit(const TradeFormState());
    if (id == null) {
      emit(
        TradeFormState(
          phase: FormPhase.ready,
          date: toApiDate(businessToday()),
          paid: Decimal.zero,
        ),
      );
      _loadAvailability();
      return;
    }
    try {
      final document = await _repository.fetchTrade(kind, id);
      if (isClosed) return;
      emit(_fromDocument(document, state.availability));
      if (!document.status.isPosted) {
        _loadAvailability();
      }
    } on AppFailure catch (failure) {
      if (isClosed) return;
      emit(TradeFormState(phase: FormPhase.failure, failure: failure));
    }
  }

  Future<void> _loadAvailability() async {
    if (kind != TradeKind.sale) return;
    try {
      final availability = await _repository.fetchStockAvailability();
      if (isClosed) return;
      emit(state.copyWith(availability: availability));
    } on AppFailure {
      return;
    }
  }

  TradeFormState _fromDocument(
    TradeDocument document,
    StockAvailability? availability,
  ) {
    return TradeFormState(
      phase: FormPhase.ready,
      documentId: document.id,
      status: document.status,
      date: document.date,
      counterparty: document.counterparty,
      items: document.items,
      paid: document.paidAmount,
      note: document.note,
      totalCost: document.totalCost,
      availability: availability,
    );
  }

  void setDate(String date) => emit(state.copyWith(date: date));

  void setCounterparty(CounterpartyRef? counterparty) =>
      emit(state.copyWith(counterparty: () => counterparty));

  void setPaid(Decimal paid) => emit(state.copyWith(paid: paid));

  void addLine(TradeLine line) =>
      emit(state.copyWith(items: [...state.items, line]));

  void replaceLine(int index, TradeLine line) {
    final items = [...state.items];
    items[index] = line;
    emit(state.copyWith(items: items));
  }

  void removeLine(int index) {
    final items = [...state.items]..removeAt(index);
    emit(state.copyWith(items: items));
  }

  TradeInput _input() {
    return TradeInput(
      date: state.date,
      counterpartyId: state.counterparty?.id,
      paidAmount: state.paidAmount,
      note: state.note,
      items: state.items,
    );
  }

  Future<AppFailure?> save() async {
    emit(state.copyWith(busy: true));
    final failure = await _save();
    if (!isClosed) {
      emit(state.copyWith(busy: false));
    }
    return failure;
  }

  Future<AppFailure?> _save() async {
    try {
      final id = state.documentId;
      final document = id == null
          ? await _repository.createTrade(kind, _input())
          : await _repository.replaceTrade(kind, id, _input());
      if (isClosed) return null;
      emit(_fromDocument(document, state.availability).copyWith(busy: true));
      return null;
    } on AppFailure catch (failure) {
      return failure;
    }
  }

  Future<AppFailure?> post() async {
    emit(state.copyWith(busy: true));
    final saveFailure = await _save();
    if (saveFailure != null) {
      if (!isClosed) emit(state.copyWith(busy: false));
      return saveFailure;
    }
    try {
      final id = state.documentId!;
      final document = await _repository.postTrade(kind, id);
      if (isClosed) return null;
      emit(_fromDocument(document, state.availability));
      return null;
    } on AppFailure catch (failure) {
      if (!isClosed) emit(state.copyWith(busy: false));
      return failure;
    }
  }

  Future<AppFailure?> delete() async {
    final id = state.documentId;
    if (id == null) return null;
    emit(state.copyWith(busy: true));
    try {
      await _repository.deleteTrade(kind, id);
      return null;
    } on AppFailure catch (failure) {
      if (!isClosed) emit(state.copyWith(busy: false));
      return failure;
    }
  }
}

extension DocumentStatusX on DocumentStatus {
  bool get isPosted => this == DocumentStatus.posted;
}
