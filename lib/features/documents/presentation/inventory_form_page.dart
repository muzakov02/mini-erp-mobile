import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/formatters.dart';
import '../../../core/models/stock_qty.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/picker_sheet.dart';
import '../../../core/widgets/snack.dart';
import '../../products/presentation/products_cubit.dart';
import '../../warehouses/data/warehouse_option.dart';
import '../../warehouses/presentation/warehouses_cubit.dart';
import '../data/document_enums.dart';
import '../data/inventory_document.dart';
import 'amount_row.dart';
import 'date_tile.dart';
import 'inventory_form_cubit.dart';
import 'inventory_line_sheet.dart';
import 'status_chip.dart';
import 'trade_form_cubit.dart';

class InventoryFormPage extends StatefulWidget {
  const InventoryFormPage({super.key, this.documentId});

  final int? documentId;

  @override
  State<InventoryFormPage> createState() => _InventoryFormPageState();
}

class _InventoryFormPageState extends State<InventoryFormPage> {
  Future<void> _editLine({int? index}) async {
    final cubit = context.read<InventoryFormCubit>();
    final products = context.read<ProductsCubit>().state.items;
    if (products.isEmpty) {
      showMessage(context, "Avval mahsulot qo'shing");
      return;
    }
    final line = await showInventoryLineSheet(
      context,
      type: cubit.state.type,
      products: products,
      usedProductIds: cubit.state.items.map((item) => item.productId).toSet(),
      initial: index == null ? null : cubit.state.items[index],
    );
    if (line == null) return;
    if (index == null) {
      cubit.addLine(line);
    } else {
      cubit.replaceLine(index, line);
    }
  }

  Future<void> _pickWarehouse() async {
    final cubit = context.read<InventoryFormCubit>();
    final options = WarehouseOption.flatten(
      context.read<WarehousesCubit>().state.items,
    );
    final picked = await showPickerSheet<WarehouseOption>(
      context,
      title: 'Ombor tanlang',
      items: options,
      labelOf: (item) => item.label,
      emptyMessage: "Omborlar yo'q",
    );
    if (picked != null) {
      cubit.setWarehouse(picked);
    }
  }

  void _changeType(InventoryFormCubit cubit, InventoryType type) {
    if (type == cubit.state.type) return;
    cubit.setType(type);
  }

  bool _precheck(InventoryFormState state) {
    if (state.warehouse == null) {
      showMessage(context, 'Omborni tanlang');
      return false;
    }
    if (state.items.isEmpty) {
      showMessage(context, "Kamida bitta qator qo'shing");
      return false;
    }
    if (state.type == InventoryType.opening &&
        state.items.any((item) => item.unitCost == null)) {
      showMessage(
        context,
        "Boshlang'ich inventarizatsiyada har qatorga tannarx kiriting",
      );
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    final cubit = context.read<InventoryFormCubit>();
    if (!_precheck(cubit.state)) return;
    final failure = await cubit.save();
    if (!mounted) return;
    if (failure != null) {
      await showFailureDialog(context, failure);
    } else {
      showMessage(context, 'Saqlandi');
    }
  }

  Future<void> _post() async {
    final cubit = context.read<InventoryFormCubit>();
    if (!_precheck(cubit.state)) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hujjatni bajarish',
      message:
          "Ombor: ${cubit.state.warehouse!.label}\nQatorlar: ${cubit.state.items.length}\n\nBajarilgandan keyin qoldiqlar sanalgan miqdorga tenglashtiriladi va hujjatni o'zgartirib bo'lmaydi.",
      confirmLabel: 'Bajarish',
    );
    if (!confirmed || !mounted) return;
    final failure = await cubit.post();
    if (!mounted) return;
    if (failure != null) {
      await showFailureDialog(context, failure);
    } else {
      showMessage(context, 'Hujjat bajarildi');
    }
  }

