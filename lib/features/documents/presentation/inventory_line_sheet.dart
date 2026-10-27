import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/format/formatters.dart';
import '../../../core/models/stock_qty.dart';
import '../../../core/widgets/money_field.dart';
import '../../../core/widgets/picker_sheet.dart';
import '../../products/data/product.dart';
import '../data/document_enums.dart';
import '../data/inventory_document.dart';

const int _maxInt32 = 2147483647;

Future<InventoryLine?> showInventoryLineSheet(
  BuildContext context, {
  required InventoryType type,
  required List<Product> products,
  required Set<int> usedProductIds,
  InventoryLine? initial,
}) {
  return showModalBottomSheet<InventoryLine>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _InventoryLineSheet(
      type: type,
      products: products,
      usedProductIds: usedProductIds,
      initial: initial,
    ),
  );
}

class _InventoryLineSheet extends StatefulWidget {
  const _InventoryLineSheet({
    required this.type,
    required this.products,
    required this.usedProductIds,
    required this.initial,
  });

  final InventoryType type;
  final List<Product> products;
  final Set<int> usedProductIds;
  final InventoryLine? initial;

  @override
  State<_InventoryLineSheet> createState() => _InventoryLineSheetState();
}

class _InventoryLineSheetState extends State<_InventoryLineSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _counted;
  late final TextEditingController _cost;
  Product? _product;

  bool get _isOpening => widget.type == InventoryType.opening;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _counted = TextEditingController(
      text: initial?.countedQty.toString() ?? '',
    );
    _cost = TextEditingController(
      text: initial?.unitCost == null ? '' : _costToInput(initial!.unitCost!),
    );
    if (initial != null) {
      _product = widget.products
          .where((product) => product.id == initial.productId)
          .firstOrNull;
    }
  }

  @override
  void dispose() {
    _counted.dispose();
    _cost.dispose();
    super.dispose();
  }

  String _costToInput(Object cost) {
    final text = cost.toString();
    if (!text.contains('.')) return text;
    var trimmed = text;
    while (trimmed.endsWith('0')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed.endsWith('.')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final product = _product!;
    Navigator.of(context).pop(
      InventoryLine(
        productId: product.id,
        productName: product.name,
        countedQty: int.parse(_counted.text.trim()),
        unitCost: _isOpening ? parseMoney(_cost.text) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final counted = int.tryParse(_counted.text.trim());
    final product = _product;
    final converted = counted != null && product != null
        ? formatStock(StockQty.fromUnits(counted, product.unitsPerBlock))
        : null;
    final available = widget.products
        .where(
          (item) =>
              !widget.usedProductIds.contains(item.id) ||
              item.id == widget.initial?.productId,
        )
        .toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.initial == null ? "Qator qo'shish" : 'Qatorni tahrirlash',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              PickerFormField<Product>(
                label: 'Mahsulot',
                value: _product,
                labelOf: (item) => item.name,
                validator: (value) =>
                    value == null ? 'Mahsulotni tanlang' : null,
                onPick: () => showPickerSheet<Product>(
                  context,
                  title: 'Mahsulot tanlang',
                  items: available,
                  labelOf: (item) => item.name,
                  emptyMessage: "Qo'shiladigan mahsulot qolmadi",
                ),
                onChanged: (item) => setState(() => _product = item),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _counted,
                textInputAction: _isOpening
                    ? TextInputAction.next
                    : TextInputAction.done,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Sanalgan miqdor (dona)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = int.tryParse((value ?? '').trim());
                  if (parsed == null) {
                    return 'Miqdorni kiriting (0 yoki undan katta)';
                  }
                  if (parsed > _maxInt32) {
                    return 'Son juda katta';
                  }
                  return null;
                },
              ),
              if (converted != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('= $converted'),
                ),
              if (_isOpening) ...[
                const SizedBox(height: 16),
                MoneyField(
                  controller: _cost,
                  label: 'Tannarx (1 dona uchun)',
                  textInputAction: TextInputAction.done,
                  decimals: 4,
                  maxIntDigits: 14,
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submit,
                child: Text(widget.initial == null ? "Qo'shish" : 'Saqlash'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
