import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/format/formatters.dart';
import '../../warehouses/data/warehouse_option.dart';
import '../data/document_enums.dart';
import '../data/documents_repository.dart';
import '../data/inventory_document.dart';
import 'trade_form_cubit.dart';

class InventoryFormState extends Equatable {
  const InventoryFormState({
    this.phase = FormPhase.loading,
    this.failure,
    this.documentId,
    this.status = DocumentStatus.draft,
    this.date = '',
    this.type = InventoryType.regular,
    this.warehouse,
    this.items = const [],
    this.note,
    this.totalDiffAmount,
    this.busy = false,
  });

  final FormPhase phase;
  final AppFailure? failure;
  final int? documentId;
  final DocumentStatus status;
  final String date;
  final InventoryType type;
  final WarehouseOption? warehouse;
  final List<InventoryLine> items;
  final String? note;
  final Decimal? totalDiffAmount;
  final bool busy;

  bool get isPosted => status == DocumentStatus.posted;

  InventoryFormState copyWith({
    String? date,
    InventoryType? type,
    WarehouseOption? warehouse,
    List<InventoryLine>? items,
    bool? busy,
  }) {
    return InventoryFormState(
      phase: phase,
      failure: failure,
      documentId: documentId,
      status: status,
      date: date ?? this.date,
      type: type ?? this.type,
      warehouse: warehouse ?? this.warehouse,
      items: items ?? this.items,
      note: note,
      totalDiffAmount: totalDiffAmount,
      busy: busy ?? this.busy,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    failure,
    documentId,
    status,
    date,
    type,
    warehouse,
    items,
    note,
    totalDiffAmount,
    busy,
  ];
}

class InventoryFormCubit extends Cubit<InventoryFormState> {
  InventoryFormCubit(this._repository) : super(const InventoryFormState());

  final DocumentsRepository _repository;

  Future<void> init({int? id}) async {
    emit(const InventoryFormState());
    if (id == null) {
      emit(
        InventoryFormState(
          phase: FormPhase.ready,
          date: toApiDate(businessToday()),
        ),
      );
      return;
    }
    try {
      final document = await _repository.fetchInventory(id);
      if (isClosed) return;
      emit(_fromDocument(document));
    } on AppFailure catch (failure) {
      if (isClosed) return;
      emit(InventoryFormState(phase: FormPhase.failure, failure: failure));
    }
  }

  InventoryFormState _fromDocument(InventoryDocument document) {
    return InventoryFormState(
      phase: FormPhase.ready,
      documentId: document.id,
      status: document.status,
      date: document.date,
      type: document.type,
      warehouse: WarehouseOption(
        id: document.warehouseId,
        label: document.warehouseName,
      ),
      items: document.items,
      note: document.note,
      totalDiffAmount: document.totalDiffAmount,
    );
  }

  void setDate(String date) => emit(state.copyWith(date: date));

  void setType(InventoryType type) => emit(state.copyWith(type: type));

  void setWarehouse(WarehouseOption warehouse) =>
      emit(state.copyWith(warehouse: warehouse));

  void addLine(InventoryLine line) =>
      emit(state.copyWith(items: [...state.items, line]));

  void replaceLine(int index, InventoryLine line) {
    final items = [...state.items];
    items[index] = line;
    emit(state.copyWith(items: items));
  }

  void removeLine(int index) {
    final items = [...state.items]..removeAt(index);
    emit(state.copyWith(items: items));
  }

  InventoryInput _input() {
    return InventoryInput(
      date: state.date,
      type: state.type,
      warehouseId: state.warehouse!.id,
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
          ? await _repository.createInventory(_input())
          : await _repository.replaceInventory(id, _input());
      if (isClosed) return null;
      emit(_fromDocument(document).copyWith(busy: true));
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
      final document = await _repository.postInventory(state.documentId!);
      if (isClosed) return null;
      emit(_fromDocument(document));
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
      await _repository.deleteInventory(id);
      return null;
    } on AppFailure catch (failure) {
      if (!isClosed) emit(state.copyWith(busy: false));
      return failure;
    }
  }
}
