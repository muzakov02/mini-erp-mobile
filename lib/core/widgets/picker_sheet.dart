import 'package:flutter/material.dart';

import 'empty_view.dart';

Future<T?> showPickerSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> items,
  required String Function(T item) labelOf,
  String? Function(T item)? subtitleOf,
  String emptyMessage = "Ro'yxat bo'sh",
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PickerSheet<T>(
      title: title,
      items: items,
      labelOf: labelOf,
      subtitleOf: subtitleOf,
      emptyMessage: emptyMessage,
    ),
  );
}

class _PickerSheet<T> extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.items,
    required this.labelOf,
    required this.subtitleOf,
    required this.emptyMessage,
  });

  final String title;
  final List<T> items;
  final String Function(T item) labelOf;
  final String? Function(T item)? subtitleOf;
  final String emptyMessage;

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final visible = query.isEmpty
        ? widget.items
        : widget.items
              .where((item) => widget.labelOf(item).toLowerCase().contains(query))
              .toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Yopish',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Qidirish',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: visible.isEmpty
                  ? EmptyView(message: widget.emptyMessage)
                  : ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final item = visible[index];
                        final subtitle = widget.subtitleOf?.call(item);
                        return ListTile(
                          title: Text(widget.labelOf(item)),
                          subtitle: subtitle == null ? null : Text(subtitle),
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class PickerFormField<T> extends FormField<T> {
  PickerFormField({
    super.key,
    required String label,
    required T? value,
    required String Function(T value) labelOf,
    required Future<T?> Function() onPick,
    required ValueChanged<T> onChanged,
    super.validator,
    super.enabled,
  }) : super(
         initialValue: value,
         builder: (field) {
           final current = field.value;
           return InkWell(
             borderRadius: BorderRadius.circular(4),
             onTap: field.widget.enabled
                 ? () async {
                     final picked = await onPick();
                     if (picked != null) {
                       field.didChange(picked);
                       onChanged(picked);
                     }
                   }
                 : null,
             child: InputDecorator(
               isEmpty: current == null,
               decoration: InputDecoration(
                 labelText: label,
                 errorText: field.errorText,
                 border: const OutlineInputBorder(),
                 suffixIcon: const Icon(Icons.arrow_drop_down),
               ),
               child: Text(
                 current == null ? '' : labelOf(current),
                 maxLines: 2,
                 overflow: TextOverflow.ellipsis,
               ),
             ),
           );
         },
       );
}
