import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/formatters.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/money_field.dart';
import '../../../core/widgets/picker_sheet.dart';
import '../../../core/widgets/snack.dart';
import '../../counterparties/data/counterparty.dart';
import '../../counterparties/presentation/counterparties_cubit.dart';
import '../../products/presentation/products_cubit.dart';
import '../../warehouses/data/warehouse_option.dart';
import '../../warehouses/presentation/warehouses_cubit.dart';
import '../data/document_enums.dart';
import '../data/trade_document.dart';
import 'amount_row.dart';
import 'date_tile.dart';
import 'status_chip.dart';
import 'trade_form_cubit.dart';
import 'trade_line_sheet.dart';

class TradeFormPage extends StatefulWidget {
  const TradeFormPage({super.key, required this.kind, this.documentId});

  final TradeKind kind;
  final int? documentId;

  @override
  State<TradeFormPage> createState() => _TradeFormPageState();
}

class _TradeFormPageState extends State<TradeFormPage> {
  final TextEditingController _paid = TextEditingController();

  @override
  void dispose() {
    _paid.dispose();
    super.dispose();
  }

  Future<void> _pickCounterparty() async {
    final cubit = context.read<TradeFormCubit>();
    final items = context.read<CounterpartiesCubit>().state.items;
    final picked = await showPickerSheet<Counterparty>(
      context,
      title: 'Kontragent tanlang',
      items: items,
      labelOf: (item) => item.name,
      subtitleOf: (item) => item.type.label,
      emptyMessage: "Kontragentlar yo'q",
    );
    if (picked == null) return;
    cubit.setCounterparty(CounterpartyRef(id: picked.id, name: picked.name));
  }

  Future<void> _editLine({int? index}) async {
    final cubit = context.read<TradeFormCubit>();
    final products = context.read<ProductsCubit>().state.items;
    final warehouses = WarehouseOption.flatten(
      context.read<WarehousesCubit>().state.items,
    );
    if (products.isEmpty || warehouses.isEmpty) {
      showMessage(context, "Avval mahsulot va ombor qo'shing");
      return;
    }
    final line = await showTradeLineSheet(
      context,
      kind: widget.kind,
      products: products,
      warehouses: warehouses,
      availability: cubit.state.availability,
      initial: index == null ? null : cubit.state.items[index],
    );
    if (line == null) return;
    if (index == null) {
      cubit.addLine(line);
    } else {
      cubit.replaceLine(index, line);
    }
  }

