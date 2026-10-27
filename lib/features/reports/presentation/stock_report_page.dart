import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/format/formatters.dart';
import '../../../core/state/list_state.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../warehouses/data/warehouse_option.dart';
import '../../warehouses/presentation/warehouses_cubit.dart';
import '../data/report_models.dart';
import 'stock_report_cubit.dart';

class StockReportPage extends StatelessWidget {
  const StockReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StockReportCubit>();
    final options = WarehouseOption.flatten(
      context.read<WarehousesCubit>().state.items,
    );
    return BlocBuilder<StockReportCubit, StockReportState>(
      builder: (context, state) {
        final data = state.report.data;
        final failure = state.report.failure;
        return Scaffold(
          appBar: AppBar(title: const Text('Qoldiq hisoboti')),
          bottomNavigationBar: data == null
              ? null
              : SafeArea(
                  child: Material(
                    elevation: 3,
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Umumiy qiymat',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              formatMoney(data.totalStockValue),
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: DropdownButtonFormField<int?>(
                  initialValue: state.warehouseId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Ombor',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Barchasi'),
                    ),
                    for (final option in options)
                      DropdownMenuItem<int?>(
                        value: option.id,
                        child: Text(
                          option.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: cubit.selectWarehouse,
                ),
              ),
              Expanded(
                child: _buildBody(
                  context,
                  state.report.status,
                  data,
                  failure,
                  cubit,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    LoadStatus status,
    StockReport? data,
    AppFailure? failure,
    StockReportCubit cubit,
  ) {
    if (data == null) {
      if (status == LoadStatus.failure && failure != null) {
        return ErrorView(failure: failure, onRetry: cubit.load);
      }
      return const LoadingView();
    }
    if (data.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: cubit.load,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: const EmptyView(
                message: "Mahsulotlar yo'q",
                icon: Icons.inventory_2_outlined,
              ),
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        if (status == LoadStatus.failure && failure != null)
          ErrorBanner(failure: failure, onRetry: cubit.load),
        Expanded(
          child: RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: data.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) =>
                  _ItemCard(item: data.items[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final StockReportItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(item.name, style: textTheme.titleSmall),
            const SizedBox(height: 6),
            _Line(label: 'Jami qoldiq', value: formatStock(item.total), bold: true),
            _Line(label: 'Qiymati', value: formatMoney(item.stockValue)),
            const SizedBox(height: 6),
            if (item.locations.isEmpty)
              Text(
                "Qoldiq yo'q",
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else
              for (final location in item.locations)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          location.label,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          formatStock(location.qty),
                          textAlign: TextAlign.end,
                          style: textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: bold ? FontWeight.w700 : null,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Flexible(child: Text(value, style: style, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
