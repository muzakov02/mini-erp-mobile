import 'package:equatable/equatable.dart';

import 'warehouse.dart';

class WarehouseOption extends Equatable {
  const WarehouseOption({required this.id, required this.label});

  final int id;
  final String label;

  static List<WarehouseOption> flatten(List<Warehouse> roots) {
    return [
      for (final root in roots) ...[
        WarehouseOption(id: root.id, label: root.name),
        for (final child in root.children)
          WarehouseOption(id: child.id, label: '${root.name} / ${child.name}'),
      ],
    ];
  }

  @override
  List<Object?> get props => [id, label];
}