  bool _precheck(TradeFormState state) {
    if (state.items.isEmpty) {
      showMessage(context, "Kamida bitta qator qo'shing");
      return false;
    }
    if (state.overpaid) {
      showMessage(context, "To'langan summa jami summadan oshmasligi kerak");
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    final cubit = context.read<TradeFormCubit>();
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
    final cubit = context.read<TradeFormCubit>();
    final state = cubit.state;
    if (!_precheck(state)) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hujjatni bajarish',
      message:
          "Jami: ${formatMoney(state.total)}\nTo'langan: ${formatMoney(state.paidAmount)}\nNasiyaga: ${formatMoney(state.unpaid)}\n\nBajarilgandan keyin hujjatni o'zgartirib bo'lmaydi.",
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
    final cubit = context.read<TradeFormCubit>();
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
    final cubit = context.read<TradeFormCubit>();
    return BlocConsumer<TradeFormCubit, TradeFormState>(
      listenWhen: (previous, current) =>
          previous.phase != FormPhase.ready && current.phase == FormPhase.ready,
      listener: (context, state) {
        final paid = state.paidAmount;
        _paid.text = paid > Decimal.zero ? moneyToInput(paid) : '';
      },
      builder: (context, state) {
        final id = state.documentId;
        final title = id == null
            ? '${widget.kind.label} (yangi)'
            : '${widget.kind.label} #$id';
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
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
                  ? _PostedView(kind: widget.kind, state: state)
                  : _buildEditor(context, state),
          },
        );
      },
    );
  }

  Widget _buildEditor(BuildContext context, TradeFormState state) {
    final cubit = context.read<TradeFormCubit>();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final busy = state.busy;
    final counterparty = state.counterparty;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DateTile(date: state.date, onChanged: cubit.setDate),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: _pickCounterparty,
            child: InputDecorator(
              isEmpty: counterparty == null,
              decoration: InputDecoration(
                labelText: 'Kontragent (ixtiyoriy)',
                border: const OutlineInputBorder(),
                suffixIcon: counterparty == null
                    ? const Icon(Icons.arrow_drop_down)
                    : IconButton(
                        tooltip: 'Tozalash',
                        icon: const Icon(Icons.close),
                        onPressed: () => cubit.setCounterparty(null),
                      ),
              ),
              child: Text(counterparty?.name ?? ''),
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
              _LineTile(
                line: state.items[i],
                onTap: busy ? null : () => _editLine(index: i),
                onDelete: busy ? null : () => cubit.removeLine(i),
              ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AmountRow(
                    label: 'Jami',
                    value: formatMoney(state.total),
                    bold: true,
                  ),
                  const SizedBox(height: 12),
                  MoneyField(
                    controller: _paid,
                    label: "To'langan summa",
                    textInputAction: TextInputAction.done,
                    onChanged: (text) => cubit.setPaid(parseMoneyOrZero(text)),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: busy
                          ? null
                          : () {
                              final total = state.total;
                              _paid.text = moneyToInput(total);
                              cubit.setPaid(total);
                            },
                      child: const Text("To'liq to'landi"),
                    ),
                  ),
                  if (state.overpaid)
                    Text(
                      "To'langan summa jami summadan oshmasligi kerak",
                      style: TextStyle(color: scheme.error),
                    ),
                  if (!state.overpaid && state.unpaid > Decimal.zero) ...[
                    AmountRow(
                      label: 'Nasiyaga',
                      value: formatMoney(state.unpaid),
                      bold: true,
                      color: scheme.error,
                    ),
                    if (state.counterparty == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          "Diqqat: to'lanmagan qism bor, lekin kontragent tanlanmagan. Hujjatni bajarish uchun kontragent tanlang.",
                          style: TextStyle(color: scheme.error),
                        ),
                      ),
                  ],
                ],
              ),
            ),
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

class _LineTile extends StatelessWidget {
  const _LineTile({
    required this.line,
    required this.onTap,
    required this.onDelete,
  });

  final TradeLine line;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: onTap,
        title: Text(line.productName),
        subtitle: Text(
          '${line.warehouseName}\n${line.quantity} ${line.unitType.label.toLowerCase()} × ${formatMoney(line.price)}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                formatMoney(line.amount),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            IconButton(
              tooltip: "Qatorni o'chirish",
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _PostedView extends StatelessWidget {
  const _PostedView({required this.kind, required this.state});

  final TradeKind kind;
  final TradeFormState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cost = state.totalCost;
    final profit = cost == null ? null : state.total - cost;
    final note = state.note;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  AmountRow(
                    label: 'Kontragent',
                    value: state.counterparty?.name ?? 'Kontragentsiz',
                  ),
                  if (note != null && note.isNotEmpty)
                    AmountRow(label: 'Izoh', value: note),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Qatorlar', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final line in state.items)
            Card(
              margin: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                title: Text(line.productName),
                subtitle: Text(
                  '${line.warehouseName}\n${line.quantity} ${line.unitType.label.toLowerCase()} × ${formatMoney(line.price)}',
                ),
                isThreeLine: true,
                trailing: Text(
                  formatMoney(line.amount),
                  style: textTheme.titleSmall,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  AmountRow(
                    label: 'Jami',
                    value: formatMoney(state.total),
                    bold: true,
                  ),
                  AmountRow(
                    label: "To'langan",
                    value: formatMoney(state.paidAmount),
                  ),
                  AmountRow(
                    label: 'Nasiyaga',
                    value: formatMoney(state.unpaid),
                    color: state.unpaid > Decimal.zero ? scheme.error : null,
                  ),
                  if (kind == TradeKind.sale && cost != null && profit != null) ...[
                    const Divider(height: 24),
                    AmountRow(label: 'Tannarx', value: formatMoney(cost)),
                    AmountRow(
                      label: 'Yalpi foyda',
                      value: formatMoney(profit),
                      bold: true,
                      color: profit < Decimal.zero
                          ? scheme.error
                          : Colors.green.shade700,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
