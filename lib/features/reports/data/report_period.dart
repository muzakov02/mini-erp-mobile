import 'package:equatable/equatable.dart';

import '../../../core/format/formatters.dart';

enum PeriodKind {
  today('Bugun'),
  month('Shu oy'),
  all('Barchasi'),
  custom('Oraliq');

  const PeriodKind(this.label);

  final String label;
}

class ReportPeriod extends Equatable {
  const ReportPeriod({this.kind = PeriodKind.month, this.from, this.to});

  final PeriodKind kind;
  final String? from;
  final String? to;

  String? get queryFrom {
    switch (kind) {
      case PeriodKind.today:
        return toApiDate(businessToday());
      case PeriodKind.month:
        final today = businessToday();
        return toApiDate(DateTime(today.year, today.month));
      case PeriodKind.all:
        return null;
      case PeriodKind.custom:
        return from;
    }
  }

  String? get queryTo {
    switch (kind) {
      case PeriodKind.today:
      case PeriodKind.month:
        return toApiDate(businessToday());
      case PeriodKind.all:
        return null;
      case PeriodKind.custom:
        return to;
    }
  }

  String get description {
    final start = queryFrom;
    final end = queryTo;
    if (start == null && end == null) return 'Barcha davr';
    if (start == end) return formatApiDate(start!);
    final startText = start == null ? '…' : formatApiDate(start);
    final endText = end == null ? '…' : formatApiDate(end);
    return '$startText — $endText';
  }

  @override
  List<Object?> get props => [kind, from, to];
}
