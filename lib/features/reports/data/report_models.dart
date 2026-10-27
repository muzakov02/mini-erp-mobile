import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import '../../../core/models/stock_qty.dart';
import '../../../core/network/json_helpers.dart';

class PnlReport extends Equatable {
  const PnlReport({
    required this.revenue,
    required this.cogs,
    required this.grossProfit,
    required this.otherIncome,
    required this.expenseTransport,
    required this.expenseRent,
    required this.expenseOther,
    required this.expenseTotal,
    required this.inventoryShortage,
    required this.inventorySurplus,
    required this.inventoryTotal,
    required this.netProfit,
    required this.excluded,
  });

  final Decimal revenue;
  final Decimal cogs;
  final Decimal grossProfit;
  final Decimal otherIncome;
  final Decimal expenseTransport;
  final Decimal expenseRent;
  final Decimal expenseOther;
  final Decimal expenseTotal;
  final Decimal inventoryShortage;
  final Decimal inventorySurplus;
  final Decimal inventoryTotal;
  final Decimal netProfit;
  final ExcludedFromPnl excluded;

  factory PnlReport.fromJson(Map<String, dynamic> json) {
    final expenses = json['expenses'] as Map<String, dynamic>;
    final inventory = json['inventoryDiff'] as Map<String, dynamic>;
    return PnlReport(
      revenue: jsonDecimal(json['revenue']),
      cogs: jsonDecimal(json['cogs']),
      grossProfit: jsonDecimal(json['grossProfit']),
      otherIncome: jsonDecimal(json['otherIncome']),
      expenseTransport: jsonDecimal(expenses['transport']),
      expenseRent: jsonDecimal(expenses['rent']),
      expenseOther: jsonDecimal(expenses['other']),
      expenseTotal: jsonDecimal(expenses['total']),
      inventoryShortage: jsonDecimal(inventory['shortage']),
      inventorySurplus: jsonDecimal(inventory['surplus']),
      inventoryTotal: jsonDecimal(inventory['total']),
      netProfit: jsonDecimal(json['netProfit']),
      excluded: ExcludedFromPnl.fromJson(
        json['excludedFromPnl'] as Map<String, dynamic>,
      ),
    );
  }

  @override
  List<Object?> get props => [
    revenue,
    cogs,
    grossProfit,
    otherIncome,
    expenseTransport,
    expenseRent,
    expenseOther,
    expenseTotal,
    inventoryShortage,
    inventorySurplus,
    inventoryTotal,
    netProfit,
    excluded,
  ];
}

class ExcludedFromPnl extends Equatable {
  const ExcludedFromPnl({
    required this.customerDebtPayments,
    required this.loansReturned,
    required this.loansTaken,
    required this.loansGiven,
    required this.loansRepaid,
    required this.supplierPayments,
    required this.ownerWithdrawals,
    required this.openingBalance,
    required this.openingStockValue,
  });

  final Decimal customerDebtPayments;
  final Decimal loansReturned;
  final Decimal loansTaken;
  final Decimal loansGiven;
  final Decimal loansRepaid;
  final Decimal supplierPayments;
  final Decimal ownerWithdrawals;
  final Decimal openingBalance;
  final Decimal openingStockValue;

  factory ExcludedFromPnl.fromJson(Map<String, dynamic> json) {
    return ExcludedFromPnl(
      customerDebtPayments: jsonDecimal(json['customerDebtPayments']),
      loansReturned: jsonDecimal(json['loansReturned']),
      loansTaken: jsonDecimal(json['loansTaken']),
      loansGiven: jsonDecimal(json['loansGiven']),
      loansRepaid: jsonDecimal(json['loansRepaid']),
      supplierPayments: jsonDecimal(json['supplierPayments']),
      ownerWithdrawals: jsonDecimal(json['ownerWithdrawals']),
      openingBalance: jsonDecimal(json['openingBalance']),
      openingStockValue: jsonDecimal(json['openingStockValue']),
    );
  }

  @override
  List<Object?> get props => [
    customerDebtPayments,
    loansReturned,
    loansTaken,
    loansGiven,
    loansRepaid,
    supplierPayments,
    ownerWithdrawals,
    openingBalance,
    openingStockValue,
  ];
}

class SalesSummary extends Equatable {
  const SalesSummary({
    required this.count,
    required this.revenue,
    required this.cost,
    required this.grossProfit,
    required this.paid,
    required this.unpaid,
  });

  final int count;
  final Decimal revenue;
  final Decimal cost;
  final Decimal grossProfit;
  final Decimal paid;
  final Decimal unpaid;

