import 'package:flutter/material.dart';

import '../errors/app_failure.dart';

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void showFailure(BuildContext context, AppFailure failure) {
  showMessage(context, failure.userMessage);
}

Future<void> showFailureDialog(BuildContext context, AppFailure failure) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(
        Icons.error_outline,
        color: Theme.of(dialogContext).colorScheme.error,
      ),
      title: const Text('Amalni bajarib bo\'lmadi'),
      content: SingleChildScrollView(child: Text(failure.userMessage)),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Yopish'),
        ),
      ],
    ),
  );
}
