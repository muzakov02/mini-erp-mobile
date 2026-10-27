import 'package:equatable/equatable.dart';

class StockQty extends Equatable {
  const StockQty({
    required this.units,
    required this.blocks,
    required this.remainder,
  });

  static const StockQty zero = StockQty(units: 0, blocks: 0, remainder: 0);

  final int units;
  final int blocks;
  final int remainder;

  factory StockQty.fromUnits(int units, int unitsPerBlock) {
    if (unitsPerBlock < 1) {
      return StockQty(units: units, blocks: 0, remainder: units);
    }
    return StockQty(
      units: units,
      blocks: units ~/ unitsPerBlock,
      remainder: units.remainder(unitsPerBlock),
    );
  }

  factory StockQty.fromJson(Map<String, dynamic> json) {
    return StockQty(
      units: (json['units'] as num).toInt(),
      blocks: (json['blocks'] as num).toInt(),
      remainder: (json['remainder'] as num).toInt(),
    );
  }

  @override
  List<Object?> get props => [units, blocks, remainder];
}
