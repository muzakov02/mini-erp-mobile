import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/formatters.dart';
import '../../../core/widgets/balance_text.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/snack.dart';
import '../../../core/state/list_state.dart';
import '../data/counterparty.dart';
import '../data/counterparty_entry.dart';
import 'counterparties_cubit.dart';
import 'counterparty_detail_cubit.dart';

class CounterpartyDetailPage extends StatelessWidget {
  const CounterpartyDetailPage({super.key, required this.counterpartyId});

  final int counterpartyId;

  Future<void> _edit(BuildContext context, Counterparty counterparty) async {
    final detail = context.read<CounterpartyDetailCubit>();
    final saved = await context.push<bool>(
      '/counterparty-form',
      extra: counterparty,
    );
    if (saved == true) {
      await detail.load(counterpartyId);
    }
  }

  Future<void> _archive(BuildContext context, Counterparty counterparty) async {
    final list = context.read<CounterpartiesCubit>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Arxivlash',
      message: '"${counterparty.name}" kontragentini arxivlaysizmi?',
      confirmLabel: 'Arxivlash',
    );
    if (!confirmed || !context.mounted) return;
    final failure = await list.archive(counterparty.id);
    if (!context.mounted) return;
    if (failure != null) {
      showFailure(context, failure);
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CounterpartyDetailCubit>();
    return BlocBuilder<CounterpartyDetailCubit, CounterpartyDetailState>(
      builder: (context, state) {
        final counterparty = state.counterparty;
        return Scaffold(
          appBar: AppBar(
            title: Text(counterparty?.name ?? 'Kontragent'),
            actions: [
              if (counterparty != null) ...[
                IconButton(
                  tooltip: 'Tahrirlash',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _edit(context, counterparty),
                ),
                IconButton(
                  tooltip: 'Arxivlash',
                  icon: const Icon(Icons.archive_outlined),
                  onPressed: () => _archive(context, counterparty),
                ),
              ],
            ],
          ),
          body: _buildBody(context, state, () => cubit.load(counterpartyId)),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    CounterpartyDetailState state,
    Future<void> Function() reload,
  ) {
    final counterparty = state.counterparty;
    final failure = state.failure;
    if (counterparty == null) {
      if (state.status == LoadStatus.failure && failure != null) {
        return ErrorView(failure: failure, onRetry: reload);
      }
      return const LoadingView();
    }
    return Column(
      children: [
        if (state.status == LoadStatus.failure && failure != null)
          ErrorBanner(failure: failure, onRetry: reload),
        Expanded(
          child: RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _Header(counterparty: counterparty),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'Hisob-kitob tarixi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (state.entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: EmptyView(
                      message: "Hisob-kitob yozuvlari yo'q",
                      icon: Icons.receipt_long_outlined,
                    ),
                  )
                else
                  for (final entry in state.entries) _EntryTile(entry: entry),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.counterparty});

  final Counterparty counterparty;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final phone = counterparty.phone;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(counterparty.type.label, style: textTheme.labelLarge),
            if (phone != null && phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(phone, style: textTheme.bodyMedium),
            ],
            const SizedBox(height: 12),
            BalanceText(
              balance: counterparty.balance,
              style: textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final CounterpartyEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final amount = entry.amount;
    final Color color;
    if (amount > Decimal.zero) {
      color = Colors.green.shade700;
    } else if (amount < Decimal.zero) {
      color = scheme.error;
    } else {
      color = scheme.onSurfaceVariant;
    }
    final sign = amount > Decimal.zero ? '+' : '';
    return ListTile(
      title: Text('${entry.sourceLabel} #${entry.sourceId}'),
      subtitle: Text(formatApiDate(entry.date)),
      trailing: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.5,
        ),
        child: Text(
          '$sign${formatMoney(amount)}',
          textAlign: TextAlign.end,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
