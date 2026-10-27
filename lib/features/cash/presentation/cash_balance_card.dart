import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../core/format/formatters.dart';

class CashBalanceCard extends StatelessWidget {
  const CashBalanceCard({super.key, required this.balance});

  final Decimal? balance;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final value = balance;
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                color: scheme.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Kassa qoldig'i",
                    style: textTheme.labelLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value == null ? '—' : formatMoney(value),
                    style: textTheme.headlineSmall?.copyWith(
                      color: value != null && value < Decimal.zero
                          ? scheme.error
                          : scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
