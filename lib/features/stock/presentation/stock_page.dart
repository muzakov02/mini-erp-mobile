import 'package:flutter/material.dart';

import '../../products/presentation/products_tab.dart';
import '../../warehouses/presentation/warehouses_tab.dart';

class StockPage extends StatelessWidget {
  const StockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ombor'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mahsulotlar'),
              Tab(text: 'Omborlar'),
            ],
          ),
        ),
        body: const TabBarView(children: [ProductsTab(), WarehousesTab()]),
      ),
    );
  }
}
