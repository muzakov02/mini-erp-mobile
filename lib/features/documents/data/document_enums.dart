enum DocumentStatus {
  draft('DRAFT', 'Qoralama'),
  posted('POSTED', 'Bajarilgan');

  const DocumentStatus(this.value, this.label);

  final String value;
  final String label;

  static DocumentStatus fromValue(String value) {
    return DocumentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => DocumentStatus.draft,
    );
  }
}

enum UnitType {
  unit('UNIT', 'Dona'),
  block('BLOCK', 'Blok');

  const UnitType(this.value, this.label);

  final String value;
  final String label;

  static UnitType fromValue(String value) {
    return UnitType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => UnitType.unit,
    );
  }
}

enum InventoryType {
  regular('REGULAR', 'Oddiy'),
  opening('OPENING', "Boshlang'ich");

  const InventoryType(this.value, this.label);

  final String value;
  final String label;

  static InventoryType fromValue(String value) {
    return InventoryType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => InventoryType.regular,
    );
  }
}

enum TradeKind {
  sale('sales', 'Savdo'),
  purchase('purchases', 'Xarid');

  const TradeKind(this.path, this.label);

  final String path;
  final String label;

  static TradeKind fromName(String? name) {
    return TradeKind.values.firstWhere(
      (kind) => kind.name == name,
      orElse: () => TradeKind.sale,
    );
  }
}

enum DocumentKind {
  sale('Savdo'),
  purchase('Xarid'),
  inventory('Inventarizatsiya');

  const DocumentKind(this.label);

  final String label;
}
