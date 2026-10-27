import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/formatters.dart';
import '../../../core/widgets/list_state_body.dart';
import '../data/cash_models.dart';
import 'cash_balance_card.dart';
import 'cash_cubit.dart';

Future<void> _chooseDirection(BuildContext context) async {
  final direction = await showModalBottomSheet<CashDirection>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.south_west, color: Colors.green.shade700),
            title: const Text('Kirim'),
            onTap: () => Navigator.of(sheetContext).pop(CashDirection.income),
          ),
          ListTile(
            leading: Icon(
              Icons.north_east,
              color: Theme.of(sheetContext).colorScheme.error,
            ),
            title: const Text('Chiqim'),
            onTap: () => Navigator.of(sheetContext).pop(CashDirection.expense),
          ),
        ],
      ),
    ),
  );
  if (direction == null || !context.mounted) return;
  final cubit = context.read<CashCubit>();
  await context.push('/cash-form/${direction.name}');
  await cubit.load();
}

class CashPage extends StatelessWidget {
  const CashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CashCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Kassa')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _chooseDirection(context),
        icon: const Icon(Icons.add),
        label: const Text('Yangi operatsiya'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: BlocBuilder<CashCubit, CashState>(
              buildWhen: (previous, current) =>
                  previous.balance != current.balance,
              builder: (context, state) =>
                  CashBalanceCard(balance: state.balance),
            ),
          ),
          BlocBuilder<CashCubit, CashState>(
            buildWhen: (previous, current) =>
                previous.filter != current.filter ||
                previous.categories != current.categories,
            builder: (context, state) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Hammasi'),
                    selected: state.filter == null,
                    onSelected: (_) => cubit.selectFilter(null),
                  ),
                  for (final category in state.categories) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(category.label),
                      selected: state.filter == category.code,
                      onSelected: (_) => cubit.selectFilter(category.code),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<CashCubit, CashState>(
              buildWhen: (previous, current) => previous.list != current.list,
              builder: (context, state) => ListStateBody<CashOperation>(
                state: state.list,
                onRetry: cubit.load,
                emptyMessage: "Operatsiyalar yo'q",
                emptyIcon: Icons.payments_outlined,
                listBuilder: (items) => ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) =>
                      _OperationTile(operation: items[index]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationTile extends StatelessWidget {
  const _OperationTile({required this.operation});

  final CashOperation operation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final income = operation.direction == CashDirection.income;
    final amountText = income
        ? '+${formatMoney(operation.amount)}'
        : '-${formatMoney(operation.amount)}';
    final details = [
      formatApiDate(operation.date),
      if (operation.counterpartyName != null) operation.counterpartyName!,
      if (operation.note != null && operation.note!.isNotEmpty) operation.note!,
    ].join(' · ');
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(operation.categoryLabel, style: textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    details,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                amountText,
                textAlign: TextAlign.end,
                style: textTheme.titleSmall?.copyWith(
                  color: income ? Colors.green.shade700 : scheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
