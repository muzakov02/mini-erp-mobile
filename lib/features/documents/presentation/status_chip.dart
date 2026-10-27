import 'package:flutter/material.dart';

import '../data/document_enums.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final DocumentStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final posted = status == DocumentStatus.posted;
    final background = posted
        ? Colors.green.shade100
        : scheme.surfaceContainerHighest;
    final foreground = posted ? Colors.green.shade900 : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
