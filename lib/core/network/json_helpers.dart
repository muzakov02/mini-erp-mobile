import 'package:decimal/decimal.dart';

Decimal jsonDecimal(Object? value) => Decimal.parse(value as String);

Decimal? jsonDecimalOrNull(Object? value) {
  return value is String ? Decimal.parse(value) : null;
}