  Future<void> _delete() async {
    final cubit = context.read<InventoryFormCubit>();
    final confirmed = await showConfirmDialog(
      context,
      title: "O'chirish",
      message: "Qoralama hujjat o'chiriladi. Davom etasizmi?",
      confirmLabel: "O'chirish",
    );
    if (!confirmed || !mounted) return;
    final failure = await cubit.delete();
    if (!mounted) return;
    if (failure != null) {
      await showFailureDialog(context, failure);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InventoryFormCubit>();
    return BlocBuilder<InventoryFormCubit, InventoryFormState>(
      builder: (context, state) {
        final id = state.documentId;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              id == null ? 'Inventarizatsiya (yangi)' : 'Inventarizatsiya #$id',
            ),
            bottom: state.busy
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(4),
                    child: LinearProgressIndicator(),
                  )
                : null,
          ),
          body: switch (state.phase) {
            FormPhase.loading => const LoadingView(),
            FormPhase.failure => ErrorView(
              failure: state.failure!,
              onRetry: () => cubit.init(id: widget.documentId),
            ),
            FormPhase.ready =>
              state.isPosted
                  ? _PostedView(state: state)
                  : _buildEditor(context, state),
          },
        );
      },
    );
  }

  Widget _buildEditor(BuildContext context, InventoryFormState state) {
    final cubit = context.read<InventoryFormCubit>();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final busy = state.busy;
    final products = context.read<ProductsCubit>().state.items;
    final unitsPerBlock = {
      for (final product in products) product.id: product.unitsPerBlock,
    };
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<InventoryType>(
            showSelectedIcon: false,
            segments: [
              for (final type in InventoryType.values)
                ButtonSegment(value: type, label: Text(type.label)),
            ],
            selected: {state.type},
            onSelectionChanged: busy
                ? null
                : (selection) => _changeType(cubit, selection.first),
          ),
          const SizedBox(height: 16),
          DateTile(date: state.date, onChanged: cubit.setDate),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: busy ? null : _pickWarehouse,
            child: InputDecorator(
              isEmpty: state.warehouse == null,
              decoration: const InputDecoration(
                labelText: 'Ombor',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              child: Text(state.warehouse?.label ?? ''),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Text('Qatorlar', style: textTheme.titleMedium)),
              OutlinedButton.icon(
                onPressed: busy ? null : () => _editLine(),
                icon: const Icon(Icons.add),
                label: const Text("Qator qo'shish"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                "Qatorlar yo'q",
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            )
          else
            for (var i = 0; i < state.items.length; i++)
              _EditLineTile(
                line: state.items[i],
                unitsPerBlock: unitsPerBlock[state.items[i].productId],
                showCost: state.type == InventoryType.opening,
                onTap: busy ? null : () => _editLine(index: i),
                onDelete: busy ? null : () => cubit.removeLine(i),
              ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: busy ? null : _post,
            child: const Text('Bajarish'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: busy ? null : _save,
            child: const Text('Saqlash'),
          ),
          if (state.documentId != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: busy ? null : _delete,
              style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
              child: const Text("O'chirish"),
            ),
          ],
        ],
      ),
    );
  }
}

String _qtyText(int units, int? unitsPerBlock) {
  if (unitsPerBlock == null) {
    return '${formatInt(units)} dona';
  }
  return formatStock(StockQty.fromUnits(units, unitsPerBlock));
}

class _EditLineTile extends StatelessWidget {
  const _EditLineTile({
    required this.line,
    required this.unitsPerBlock,
    required this.showCost,
    required this.onTap,
    required this.onDelete,
  });

  final InventoryLine line;
  final int? unitsPerBlock;
  final bool showCost;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cost = line.unitCost;
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: onTap,
        title: Text(line.productName),
        subtitle: Text(
          [
            'Sanalgan: ${_qtyText(line.countedQty, unitsPerBlock)}',
            if (showCost)
              cost == null
                  ? 'Tannarx kiritilmagan'
                  : 'Tannarx: ${cost.toStringAsFixed(4)} so\'m / dona',
          ].join('\n'),
        ),
        isThreeLine: showCost,
        trailing: IconButton(
          tooltip: "Qatorni o'chirish",
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _PostedView extends StatelessWidget {
  const _PostedView({required this.state});

  final InventoryFormState state;

  Color _diffColor(BuildContext context, int diff) {
    if (diff > 0) return Colors.green.shade700;
    if (diff < 0) return Theme.of(context).colorScheme.error;
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final products = context.read<ProductsCubit>().state.items;
    final unitsPerBlock = {
      for (final product in products) product.id: product.unitsPerBlock,
    };
    final total = state.totalDiffAmount;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatApiDate(state.date),
                          style: textTheme.titleMedium,
                        ),
                      ),
                      StatusChip(status: state.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AmountRow(label: 'Turi', value: state.type.label),
                  AmountRow(
                    label: 'Ombor',
                    value: state.warehouse?.label ?? '',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Qatorlar', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final line in state.items)
            _PostedLineCard(
              line: line,
              unitsPerBlock: unitsPerBlock[line.productId],
              diffColor: _diffColor(context, line.diffQty ?? 0),
            ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AmountRow(
                label: 'Jami farq',
                value: total == null ? '—' : formatSignedMoney(total),
                bold: true,
                color: total == null
                    ? null
                    : _diffColor(
                        context,
                        total > Decimal.zero
                            ? 1
                            : total < Decimal.zero
                            ? -1
                            : 0,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostedLineCard extends StatelessWidget {
  const _PostedLineCard({
    required this.line,
    required this.unitsPerBlock,
    required this.diffColor,
  });

  final InventoryLine line;
  final int? unitsPerBlock;
  final Color diffColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final expected = line.expectedQty;
    final diff = line.diffQty;
    final diffAmount = line.diffAmount;
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(line.productName, style: textTheme.titleSmall),
            const SizedBox(height: 6),
            AmountRow(
              label: 'Kutilgan',
              value: expected == null ? '—' : _qtyText(expected, unitsPerBlock),
            ),
            AmountRow(
              label: 'Sanalgan',
              value: _qtyText(line.countedQty, unitsPerBlock),
            ),
            AmountRow(
              label: 'Farq',
              value: diff == null ? '—' : '${formatSignedInt(diff)} dona',
              color: diffColor,
              bold: true,
            ),
            AmountRow(
              label: 'Farq summasi',
              value: diffAmount == null ? '—' : formatSignedMoney(diffAmount),
              color: diffColor,
            ),
          ],
        ),
      ),
    );
  }
}
