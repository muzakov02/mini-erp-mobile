import 'package:flutter/material.dart';

import '../state/list_state.dart';
import 'empty_view.dart';
import 'error_view.dart';
import 'loading_view.dart';

class ListStateBody<T> extends StatelessWidget {
  const ListStateBody({
    super.key,
    required this.state,
    required this.onRetry,
    required this.emptyMessage,
    required this.listBuilder,
    this.emptyIcon = Icons.inbox,
  });

  final ListState<T> state;
  final Future<void> Function() onRetry;
  final String emptyMessage;
  final IconData emptyIcon;
  final Widget Function(List<T> items) listBuilder;

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      if (state.status == LoadStatus.loading) {
        return const LoadingView();
      }
      final failure = state.failure;
      if (state.status == LoadStatus.failure && failure != null) {
        return ErrorView(failure: failure, onRetry: onRetry);
      }
      return RefreshIndicator(
        onRefresh: onRetry,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: EmptyView(message: emptyMessage, icon: emptyIcon),
            ),
          ),
        ),
      );
    }

    final failure = state.failure;
    return Column(
      children: [
        if (state.status == LoadStatus.failure && failure != null)
          ErrorBanner(failure: failure, onRetry: onRetry),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRetry,
            child: listBuilder(state.items),
          ),
        ),
      ],
    );
  }
}
