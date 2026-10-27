import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

import '../models/stock_qty.dart';

String _groupDigits(String digits) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(' ');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

String formatInt(int value) {
  final grouped = _groupDigits(value.abs().toString());
  return value < 0 ? '-$grouped' : grouped;
}

String formatMoney(Decimal value) {
  final parts = value.abs().toStringAsFixed(2).split('.');
  final fraction = parts[1] == '00' ? '' : ',${parts[1]}';
  final sign = value < Decimal.zero ? '-' : '';
  return "$sign${_groupDigits(parts[0])}$fraction so'm";
}

String moneyToInput(Decimal value) {
  final fixed = value.toStringAsFixed(2);
  return fixed.endsWith('.00') ? fixed.substring(0, fixed.length - 3) : fixed;
}

String formatApiDate(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) {
    return value;
  }
  return DateFormat('dd.MM.yyyy').format(date);
}

String toApiDate(DateTime value) => DateFormat('yyyy-MM-dd').format(value);

DateTime businessToday() {
  final shifted = DateTime.now().toUtc().add(const Duration(hours: 5));
  return DateTime(shifted.year, shifted.month, shifted.day);
}

DateTime parseApiDate(String value) {
  return DateTime.tryParse(value) ?? businessToday();
}

String formatSignedMoney(Decimal value) {
  final text = formatMoney(value);
  return value > Decimal.zero ? '+$text' : text;
}

String formatBalance(Decimal balance) {
  if (balance > Decimal.zero) {
    return 'Bizga qarz: ${formatMoney(balance)}';
  }
  if (balance < Decimal.zero) {
    return 'Biz qarzmiz: ${formatMoney(balance.abs())}';
  }
  return "Hisob-kitob yo'q";
}

String formatSignedInt(int value) {
  final text = formatInt(value);
  return value > 0 ? '+$text' : text;
}

String formatStock(StockQty qty) {
  final units = '${formatInt(qty.units)} dona';
  if (qty.blocks == 0) {
    return units;
  }
  final blocks = '${formatInt(qty.blocks)} blok';
  if (qty.remainder == 0) {
    return '$units · $blocks';
  }
  final sign = qty.remainder < 0 ? '-' : '+';
  return '$units · $blocks $sign ${formatInt(qty.remainder.abs())} dona';
}
