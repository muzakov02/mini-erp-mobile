import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/formatters.dart';
import '../../../core/widgets/list_state_body.dart';
import '../data/document_enums.dart';
import 'documents_cubit.dart';
import 'status_chip.dart';

String _formPath(DocumentKind kind, {int? id}) {
  final query = id == null ? '' : '?id=$id';
  switch (kind) {
    case DocumentKind.sale:
      return '/trade-form/sale$query';
    case DocumentKind.purchase:
      return '/trade-form/purchase$query';
    case DocumentKind.inventory:
      return '/inventory-form$query';
  }
}

Future<void> _open(BuildContext context, DocumentKind kind, {int? id}) async {
  final cubit = context.read<DocumentsCubit>();
  await context.push(_formPath(kind, id: id));
  await cubit.load();
}

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DocumentsCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Hujjatlar')),
      floatingActionButton: BlocBuilder<DocumentsCubit, DocumentsListState>(
        buildWhen: (previous, current) => previous.kind != current.kind,
        builder: (context, state) => FloatingActionButton.extended(
          onPressed: () => _open(context, state.kind),
          icon: const Icon(Icons.add),
          label: const Text('Yangi hujjat'),
        ),
      ),
      body: Column(
        children: [
          BlocBuilder<DocumentsCubit, DocumentsListState>(
            buildWhen: (previous, current) =>
                previous.kind != current.kind ||
                previous.filter != current.filter,
            builder: (context, state) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<DocumentKind>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        textStyle: Theme.of(context).textTheme.labelMedium,
                      ),
                      segments: [
                        for (final kind in DocumentKind.values)
                          ButtonSegment(
                            value: kind,
                            label: Text(
                              kind.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      selected: {state.kind},
                      onSelectionChanged: (selection) =>
                          cubit.selectKind(selection.first),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Hammasi'),
                        selected: state.filter == null,
                        onSelected: (_) => cubit.selectFilter(null),
                      ),
                      for (final status in DocumentStatus.values) ...[
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(status.label),
                          selected: state.filter == status,
                          onSelected: (_) => cubit.selectFilter(status),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<DocumentsCubit, DocumentsListState>(
              builder: (context, state) => ListStateBody<DocumentRow>(
                state: state.list,
                onRetry: cubit.load,
                emptyMessage: "Hujjatlar yo'q",
                emptyIcon: Icons.description_outlined,
                listBuilder: (rows) => ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) =>
                      _DocumentTile(row: rows[index]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.row});

  final DocumentRow row;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final amount = row.amount;
    final amountText = amount == null
        ? '—'
        : row.kind == DocumentKind.inventory
        ? formatSignedMoney(amount)
        : formatMoney(amount);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _open(context, row.kind, id: row.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${row.id} · ${formatApiDate(row.date)}',
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(row.subtitle, style: textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    row.kind == DocumentKind.inventory
                        ? 'Farq: $amountText'
                        : amountText,
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  StatusChip(status: row.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
