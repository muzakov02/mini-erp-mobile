import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

enum CounterpartyType {
  customer('CUSTOMER', 'Mijoz'),
  supplier('SUPPLIER', 'Yetkazib beruvchi'),
  other('OTHER', 'Boshqa');

  const CounterpartyType(this.value, this.label);

  final String value;
  final String label;

  static CounterpartyType fromValue(String value) {
    return CounterpartyType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CounterpartyType.other,
    );
  }
}

class Counterparty extends Equatable {
  const Counterparty({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.phone,
  });

  final int id;
  final String name;
  final String? phone;
  final CounterpartyType type;
  final Decimal balance;

  factory Counterparty.fromJson(Map<String, dynamic> json) {
    final balance = json['balance'];
    return Counterparty(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      phone: json['phone'] as String?,
      type: CounterpartyType.fromValue(json['type'] as String),
      balance: balance is String ? Decimal.parse(balance) : Decimal.zero,
    );
  }

  @override
  List<Object?> get props => [id, name, phone, type, balance];
}

class CounterpartyInput {
  const CounterpartyInput({
    required this.name,
    required this.type,
    this.phone,
  });

  final String name;
  final String? phone;
  final CounterpartyType type;

  Map<String, dynamic> toCreateJson() => {
    'name': name,
    'type': type.value,
    'phone': ?phone,
  };

  Map<String, dynamic> toUpdateJson() => {
    'name': name,
    'type': type.value,
    'phone': phone,
  };
}
