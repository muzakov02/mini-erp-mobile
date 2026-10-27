import 'package:flutter/material.dart';

import '../../../core/format/formatters.dart';

class DateTile extends StatelessWidget {
  const DateTile({super.key, required this.date, required this.onChanged});

  final String date;
  final ValueChanged<String> onChanged;

  Future<void> _pick(BuildContext context) async {
    final today = businessToday();
    final current = parseApiDate(date);
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isAfter(today) ? today : current,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (picked != null) {
      onChanged(toApiDate(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Sana',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(formatApiDate(date)),
      ),
    );
  }
}
