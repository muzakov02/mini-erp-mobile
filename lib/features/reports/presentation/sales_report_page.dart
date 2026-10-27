import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/formatters.dart';
import '../../../core/state/list_state.dart';
import '../../../core/state/load_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../documents/presentation/amount_row.dart';
import '../data/report_models.dart';
import '../data/report_period.dart';
import 'sales_report_cubit.dart';

class SalesReportPage extends StatelessWidget {
  const SalesReportPage({super.key, this.from, this.to});

  final String? from;
  final String? to;

  Future<void> _reload(BuildContext context) {
    return context.read<SalesReportCubit>().load(from: from, to: to);
  }

  @override
  Widget build(BuildContext context) {
    final description = ReportPeriod(
      kind: PeriodKind.custom,
      from: from,
      to: to,
    ).description;
    return Scaffold(
      appBar: AppBar(title: const Text('Savdo hisoboti')),
      body: BlocBuilder<SalesReportCubit, LoadState<SalesReport>>(
        builder: (context, state) {
          final data = state.data;
          final failure = state.failure;
          if (data == null) {
            if (state.status == LoadStatus.failure && failure != null) {
              return ErrorView(
                failure: failure,
                onRetry: () => _reload(context),
              );
            }
            return const LoadingView();
          }
          return RefreshIndicator(
            onRefresh: () => _reload(context),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              children: [
                if (failure != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ErrorBanner(
                      failure: failure,
                      onRetry: () => _reload(context),
                    ),
                  ),
                Row(
                  children: [
                    const Icon(Icons.date_range_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(child: Text(description)),
                  ],
                ),
                const SizedBox(height: 8),
                _SummaryCard(summary: data.summary),
                const SizedBox(height: 16),
                Text(
                  "Mahsulotlar bo'yicha",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (data.byProduct.isEmpty)
                  const _EmptyNote(text: "Sotuvlar yo'q")
                else
                  for (final row in data.byProduct) _ProductCard(row: row),
                const SizedBox(height: 16),
                Text(
                  'Hujjatlar',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (data.documents.isEmpty)
                  const _EmptyNote(text: "Hujjatlar yo'q")
                else
                  for (final doc in data.documents) _DocumentCard(doc: doc),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final SalesSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AmountRow(label: 'Hujjatlar soni', value: '${summary.count}'),
            AmountRow(label: 'Daromad', value: formatMoney(summary.revenue)),
            AmountRow(label: 'Tannarx', value: formatMoney(summary.cost)),
            AmountRow(
              label: 'Yalpi foyda',
              value: formatMoney(summary.grossProfit),
              bold: true,
              color: summary.grossProfit < Decimal.zero
                  ? Theme.of(context).colorScheme.error
                  : Colors.green.shade700,
            ),
            const Divider(height: 24),
            AmountRow(label: "To'langan", value: formatMoney(summary.paid)),
            AmountRow(
              label: 'Nasiya',
              value: formatMoney(summary.unpaid),
              color: summary.unpaid > Decimal.zero
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.row});

  final SalesProductRow row;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(row.name, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            AmountRow(label: 'Miqdor', value: formatStock(row.qty)),
            AmountRow(label: 'Daromad', value: formatMoney(row.revenue)),
            AmountRow(label: 'Tannarx', value: formatMoney(row.cost)),
            AmountRow(
              label: 'Yalpi foyda',
              value: formatMoney(row.grossProfit),
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.doc});

  final SalesDocumentRow doc;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/trade-form/sale?id=${doc.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${doc.id} · ${formatApiDate(doc.date)}',
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(doc.counterpartyName ?? 'Kontragentsiz'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMoney(doc.totalAmount),
                    style: textTheme.titleSmall,
                  ),
                  if (doc.unpaid > Decimal.zero)
                    Text(
                      'Nasiya: ${formatMoney(doc.unpaid)}',
                      style: textTheme.bodySmall?.copyWith(color: scheme.error),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
