import 'package:equatable/equatable.dart';

class Warehouse extends Equatable {
  const Warehouse({
    required this.id,
    required this.name,
    this.parentId,
    this.children = const [],
  });

  final int id;
  final String name;
  final int? parentId;
  final List<Warehouse> children;

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    final children = json['children'];
    return Warehouse(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      parentId: (json['parentId'] as num?)?.toInt(),
      children: children is List
          ? children
                .map((c) => Warehouse.fromJson(c as Map<String, dynamic>))
                .toList()
          : const [],
    );
  }

  @override
  List<Object?> get props => [id, name, parentId, children];
}
