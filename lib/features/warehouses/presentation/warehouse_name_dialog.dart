import 'package:flutter/material.dart';

Future<String?> showWarehouseNameDialog(
  BuildContext context, {
  required String title,
  String initialName = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _WarehouseNameDialog(title: title, initialName: initialName),
  );
}

class _WarehouseNameDialog extends StatefulWidget {
  const _WarehouseNameDialog({required this.title, required this.initialName});

  final String title;
  final String initialName;

  @override
  State<_WarehouseNameDialog> createState() => _WarehouseNameDialogState();
}

class _WarehouseNameDialogState extends State<_WarehouseNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            labelText: 'Nomi',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              (value ?? '').trim().isEmpty ? 'Nomini kiriting' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Saqlash')),
      ],
    );
  }
}
