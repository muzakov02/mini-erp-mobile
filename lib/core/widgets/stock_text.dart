import 'package:flutter/material.dart';

import '../format/formatters.dart';
import '../models/stock_qty.dart';

class StockText extends StatelessWidget {
  const StockText({super.key, required this.qty, this.style});

  final StockQty qty;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(formatStock(qty), style: style);
  }
}
