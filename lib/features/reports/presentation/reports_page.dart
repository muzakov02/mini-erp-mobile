import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/formatters.dart';
import '../../../core/state/list_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../cash/presentation/cash_balance_card.dart';
import '../../cash/presentation/cash_cubit.dart';
import '../../documents/presentation/amount_row.dart';
import '../data/report_models.dart';
import '../data/report_period.dart';
import 'reports_cubit.dart';

const String _excludedNote =
    "Qarz, qarz qaytarish va kapital harakatlari foyda yoki zarar emas.";

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  Future<void> _selectKind(
    BuildContext context,
    PeriodKind kind,
    ReportPeriod current,
  ) async {
    final cubit = context.read<ReportsCubit>();
    if (kind != PeriodKind.custom) {
      cubit.selectPeriod(ReportPeriod(kind: kind));
      return;
    }
    final today = businessToday();
    final from = current.from;
    final to = current.to;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: today,
      initialDateRange: current.kind == PeriodKind.custom &&
              from != null &&
              to != null
          ? DateTimeRange(start: parseApiDate(from), end: parseApiDate(to))
          : null,
    );
    if (range == null) return;
    cubit.selectPeriod(
      ReportPeriod(
        kind: PeriodKind.custom,
        from: toApiDate(range.start),
        to: toApiDate(range.end),
      ),
    );
  }

  Future<void> _refresh(BuildContext context) {
    return Future.wait([
      context.read<ReportsCubit>().load(),
      context.read<CashCubit>().load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hisobotlar')),
      body: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          final period = state.period;
          final pnl = state.pnl;
          final data = pnl.data;
          final failure = pnl.failure;
          return RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<PeriodKind>(
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      textStyle: Theme.of(context).textTheme.labelMedium,
                    ),
                    segments: [
                      for (final kind in PeriodKind.values)
                        ButtonSegment(
                          value: kind,
                          label: Text(
                            kind.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    selected: {period.kind},
                    onSelectionChanged: (selection) =>
                        _selectKind(context, selection.first, period),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range_outlined, size: 18),
                      const SizedBox(width: 6),
                      Expanded(child: Text(period.description)),
                      if (period.kind == PeriodKind.custom)
                        TextButton(
                          onPressed: () =>
                              _selectKind(context, PeriodKind.custom, period),
                          child: const Text("O'zgartirish"),
                        ),
                    ],
                  ),
                ),
                BlocBuilder<CashCubit, CashState>(
                  buildWhen: (previous, current) =>
                      previous.balance != current.balance,
                  builder: (context, cash) =>
                      CashBalanceCard(balance: cash.balance),
                ),
                const SizedBox(height: 12),
                if (data == null && pnl.status == LoadStatus.loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: LoadingView(),
                  )
                else if (data == null && failure != null)
                  SizedBox(
                    height: 280,
                    child: ErrorView(
                      failure: failure,
                      onRetry: context.read<ReportsCubit>().load,
                    ),
                  )
                else if (data != null) ...[
                  if (failure != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ErrorBanner(
                        failure: failure,
                        onRetry: context.read<ReportsCubit>().load,
                      ),
                    ),
                  _PnlCard(report: data),
                  const SizedBox(height: 12),
                  _ExcludedCard(excluded: data.excluded),
                ],
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.point_of_sale),
                        title: const Text('Savdo hisoboti'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          Uri(
                            path: '/sales-report',
                            queryParameters: {
                              'from': ?period.queryFrom,
                              'to': ?period.queryTo,
                            },
                          ).toString(),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: const Text('Qoldiq hisoboti'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/stock-report'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PnlCard extends StatelessWidget {
  const _PnlCard({required this.report});

  final PnlReport report;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final net = report.netProfit;
    final netColor = net > Decimal.zero
        ? Colors.green.shade700
        : net < Decimal.zero
        ? scheme.error
        : scheme.onSurfaceVariant;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Foyda va zarar', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            AmountRow(
              label: 'Savdo daromadi',
              value: formatMoney(report.revenue),
            ),
            AmountRow(label: 'Tannarx', value: formatMoney(-report.cogs)),
            AmountRow(
              label: 'Yalpi foyda',
              value: formatMoney(report.grossProfit),
              bold: true,
            ),
            const Divider(height: 24),
            AmountRow(
              label: 'Boshqa daromad',
              value: formatMoney(report.otherIncome),
            ),
            const SizedBox(height: 8),
            Text('Xarajatlar', style: textTheme.titleSmall),
            AmountRow(
              label: "Yo'l kira",
              value: formatMoney(-report.expenseTransport),
            ),
            AmountRow(label: 'Ijara', value: formatMoney(-report.expenseRent)),
            AmountRow(
              label: 'Boshqa xarajat',
              value: formatMoney(-report.expenseOther),
            ),
            AmountRow(
              label: 'Jami xarajat',
              value: formatMoney(-report.expenseTotal),
              bold: true,
            ),
            const Divider(height: 24),
            Text('Inventarizatsiya farqi', style: textTheme.titleSmall),
            AmountRow(
              label: 'Kamomad',
              value: formatMoney(report.inventoryShortage),
            ),
            AmountRow(
              label: 'Ortiqcha',
              value: formatSignedMoney(report.inventorySurplus),
            ),
            AmountRow(
              label: 'Jami farq',
              value: formatSignedMoney(report.inventoryTotal),
              bold: true,
            ),
            const Divider(height: 24),
            Text('SOF FOYDA', style: textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              formatMoney(net),
              style: textTheme.headlineMedium?.copyWith(
                color: netColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExcludedCard extends StatelessWidget {
  const _ExcludedCard({required this.excluded});

  final ExcludedFromPnl excluded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rows = <(String, Decimal)>[
      ("Mijozlarning nasiya to'lovi", excluded.customerDebtPayments),
      ('Berilgan qarz qaytdi', excluded.loansReturned),
      ('Olingan qarz', excluded.loansTaken),
      ('Berilgan qarz', excluded.loansGiven),
      ("Olingan qarz to'langan", excluded.loansRepaid),
      ("Yetkazib beruvchilarga to'lov", excluded.supplierPayments),
      ('Egasi olgan pul', excluded.ownerWithdrawals),
      ("Boshlang'ich kassa qoldig'i", excluded.openingBalance),
      ("Boshlang'ich tovar qiymati", excluded.openingStockValue),
    ];
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Foydaga kirmagan pul harakatlari",
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final row in rows)
              AmountRow(label: row.$1, value: formatMoney(row.$2)),
            const SizedBox(height: 8),
            Text(
              _excludedNote,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
