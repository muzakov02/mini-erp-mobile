import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

RegExp _inputPattern(int decimals, int maxIntDigits) =>
    RegExp('^\\d{0,$maxIntDigits}([.,]\\d{0,$decimals})?\$');

RegExp _valuePattern(int decimals, int maxIntDigits) =>
    RegExp('^\\d{1,$maxIntDigits}(\\.\\d{1,$decimals})?\$');

class MoneyInputFormatter extends TextInputFormatter {
  MoneyInputFormatter({this.decimals = 2, this.maxIntDigits = 16})
    : _allowed = _inputPattern(decimals, maxIntDigits);

  final int decimals;
  final int maxIntDigits;
  final RegExp _allowed;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!_allowed.hasMatch(newValue.text)) {
      return oldValue;
    }
    return newValue.copyWith(text: newValue.text.replaceAll(',', '.'));
  }
}

String? validateMoney(
  String? value, {
  int decimals = 2,
  int maxIntDigits = 16,
  String emptyMessage = 'Summani kiriting',
}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return emptyMessage;
  }
  if (!_valuePattern(decimals, maxIntDigits).hasMatch(text)) {
    return "Summa noto'g'ri";
  }
  return null;
}

Decimal parseMoney(String value) => Decimal.parse(value.trim());

Decimal parseMoneyOrZero(String value) {
  var text = value.trim();
  if (text.endsWith('.')) {
    text = text.substring(0, text.length - 1);
  }
  return Decimal.tryParse(text) ?? Decimal.zero;
}

class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.controller,
    required this.label,
    this.textInputAction = TextInputAction.next,
    this.decimals = 2,
    this.maxIntDigits = 16,
    this.suffixText = "so'm",
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final TextInputAction textInputAction;
  final int decimals;
  final int maxIntDigits;
  final String suffixText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textInputAction: textInputAction,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        MoneyInputFormatter(decimals: decimals, maxIntDigits: maxIntDigits),
      ],
      onChanged: onChanged,
      validator: (value) =>
          validateMoney(value, decimals: decimals, maxIntDigits: maxIntDigits),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffixText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
