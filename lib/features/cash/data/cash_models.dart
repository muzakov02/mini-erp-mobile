import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import '../../../core/network/json_helpers.dart';

enum CashDirection {
  income('IN', 'Kirim'),
  expense('OUT', 'Chiqim');

  const CashDirection(this.value, this.label);

  final String value;
  final String label;

  static CashDirection fromValue(String value) {
    return CashDirection.values.firstWhere(
      (direction) => direction.value == value,
      orElse: () => CashDirection.income,
    );
  }
}

class CashCategoryMeta extends Equatable {
  const CashCategoryMeta({
    required this.code,
    required this.direction,
    required this.label,
    required this.manual,
    required this.requiresCounterparty,
  });

  final String code;
  final CashDirection direction;
  final String label;
  final bool manual;
  final bool requiresCounterparty;

  factory CashCategoryMeta.fromJson(Map<String, dynamic> json) {
    return CashCategoryMeta(
      code: json['code'] as String,
      direction: CashDirection.fromValue(json['direction'] as String),
      label: json['label'] as String,
      manual: json['manual'] as bool,
      requiresCounterparty: json['requiresCounterparty'] as bool,
    );
  }

  @override
  List<Object?> get props => [
    code,
    direction,
    label,
    manual,
    requiresCounterparty,
  ];
}

class CashOperation extends Equatable {
  const CashOperation({
    required this.id,
    required this.date,
    required this.direction,
    required this.category,
    required this.categoryLabel,
    required this.amount,
    this.counterpartyName,
    this.note,
  });

  final int id;
  final String date;
  final CashDirection direction;
  final String category;
  final String categoryLabel;
  final Decimal amount;
  final String? counterpartyName;
  final String? note;

  factory CashOperation.fromJson(Map<String, dynamic> json) {
    final counterparty = json['counterparty'] as Map<String, dynamic>?;
    return CashOperation(
      id: (json['id'] as num).toInt(),
      date: json['date'] as String,
      direction: CashDirection.fromValue(json['direction'] as String),
      category: json['category'] as String,
      categoryLabel: json['categoryLabel'] as String,
      amount: jsonDecimal(json['amount']),
      counterpartyName: counterparty?['name'] as String?,
      note: json['note'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    date,
    direction,
    category,
    categoryLabel,
    amount,
    counterpartyName,
    note,
  ];
}

class CashInput {
  const CashInput({
    required this.date,
    required this.category,
    required this.amount,
    this.counterpartyId,
    this.note,
  });

  final String date;
  final String category;
  final Decimal amount;
  final int? counterpartyId;
  final String? note;

  Map<String, dynamic> toJson() => {
    'date': date,
    'category': category,
    'amount': amount.toStringAsFixed(2),
    'counterpartyId': ?counterpartyId,
    'note': ?note,
  };
}