  factory SalesSummary.fromJson(Map<String, dynamic> json) {
    return SalesSummary(
      count: (json['count'] as num).toInt(),
      revenue: jsonDecimal(json['revenue']),
      cost: jsonDecimal(json['cost']),
      grossProfit: jsonDecimal(json['grossProfit']),
      paid: jsonDecimal(json['paid']),
      unpaid: jsonDecimal(json['unpaid']),
    );
  }

  @override
  List<Object?> get props => [count, revenue, cost, grossProfit, paid, unpaid];
}

class SalesProductRow extends Equatable {
  const SalesProductRow({
    required this.productId,
    required this.name,
    required this.qty,
    required this.revenue,
    required this.cost,
    required this.grossProfit,
  });

  final int productId;
  final String name;
  final StockQty qty;
  final Decimal revenue;
  final Decimal cost;
  final Decimal grossProfit;

  factory SalesProductRow.fromJson(Map<String, dynamic> json) {
    return SalesProductRow(
      productId: (json['productId'] as num).toInt(),
      name: json['name'] as String,
      qty: StockQty.fromJson(json['qty'] as Map<String, dynamic>),
      revenue: jsonDecimal(json['revenue']),
      cost: jsonDecimal(json['cost']),
      grossProfit: jsonDecimal(json['grossProfit']),
    );
  }

  @override
  List<Object?> get props => [productId, name, qty, revenue, cost, grossProfit];
}

class SalesDocumentRow extends Equatable {
  const SalesDocumentRow({
    required this.id,
    required this.date,
    required this.totalAmount,
    required this.paidAmount,
    required this.unpaid,
    this.counterpartyName,
  });

  final int id;
  final String date;
  final String? counterpartyName;
  final Decimal totalAmount;
  final Decimal paidAmount;
  final Decimal unpaid;

  factory SalesDocumentRow.fromJson(Map<String, dynamic> json) {
    return SalesDocumentRow(
      id: (json['id'] as num).toInt(),
      date: json['date'] as String,
      counterpartyName: json['counterpartyName'] as String?,
      totalAmount: jsonDecimal(json['totalAmount']),
      paidAmount: jsonDecimal(json['paidAmount']),
      unpaid: jsonDecimal(json['unpaid']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    date,
    counterpartyName,
    totalAmount,
    paidAmount,
    unpaid,
  ];
}

class SalesReport extends Equatable {
  const SalesReport({
    required this.summary,
    required this.byProduct,
    required this.documents,
  });

  final SalesSummary summary;
  final List<SalesProductRow> byProduct;
  final List<SalesDocumentRow> documents;

  factory SalesReport.fromJson(Map<String, dynamic> json) {
    return SalesReport(
      summary: SalesSummary.fromJson(json['summary'] as Map<String, dynamic>),
      byProduct: (json['byProduct'] as List<dynamic>)
          .map((item) => SalesProductRow.fromJson(item as Map<String, dynamic>))
          .toList(),
      documents: (json['documents'] as List<dynamic>)
          .map(
            (item) => SalesDocumentRow.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  @override
  List<Object?> get props => [summary, byProduct, documents];
}

class StockLocation extends Equatable {
  const StockLocation({required this.label, required this.qty});

  final String label;
  final StockQty qty;

  factory StockLocation.fromJson(Map<String, dynamic> json) {
    final parent = json['parentName'] as String?;
    final name = json['warehouseName'] as String;
    return StockLocation(
      label: parent == null ? name : '$parent / $name',
      qty: StockQty.fromJson(json['qty'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [label, qty];
}

class StockReportItem extends Equatable {
  const StockReportItem({
    required this.productId,
    required this.name,
    required this.total,
    required this.stockValue,
    required this.locations,
  });

  final int productId;
  final String name;
  final StockQty total;
  final Decimal stockValue;
  final List<StockLocation> locations;

  factory StockReportItem.fromJson(Map<String, dynamic> json) {
    return StockReportItem(
      productId: (json['productId'] as num).toInt(),
      name: json['name'] as String,
      total: StockQty.fromJson(json['total'] as Map<String, dynamic>),
      stockValue: jsonDecimal(json['stockValue']),
      locations: (json['locations'] as List<dynamic>)
          .map((item) => StockLocation.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [productId, name, total, stockValue, locations];
}

class StockReport extends Equatable {
  const StockReport({required this.items, required this.totalStockValue});

  final List<StockReportItem> items;
  final Decimal totalStockValue;

  factory StockReport.fromJson(Map<String, dynamic> json) {
    return StockReport(
      items: (json['items'] as List<dynamic>)
          .map((item) => StockReportItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalStockValue: jsonDecimal(json['totalStockValue']),
    );
  }

  @override
  List<Object?> get props => [items, totalStockValue];
}
