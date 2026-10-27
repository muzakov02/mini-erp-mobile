import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injector.dart';
import 'core/router/app_router.dart';
import 'features/counterparties/presentation/counterparties_cubit.dart';
import 'features/cash/presentation/cash_cubit.dart';
import 'features/documents/presentation/documents_cubit.dart';
import 'features/reports/presentation/reports_cubit.dart';
import 'features/products/presentation/products_cubit.dart';
import 'features/warehouses/presentation/warehouses_cubit.dart';

class MiniErpApp extends StatefulWidget {
  const MiniErpApp({super.key});

  @override
  State<MiniErpApp> createState() => _MiniErpAppState();
}

class _MiniErpAppState extends State<MiniErpApp> {
  late final GoRouter _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ReportsCubit>()..load()),
        BlocProvider(create: (_) => getIt<CashCubit>()..load()),
        BlocProvider(create: (_) => getIt<DocumentsCubit>()..load()),
        BlocProvider(create: (_) => getIt<ProductsCubit>()..load()),
        BlocProvider(create: (_) => getIt<WarehousesCubit>()..load()),
        BlocProvider(create: (_) => getIt<CounterpartiesCubit>()..load()),
      ],
      child: MaterialApp.router(
        title: 'Mini ERP',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.teal,
        ),
        routerConfig: _router,
      ),
    );
  }
}
