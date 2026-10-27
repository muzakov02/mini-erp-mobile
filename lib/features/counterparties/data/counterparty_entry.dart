import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

enum EntrySource {
  sale('SALE', 'Sotuv'),
  purchase('PURCHASE', 'Xarid'),
  cash('CASH', 'Kassa');

  const EntrySource(this.value, this.label);

  final String value;
  final String label;

  static EntrySource? fromValue(String value) {
    for (final source in EntrySource.values) {
      if (source.value == value) {
        return source;
      }
    }
    return null;
  }
}

class CounterpartyEntry extends Equatable {
  const CounterpartyEntry({
    required this.id,
    required this.amount,
    required this.sourceLabel,
    required this.sourceId,
    required this.date,
  });

  final int id;
  final Decimal amount;
  final String sourceLabel;
  final int sourceId;
  final String date;

  factory CounterpartyEntry.fromJson(Map<String, dynamic> json) {
    final rawSource = json['sourceType'] as String;
    return CounterpartyEntry(
      id: (json['id'] as num).toInt(),
      amount: Decimal.parse(json['amount'] as String),
      sourceLabel: EntrySource.fromValue(rawSource)?.label ?? rawSource,
      sourceId: (json['sourceId'] as num).toInt(),
      date: json['date'] as String,
    );
  }

  @override
  List<Object?> get props => [id, amount, sourceLabel, sourceId, date];
}
