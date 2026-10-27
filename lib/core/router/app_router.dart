import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/counterparties/data/counterparty.dart';
import '../../features/counterparties/presentation/counterparties_page.dart';
import '../../features/counterparties/presentation/counterparty_detail_cubit.dart';
import '../../features/counterparties/presentation/counterparty_detail_page.dart';
import '../../features/counterparties/presentation/counterparty_form_page.dart';
import '../../features/documents/data/document_enums.dart';
import '../../features/documents/presentation/documents_page.dart';
import '../../features/documents/presentation/inventory_form_cubit.dart';
import '../../features/documents/presentation/inventory_form_page.dart';
import '../../features/documents/presentation/trade_form_cubit.dart';
import '../../features/documents/presentation/trade_form_page.dart';
import '../../features/products/data/product.dart';
import '../../features/products/presentation/product_form_page.dart';
import '../../features/stock/presentation/stock_page.dart';
import '../di/injector.dart';
import '../../features/cash/data/cash_models.dart';
import '../../features/cash/presentation/cash_form_page.dart';
import '../../features/cash/presentation/cash_page.dart';
import '../../features/cash/presentation/counterparty_balance_cubit.dart';
import '../../features/reports/presentation/reports_page.dart';
import '../../features/reports/presentation/sales_report_cubit.dart';
import '../../features/reports/presentation/sales_report_page.dart';
import '../../features/reports/presentation/stock_report_cubit.dart';
import '../../features/reports/presentation/stock_report_page.dart';
import 'app_shell.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/reports',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/documents',
                builder: (context, state) => const DocumentsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cash',
                builder: (context, state) => const CashPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stock',
                builder: (context, state) => const StockPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/counterparties',
                builder: (context, state) => const CounterpartiesPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/cash-form/:direction',
        builder: (context, state) {
          final direction = CashDirection.values.firstWhere(
            (item) => item.name == state.pathParameters['direction'],
            orElse: () => CashDirection.income,
          );
          return BlocProvider(
            create: (_) => getIt<CounterpartyBalanceCubit>(),
            child: CashFormPage(direction: direction),
          );
        },
      ),
      GoRoute(
        path: '/sales-report',
        builder: (context, state) {
          final from = state.uri.queryParameters['from'];
          final to = state.uri.queryParameters['to'];
          return BlocProvider(
            create: (_) =>
                getIt<SalesReportCubit>()..load(from: from, to: to),
            child: SalesReportPage(from: from, to: to),
          );
        },
      ),
      GoRoute(
        path: '/stock-report',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<StockReportCubit>()..load(),
          child: const StockReportPage(),
        ),
      ),
      GoRoute(
        path: '/trade-form/:kind',
        builder: (context, state) {
          final kind = TradeKind.fromName(state.pathParameters['kind']);
          final id = int.tryParse(state.uri.queryParameters['id'] ?? '');
          return BlocProvider(
            create: (_) => TradeFormCubit(getIt(), kind)..init(id: id),
            child: TradeFormPage(kind: kind, documentId: id),
          );
        },
      ),
      GoRoute(
        path: '/inventory-form',
        builder: (context, state) {
          final id = int.tryParse(state.uri.queryParameters['id'] ?? '');
          return BlocProvider(
            create: (_) => getIt<InventoryFormCubit>()..init(id: id),
            child: InventoryFormPage(documentId: id),
          );
        },
      ),
      GoRoute(
        path: '/product-form',
        builder: (context, state) =>
            ProductFormPage(product: state.extra as Product?),
      ),
      GoRoute(
        path: '/counterparty-form',
        builder: (context, state) =>
            CounterpartyFormPage(counterparty: state.extra as Counterparty?),
      ),
      GoRoute(
        path: '/counterparties/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return BlocProvider(
            create: (_) => getIt<CounterpartyDetailCubit>()..load(id),
            child: CounterpartyDetailPage(counterpartyId: id),
          );
        },
      ),
    ],
  );
}
