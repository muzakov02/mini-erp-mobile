import 'package:flutter/material.dart';

import 'empty_view.dart';

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const EmptyView(message: 'Tez orada', icon: Icons.schedule),
    );
  }
}
