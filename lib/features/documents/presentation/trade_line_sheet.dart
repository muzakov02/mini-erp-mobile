import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/format/formatters.dart';
import '../../../core/widgets/money_field.dart';
import '../../../core/widgets/picker_sheet.dart';
import '../../products/data/product.dart';
import '../../warehouses/data/warehouse_option.dart';
import '../data/document_enums.dart';
import '../data/stock_availability.dart';
import '../data/trade_document.dart';

const int _maxInt32 = 2147483647;

Future<TradeLine?> showTradeLineSheet(
  BuildContext context, {
  required TradeKind kind,
  required List<Product> products,
  required List<WarehouseOption> warehouses,
  StockAvailability? availability,
  TradeLine? initial,
}) {
  return showModalBottomSheet<TradeLine>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _TradeLineSheet(
      kind: kind,
      products: products,
      warehouses: warehouses,
      availability: availability,
      initial: initial,
    ),
  );
}

class _TradeLineSheet extends StatefulWidget {
  const _TradeLineSheet({
    required this.kind,
    required this.products,
    required this.warehouses,
    required this.availability,
    required this.initial,
  });

  final TradeKind kind;
  final List<Product> products;
  final List<WarehouseOption> warehouses;
  final StockAvailability? availability;
  final TradeLine? initial;

  @override
  State<_TradeLineSheet> createState() => _TradeLineSheetState();
}

class _TradeLineSheetState extends State<_TradeLineSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantity;
  late final TextEditingController _price;
  Product? _product;
  WarehouseOption? _warehouse;
  late UnitType _unit;
  bool _priceEdited = false;

  bool get _isSale => widget.kind == TradeKind.sale;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _quantity = TextEditingController(text: initial?.quantity.toString() ?? '');
    _price = TextEditingController(
      text: initial == null ? '' : moneyToInput(initial.price),
    );
    _unit = initial?.unitType ?? UnitType.unit;
    _priceEdited = initial != null;
    if (initial != null) {
      _product = widget.products
          .where((product) => product.id == initial.productId)
          .firstOrNull;
      _warehouse = widget.warehouses
          .where((warehouse) => warehouse.id == initial.warehouseId)
          .firstOrNull;
    }
  }

  @override
  void dispose() {
    _quantity.dispose();
    _price.dispose();
    super.dispose();
  }

  void _applyDefaultPrice() {
    final product = _product;
    if (!_isSale || _priceEdited || product == null) return;
    final price = _unit == UnitType.unit
        ? product.salePriceUnit
        : product.salePriceBlock;
    _price.text = moneyToInput(price);
  }

  int get _quantityValue => int.tryParse(_quantity.text.trim()) ?? 0;

  Decimal get _amount =>
      parseMoneyOrZero(_price.text) * Decimal.fromInt(_quantityValue);

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final product = _product!;
    final warehouse = _warehouse!;
    Navigator.of(context).pop(
      TradeLine(
        productId: product.id,
        productName: product.name,
        warehouseId: warehouse.id,
        warehouseName: warehouse.label,
        unitType: _unit,
        quantity: _quantityValue,
        price: parseMoney(_price.text),
      ),
    );
  }

  Widget? _availabilityInfo(BuildContext context) {
    final product = _product;
    final warehouse = _warehouse;
    if (!_isSale || product == null || warehouse == null) return null;
    final scheme = Theme.of(context).colorScheme;
    final availability = widget.availability;
    if (availability == null) {
      return Text(
        "Mavjud qoldiq ma'lumoti olinmadi",
        style: TextStyle(color: scheme.onSurfaceVariant),
      );
    }
    final qty = availability.of(product.id, warehouse.id);
    final requested =
        _quantityValue *
        (_unit == UnitType.block ? product.unitsPerBlock : 1);
    final exceeds = requested > qty.units;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mavjud: ${formatStock(qty)}'),
        if (exceeds)
          Text(
            "So'ralgan miqdor mavjud qoldiqdan ko'p",
            style: TextStyle(color: scheme.error),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = _availabilityInfo(context);
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
                labelOf: (product) => product.name,
                validator: (value) =>
                    value == null ? 'Mahsulotni tanlang' : null,
                onPick: () => showPickerSheet<Product>(
                  context,
                  title: 'Mahsulot tanlang',
                  items: widget.products,
                  labelOf: (product) => product.name,
                  subtitleOf: (product) => formatStock(product.stock),
                  emptyMessage: "Mahsulotlar yo'q",
                ),
                onChanged: (product) => setState(() {
                  _product = product;
                  _applyDefaultPrice();
                }),
              ),
              const SizedBox(height: 16),
              PickerFormField<WarehouseOption>(
                label: 'Ombor',
                value: _warehouse,
                labelOf: (warehouse) => warehouse.label,
                validator: (value) => value == null ? 'Omborni tanlang' : null,
                onPick: () => showPickerSheet<WarehouseOption>(
                  context,
                  title: 'Ombor tanlang',
                  items: widget.warehouses,
                  labelOf: (warehouse) => warehouse.label,
                  emptyMessage: "Omborlar yo'q",
                ),
                onChanged: (warehouse) => setState(() => _warehouse = warehouse),
              ),
              if (info != null) ...[const SizedBox(height: 8), info],
              const SizedBox(height: 16),
              SegmentedButton<UnitType>(
                showSelectedIcon: false,
                segments: [
                  for (final unit in UnitType.values)
                    ButtonSegment(value: unit, label: Text(unit.label)),
                ],
                selected: {_unit},
                onSelectionChanged: (selection) => setState(() {
                  _unit = selection.first;
                  _applyDefaultPrice();
                }),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantity,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Miqdor (${_unit.label.toLowerCase()})',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = int.tryParse((value ?? '').trim());
                  if (parsed == null || parsed < 1) {
                    return '1 yoki undan katta butun son kiriting';
                  }
                  if (parsed > _maxInt32) {
                    return 'Son juda katta';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              MoneyField(
                controller: _price,
                label: _unit == UnitType.unit ? 'Dona narxi' : 'Blok narxi',
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() => _priceEdited = true),
              ),
              const SizedBox(height: 12),
              Text(
                'Summa: ${formatMoney(_amount)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
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
