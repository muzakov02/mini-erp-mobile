import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/formatters.dart';
import '../../../core/state/list_state.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/list_state_body.dart';
import '../../../core/widgets/snack.dart';
import '../../../core/widgets/stock_text.dart';
import '../data/product.dart';
import 'products_cubit.dart';

enum _ProductAction { edit, archive }

class ProductsTab extends StatelessWidget {
  const ProductsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductsCubit>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/product-form'),
        icon: const Icon(Icons.add),
        label: const Text("Mahsulot qo'shish"),
      ),
      body: BlocBuilder<ProductsCubit, ListState<Product>>(
        builder: (context, state) => ListStateBody<Product>(
          state: state,
          onRetry: cubit.load,
          emptyMessage: "Mahsulotlar yo'q",
          emptyIcon: Icons.inventory_2_outlined,
          listBuilder: (items) => ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, index) =>
                _ProductTile(product: items[index]),
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final Product product;

  Future<void> _archive(BuildContext context) async {
    final cubit = context.read<ProductsCubit>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Arxivlash',
      message: '"${product.name}" mahsulotini arxivlaysizmi?',
      confirmLabel: 'Arxivlash',
    );
    if (!confirmed || !context.mounted) return;
    final failure = await cubit.archive(product.id);
    if (failure != null && context.mounted) {
      showFailure(context, failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () => context.push('/product-form', extra: product),
        title: Text(product.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StockText(qty: product.stock, style: textTheme.bodyMedium),
            const SizedBox(height: 2),
            Text(
              'Dona: ${formatMoney(product.salePriceUnit)}',
              style: textTheme.bodySmall,
            ),
            Text(
              'Blok: ${formatMoney(product.salePriceBlock)}',
              style: textTheme.bodySmall,
            ),
          ],
        ),
        trailing: PopupMenuButton<_ProductAction>(
          tooltip: 'Amallar',
          onSelected: (action) {
            switch (action) {
              case _ProductAction.edit:
                context.push('/product-form', extra: product);
              case _ProductAction.archive:
                _archive(context);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: _ProductAction.edit, child: Text('Tahrirlash')),
            PopupMenuItem(
              value: _ProductAction.archive,
              child: Text('Arxivlash'),
            ),
          ],
        ),
      ),
    );
  }
}
