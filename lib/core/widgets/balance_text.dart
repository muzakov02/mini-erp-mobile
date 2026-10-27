import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../format/formatters.dart';

class BalanceText extends StatelessWidget {
  const BalanceText({super.key, required this.balance, this.style});

  final Decimal balance;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color color;
    if (balance > Decimal.zero) {
      color = Colors.green.shade700;
    } else if (balance < Decimal.zero) {
      color = scheme.error;
    } else {
      color = scheme.onSurfaceVariant;
    }
    return Text(
      formatBalance(balance),
      style: (style ?? const TextStyle()).copyWith(color: color),
    );
  }
}
