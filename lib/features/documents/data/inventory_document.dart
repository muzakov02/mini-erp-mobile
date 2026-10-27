import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import 'document_enums.dart';

class InventoryLine extends Equatable {
  const InventoryLine({
    required this.productId,
    required this.productName,
    required this.countedQty,
    this.unitCost,
    this.expectedQty,
    this.diffQty,
    this.diffAmount,
  });

  final int productId;
  final String productName;
  final int countedQty;
  final Decimal? unitCost;
  final int? expectedQty;
  final int? diffQty;
  final Decimal? diffAmount;

  factory InventoryLine.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final unitCost = json['unitCost'];
    final diffAmount = json['diffAmount'];
    return InventoryLine(
      productId: (json['productId'] as num).toInt(),
      productName: (product?['name'] as String?) ?? '#${json['productId']}',
      countedQty: (json['countedQty'] as num).toInt(),
      unitCost: unitCost is String ? Decimal.parse(unitCost) : null,
      expectedQty: (json['expectedQty'] as num?)?.toInt(),
      diffQty: (json['diffQty'] as num?)?.toInt(),
      diffAmount: diffAmount is String ? Decimal.parse(diffAmount) : null,
    );
  }

  @override
  List<Object?> get props => [
    productId,
    productName,
    countedQty,
    unitCost,
    expectedQty,
    diffQty,
    diffAmount,
  ];
}

class InventorySummary extends Equatable {
  const InventorySummary({
    required this.id,
    required this.date,
    required this.type,
    required this.status,
    required this.warehouseName,
    this.totalDiffAmount,
  });

  final int id;
  final String date;
  final InventoryType type;
  final DocumentStatus status;
  final String warehouseName;
  final Decimal? totalDiffAmount;

  factory InventorySummary.fromJson(Map<String, dynamic> json) {
    final warehouse = json['warehouse'] as Map<String, dynamic>?;
    final diff = json['totalDiffAmount'];
    return InventorySummary(
      id: (json['id'] as num).toInt(),
      date: json['date'] as String,
      type: InventoryType.fromValue(json['type'] as String),
      status: DocumentStatus.fromValue(json['status'] as String),
      warehouseName:
          (warehouse?['name'] as String?) ?? '#${json['warehouseId']}',
      totalDiffAmount: diff is String ? Decimal.parse(diff) : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    date,
    type,
    status,
    warehouseName,
    totalDiffAmount,
  ];
}

class InventoryDocument extends Equatable {
  const InventoryDocument({
    required this.id,
    required this.date,
    required this.type,
    required this.status,
    required this.warehouseId,
    required this.warehouseName,
    required this.items,
    this.totalDiffAmount,
    this.note,
  });

  final int id;
  final String date;
  final InventoryType type;
  final DocumentStatus status;
  final int warehouseId;
  final String warehouseName;
  final Decimal? totalDiffAmount;
  final String? note;
  final List<InventoryLine> items;

  factory InventoryDocument.fromJson(Map<String, dynamic> json) {
    final warehouse = json['warehouse'] as Map<String, dynamic>?;
    final diff = json['totalDiffAmount'];
    return InventoryDocument(
      id: (json['id'] as num).toInt(),
      date: json['date'] as String,
      type: InventoryType.fromValue(json['type'] as String),
      status: DocumentStatus.fromValue(json['status'] as String),
      warehouseId: (json['warehouseId'] as num).toInt(),
      warehouseName:
          (warehouse?['name'] as String?) ?? '#${json['warehouseId']}',
      totalDiffAmount: diff is String ? Decimal.parse(diff) : null,
      note: json['note'] as String?,
      items: (json['items'] as List<dynamic>)
          .map((item) => InventoryLine.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    date,
    type,
    status,
    warehouseId,
    warehouseName,
    totalDiffAmount,
    note,
    items,
  ];
}

class InventoryInput {
  const InventoryInput({
    required this.date,
    required this.type,
    required this.warehouseId,
    required this.items,
    this.note,
  });

  final String date;
  final InventoryType type;
  final int warehouseId;
  final String? note;
  final List<InventoryLine> items;

  Map<String, dynamic> toJson() {
    final isOpening = type == InventoryType.opening;
    return {
      'date': date,
      'type': type.value,
      'warehouseId': warehouseId,
      'note': ?note,
      'items': items
          .map(
            (item) => {
              'productId': item.productId,
              'countedQty': item.countedQty,
              if (isOpening && item.unitCost != null)
                'unitCost': item.unitCost!.toStringAsFixed(4),
            },
          )
          .toList(),
    };
  }
}
