import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/formatters.dart';
import '../../../core/widgets/balance_text.dart';
import '../../../core/widgets/money_field.dart';
import '../../../core/widgets/picker_sheet.dart';
import '../../../core/widgets/snack.dart';
import '../../counterparties/data/counterparty.dart';
import '../../counterparties/presentation/counterparties_cubit.dart';
import '../../documents/presentation/date_tile.dart';
import '../data/cash_models.dart';
import 'cash_cubit.dart';
import 'counterparty_balance_cubit.dart';

class CashFormPage extends StatefulWidget {
  const CashFormPage({super.key, required this.direction});

  final CashDirection direction;

  @override
  State<CashFormPage> createState() => _CashFormPageState();
}

class _CashFormPageState extends State<CashFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  CashCategoryMeta? _category;
  Counterparty? _counterparty;
  String _date = toApiDate(businessToday());
  bool _saving = false;
  int _counterpartyFieldKey = 0;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _selectCategory(CashCategoryMeta? category) {
    final keepCounterparty = category?.requiresCounterparty ?? false;
    if (!keepCounterparty) {
      context.read<CounterpartyBalanceCubit>().clear();
    }
    setState(() {
      _category = category;
      if (!keepCounterparty) {
        _counterparty = null;
      }
      _counterpartyFieldKey++;
    });
  }

  Future<Counterparty?> _pickCounterparty() {
    return showPickerSheet<Counterparty>(
      context,
      title: 'Kontragent tanlang',
      items: context.read<CounterpartiesCubit>().state.items,
      labelOf: (item) => item.name,
      subtitleOf: (item) => item.type.label,
      emptyMessage: "Kontragentlar yo'q",
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final category = _category!;
    final cash = context.read<CashCubit>();
    final note = _note.text.trim();
    final input = CashInput(
      date: _date,
      category: category.code,
      amount: parseMoney(_amount.text),
      counterpartyId: category.requiresCounterparty ? _counterparty?.id : null,
      note: note.isEmpty ? null : note,
    );
    setState(() => _saving = true);
    final failure = await cash.create(input);
    if (!mounted) return;
    if (failure != null) {
      setState(() => _saving = false);
      await showFailureDialog(context, failure);
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context
        .read<CashCubit>()
        .state
        .categories
        .where(
          (category) =>
              category.manual && category.direction == widget.direction,
        )
        .toList();
    final category = _category;
    final needsCounterparty = category?.requiresCounterparty ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(widget.direction.label)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<CashCategoryMeta>(
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Turkum',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final item in categories)
                    DropdownMenuItem(value: item, child: Text(item.label)),
                ],
                onChanged: _selectCategory,
                validator: (value) =>
                    value == null ? 'Turkumni tanlang' : null,
              ),
              if (needsCounterparty) ...[
                const SizedBox(height: 16),
                PickerFormField<Counterparty>(
                  key: ValueKey(_counterpartyFieldKey),
                  label: 'Kontragent',
                  value: _counterparty,
                  labelOf: (item) => item.name,
                  validator: (value) =>
                      value == null ? 'Kontragentni tanlang' : null,
                  onPick: _pickCounterparty,
                  onChanged: (item) {
                    setState(() => _counterparty = item);
                    context.read<CounterpartyBalanceCubit>().load(item.id);
                  },
                ),
                const SizedBox(height: 8),
                BlocBuilder<CounterpartyBalanceCubit, CounterpartyBalanceState>(
                  builder: (context, state) {
                    if (_counterparty == null) return const SizedBox.shrink();
                    if (state.loading) {
                      return const Text('Joriy balans yuklanmoqda...');
                    }
                    final failure = state.failure;
                    if (failure != null) {
                      return Text(
                        failure.userMessage,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                    final balance = state.balance ?? Decimal.zero;
                    return Row(
                      children: [
                        const Text('Joriy balans: '),
                        Flexible(
                          child: BalanceText(
                            balance: balance,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _amount,
                textInputAction: TextInputAction.next,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [MoneyInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Summa',
                  suffixText: "so'm",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final error = validateMoney(value);
                  if (error != null) return error;
                  if (parseMoney(value!) <= Decimal.zero) {
                    return "Summa 0 dan katta bo'lishi kerak";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DateTile(
                date: _date,
                onChanged: (value) => setState(() => _date = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _note,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Izoh (ixtiyoriy)',
                  border: OutlineInputBorder(),
                ),
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
