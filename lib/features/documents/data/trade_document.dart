import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import 'document_enums.dart';

class CounterpartyRef extends Equatable {
  const CounterpartyRef({required this.id, required this.name});

  final int id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

class TradeLine extends Equatable {
  const TradeLine({
    required this.productId,
    required this.productName,
    required this.warehouseId,
    required this.warehouseName,
    required this.unitType,
    required this.quantity,
    required this.price,
  });

  final int productId;
  final String productName;
  final int warehouseId;
  final String warehouseName;
  final UnitType unitType;
  final int quantity;
  final Decimal price;

  Decimal get amount => price * Decimal.fromInt(quantity);

  factory TradeLine.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final warehouse = json['warehouse'] as Map<String, dynamic>?;
    return TradeLine(
      productId: (json['productId'] as num).toInt(),
      productName: (product?['name'] as String?) ?? '#${json['productId']}',
      warehouseId: (json['warehouseId'] as num).toInt(),
      warehouseName:
          (warehouse?['name'] as String?) ?? '#${json['warehouseId']}',
      unitType: UnitType.fromValue(json['unitType'] as String),
      quantity: (json['quantity'] as num).toInt(),
      price: Decimal.parse(json['price'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'warehouseId': warehouseId,
    'unitType': unitType.value,
    'quantity': quantity,
    'price': price.toStringAsFixed(2),
  };

  @override
  List<Object?> get props => [
    productId,
    productName,
    warehouseId,
    warehouseName,
    unitType,
    quantity,
    price,
  ];
}

class TradeSummary extends Equatable {
  const TradeSummary({
    required this.id,
    required this.date,
    required this.status,
    required this.totalAmount,
    this.counterpartyName,
  });

  final int id;
  final String date;
  final DocumentStatus status;
  final Decimal totalAmount;
  final String? counterpartyName;

  factory TradeSummary.fromJson(Map<String, dynamic> json) {
    final counterparty = json['counterparty'] as Map<String, dynamic>?;
    return TradeSummary(
      id: (json['id'] as num).toInt(),
      date: json['date'] as String,
      status: DocumentStatus.fromValue(json['status'] as String),
      totalAmount: Decimal.parse(json['totalAmount'] as String),
      counterpartyName: counterparty?['name'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, date, status, totalAmount, counterpartyName];
}

class TradeDocument extends Equatable {
  const TradeDocument({
    required this.id,
    required this.date,
    required this.status,
    required this.totalAmount,
    required this.paidAmount,
    required this.items,
    this.counterparty,
    this.totalCost,
    this.note,
  });

  final int id;
  final String date;
  final DocumentStatus status;
  final Decimal totalAmount;
  final Decimal paidAmount;
  final Decimal? totalCost;
  final String? note;
  final CounterpartyRef? counterparty;
  final List<TradeLine> items;

  factory TradeDocument.fromJson(Map<String, dynamic> json) {
    final counterparty = json['counterparty'] as Map<String, dynamic>?;
    final totalCost = json['totalCost'];
    return TradeDocument(
      id: (json['id'] as num).toInt(),
      date: json['date'] as String,
      status: DocumentStatus.fromValue(json['status'] as String),
      totalAmount: Decimal.parse(json['totalAmount'] as String),
      paidAmount: Decimal.parse(json['paidAmount'] as String),
      totalCost: totalCost is String ? Decimal.parse(totalCost) : null,
      note: json['note'] as String?,
      counterparty: counterparty == null
          ? null
          : CounterpartyRef(
              id: (counterparty['id'] as num).toInt(),
              name: counterparty['name'] as String,
            ),
      items: (json['items'] as List<dynamic>)
          .map((item) => TradeLine.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    date,
    status,
    totalAmount,
    paidAmount,
    totalCost,
    note,
    counterparty,
    items,
  ];
}

class TradeInput {
  const TradeInput({
    required this.date,
    required this.paidAmount,
    required this.items,
    this.counterpartyId,
    this.note,
  });

  final String date;
  final int? counterpartyId;
  final Decimal paidAmount;
  final String? note;
  final List<TradeLine> items;

  Map<String, dynamic> toJson() => {
    'date': date,
    'counterpartyId': counterpartyId,
    'paidAmount': paidAmount.toStringAsFixed(2),
    'note': ?note,
    'items': items.map((item) => item.toJson()).toList(),
  };
}
