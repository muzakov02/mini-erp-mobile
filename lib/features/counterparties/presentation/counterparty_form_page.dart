import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/snack.dart';
import '../data/counterparty.dart';
import 'counterparties_cubit.dart';

class CounterpartyFormPage extends StatefulWidget {
  const CounterpartyFormPage({super.key, this.counterparty});

  final Counterparty? counterparty;

  @override
  State<CounterpartyFormPage> createState() => _CounterpartyFormPageState();
}

class _CounterpartyFormPageState extends State<CounterpartyFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late CounterpartyType _type;
  bool _saving = false;

  bool get _isEdit => widget.counterparty != null;

  @override
  void initState() {
    super.initState();
    final counterparty = widget.counterparty;
    _name = TextEditingController(text: counterparty?.name ?? '');
    _phone = TextEditingController(text: counterparty?.phone ?? '');
    _type = counterparty?.type ?? CounterpartyType.customer;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<CounterpartiesCubit>();
    final phone = _phone.text.trim();
    final input = CounterpartyInput(
      name: _name.text.trim(),
      type: _type,
      phone: phone.isEmpty ? null : phone,
    );
    setState(() => _saving = true);
    final failure = await cubit.save(input, id: widget.counterparty?.id);
    if (!mounted) return;
    if (failure != null) {
      setState(() => _saving = false);
      showFailure(context, failure);
      return;
    }
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Kontragentni tahrirlash' : "Kontragent qo'shish",
        ),
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
                textCapitalization: TextCapitalization.words,
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
                controller: _phone,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefon (ixtiyoriy)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CounterpartyType>(
                initialValue: _type,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Turi',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final type in CounterpartyType.values)
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _type = value);
                  }
                },
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
