import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/stock_qty.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.unitsPerBlock,
    required this.salePriceUnit,
    required this.salePriceBlock,
    required this.stock,
  });

  final int id;
  final String name;
  final int unitsPerBlock;
  final Decimal salePriceUnit;
  final Decimal salePriceBlock;
  final StockQty stock;

  factory Product.fromJson(Map<String, dynamic> json) {
    final stock = json['stock'];
    return Product(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      unitsPerBlock: (json['unitsPerBlock'] as num).toInt(),
      salePriceUnit: Decimal.parse(json['salePriceUnit'] as String),
      salePriceBlock: Decimal.parse(json['salePriceBlock'] as String),
      stock: stock is Map<String, dynamic>
          ? StockQty.fromJson(stock)
          : StockQty.zero,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    unitsPerBlock,
    salePriceUnit,
    salePriceBlock,
    stock,
  ];
}

class ProductInput {
  const ProductInput({
    required this.name,
    required this.unitsPerBlock,
    required this.salePriceUnit,
    required this.salePriceBlock,
  });

  final String name;
  final int unitsPerBlock;
  final Decimal salePriceUnit;
  final Decimal salePriceBlock;

  Map<String, dynamic> toJson() => {
    'name': name,
    'unitsPerBlock': unitsPerBlock,
    'salePriceUnit': salePriceUnit.toStringAsFixed(2),
    'salePriceBlock': salePriceBlock.toStringAsFixed(2),
  };
}
