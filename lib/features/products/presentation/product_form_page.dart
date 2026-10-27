import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/formatters.dart';
import '../../../core/widgets/money_field.dart';
import '../../../core/widgets/snack.dart';
import '../data/product.dart';
import 'products_cubit.dart';

const int _maxInt32 = 2147483647;

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, this.product});

  final Product? product;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _unitsPerBlock;
  late final TextEditingController _priceUnit;
  late final TextEditingController _priceBlock;
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: product?.name ?? '');
    _unitsPerBlock = TextEditingController(
      text: product?.unitsPerBlock.toString() ?? '',
    );
    _priceUnit = TextEditingController(
      text: product == null ? '' : moneyToInput(product.salePriceUnit),
    );
    _priceBlock = TextEditingController(
      text: product == null ? '' : moneyToInput(product.salePriceBlock),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _unitsPerBlock.dispose();
    _priceUnit.dispose();
    _priceBlock.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<ProductsCubit>();
    final input = ProductInput(
      name: _name.text.trim(),
      unitsPerBlock: int.parse(_unitsPerBlock.text.trim()),
      salePriceUnit: parseMoney(_priceUnit.text),
      salePriceBlock: parseMoney(_priceBlock.text),
    );
    setState(() => _saving = true);
    final failure = await cubit.save(input, id: widget.product?.id);
    if (!mounted) return;
    if (failure != null) {
      setState(() => _saving = false);
      showFailure(context, failure);
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Mahsulotni tahrirlash' : "Mahsulot qo'shish"),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nomi',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Nomini kiriting'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitsPerBlock,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Blokdagi dona soni',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = int.tryParse((value ?? '').trim());
                  if (parsed == null || parsed < 1) {
                    return "1 yoki undan katta butun son kiriting";
                  }
                  if (parsed > _maxInt32) {
                    return 'Son juda katta';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              MoneyField(controller: _priceUnit, label: 'Dona narxi'),
              const SizedBox(height: 16),
              MoneyField(
                controller: _priceBlock,
                label: 'Blok narxi',
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Saqlash'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
