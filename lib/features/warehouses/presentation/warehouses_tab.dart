import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/state/list_state.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/list_state_body.dart';
import '../../../core/widgets/snack.dart';
import '../data/warehouse.dart';
import 'warehouse_name_dialog.dart';
import 'warehouses_cubit.dart';

enum _WarehouseAction { rename, archive }

Future<void> _create(BuildContext context, {Warehouse? parent}) async {
  final cubit = context.read<WarehousesCubit>();
  final name = await showWarehouseNameDialog(
    context,
    title: parent == null
        ? "Ombor qo'shish"
        : "Sub-ombor qo'shish: ${parent.name}",
  );
  if (name == null || !context.mounted) return;
  final failure = await cubit.create(name, parentId: parent?.id);
  if (!context.mounted) return;
  _report(context, failure);
}

Future<void> _rename(BuildContext context, Warehouse warehouse) async {
  final cubit = context.read<WarehousesCubit>();
  final name = await showWarehouseNameDialog(
    context,
    title: "Nomini o'zgartirish",
    initialName: warehouse.name,
  );
  if (name == null || !context.mounted) return;
  final failure = await cubit.rename(warehouse.id, name);
  if (!context.mounted) return;
  _report(context, failure);
}

Future<void> _archive(BuildContext context, Warehouse warehouse) async {
  final cubit = context.read<WarehousesCubit>();
  final confirmed = await showConfirmDialog(
    context,
    title: 'Arxivlash',
    message: '"${warehouse.name}" omborini arxivlaysizmi?',
    confirmLabel: 'Arxivlash',
  );
  if (!confirmed || !context.mounted) return;
  final failure = await cubit.archive(warehouse.id);
  if (!context.mounted) return;
  _report(context, failure);
}

void _report(BuildContext context, AppFailure? failure) {
  if (failure != null) {
    showFailure(context, failure);
  }
}

class WarehousesTab extends StatelessWidget {
  const WarehousesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WarehousesCubit>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        icon: const Icon(Icons.add),
        label: const Text("Ombor qo'shish"),
      ),
      body: BlocBuilder<WarehousesCubit, ListState<Warehouse>>(
        builder: (context, state) => ListStateBody<Warehouse>(
          state: state,
          onRetry: cubit.load,
          emptyMessage: "Omborlar yo'q",
          emptyIcon: Icons.warehouse_outlined,
          listBuilder: (items) => ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, index) => _RootWarehouseTile(
              key: ValueKey(items[index].id),
              warehouse: items[index],
            ),
          ),
        ),
      ),
    );
  }
}

class _RootWarehouseTile extends StatelessWidget {
  const _RootWarehouseTile({super.key, required this.warehouse});

  final Warehouse warehouse;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.warehouse_outlined),
        title: Text(warehouse.name),
        subtitle: Text('Sub-omborlar: ${warehouse.children.length}'),
        trailing: _WarehouseMenu(warehouse: warehouse),
        children: [
          for (final child in warehouse.children)
            ListTile(
              contentPadding: const EdgeInsets.only(left: 32, right: 4),
              leading: const Icon(Icons.subdirectory_arrow_right),
              title: Text(child.name),
              trailing: _WarehouseMenu(warehouse: child),
            ),
          ListTile(
            contentPadding: const EdgeInsets.only(left: 32, right: 16),
            leading: const Icon(Icons.add),
            title: const Text("Sub-ombor qo'shish"),
            onTap: () => _create(context, parent: warehouse),
          ),
        ],
      ),
    );
  }
}

class _WarehouseMenu extends StatelessWidget {
  const _WarehouseMenu({required this.warehouse});

  final Warehouse warehouse;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_WarehouseAction>(
      tooltip: 'Amallar',
      onSelected: (action) {
        switch (action) {
          case _WarehouseAction.rename:
            _rename(context, warehouse);
          case _WarehouseAction.archive:
            _archive(context, warehouse);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _WarehouseAction.rename,
          child: Text("Nomini o'zgartirish"),
        ),
        PopupMenuItem(
          value: _WarehouseAction.archive,
          child: Text('Arxivlash'),
        ),
      ],
    );
  }
}
