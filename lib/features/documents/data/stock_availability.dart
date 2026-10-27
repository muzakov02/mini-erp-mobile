import '../../../core/models/stock_qty.dart';

class StockAvailability {
  const StockAvailability(this._byLocation);

  final Map<String, StockQty> _byLocation;

  factory StockAvailability.fromJson(Map<String, dynamic> json) {
    final result = <String, StockQty>{};
    for (final item in (json['items'] as List<dynamic>? ?? const [])) {
      final product = item as Map<String, dynamic>;
      final productId = (product['productId'] as num).toInt();
      for (final location
          in (product['locations'] as List<dynamic>? ?? const [])) {
        final map = location as Map<String, dynamic>;
        final warehouseId = (map['warehouseId'] as num).toInt();
        result[_key(productId, warehouseId)] = StockQty.fromJson(
          map['qty'] as Map<String, dynamic>,
        );
      }
    }
    return StockAvailability(result);
  }

  static String _key(int productId, int warehouseId) => '$productId:$warehouseId';

  StockQty of(int productId, int warehouseId) {
    return _byLocation[_key(productId, warehouseId)] ?? StockQty.zero;
  }
}
