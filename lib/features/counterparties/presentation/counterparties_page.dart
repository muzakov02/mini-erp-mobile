import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/list_state.dart';
import '../../../core/widgets/balance_text.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/list_state_body.dart';
import '../data/counterparty.dart';
import 'counterparties_cubit.dart';

class CounterpartiesPage extends StatefulWidget {
  const CounterpartiesPage({super.key});

  @override
  State<CounterpartiesPage> createState() => _CounterpartiesPageState();
}

class _CounterpartiesPageState extends State<CounterpartiesPage> {
  CounterpartyType? _filter;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CounterpartiesCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Kontragentlar')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/counterparty-form'),
        icon: const Icon(Icons.person_add_alt),
        label: const Text("Kontragent qo'shish"),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Hammasi'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                for (final type in CounterpartyType.values) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(type.label),
                    selected: _filter == type,
                    onSelected: (_) => setState(() => _filter = type),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<CounterpartiesCubit, ListState<Counterparty>>(
              builder: (context, state) => ListStateBody<Counterparty>(
                state: state,
                onRetry: cubit.load,
                emptyMessage: "Kontragentlar yo'q",
                emptyIcon: Icons.people_outline,
                listBuilder: (items) {
                  final visible = _filter == null
                      ? items
                      : items.where((c) => c.type == _filter).toList();
                  if (visible.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 64),
                        EmptyView(
                          message: "Bu turdagi kontragent yo'q",
                          icon: Icons.filter_alt_off_outlined,
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, index) =>
                        _CounterpartyTile(counterparty: visible[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterpartyTile extends StatelessWidget {
  const _CounterpartyTile({required this.counterparty});

  final Counterparty counterparty;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () => context.push('/counterparties/${counterparty.id}'),
        title: Text(counterparty.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(counterparty.type.label, style: textTheme.bodySmall),
            const SizedBox(height: 2),
            BalanceText(
              balance: counterparty.balance,
              style: textTheme.bodyMedium,
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
