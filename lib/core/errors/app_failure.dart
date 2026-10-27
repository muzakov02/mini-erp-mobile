import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

import '../format/formatters.dart';

class AppFailure extends Equatable implements Exception {
  const AppFailure({
    required this.code,
    required this.message,
    this.details,
    this.statusCode,
  });

  static const String networkCode = 'NETWORK_ERROR';
  static const String unknownCode = 'UNKNOWN_ERROR';

  final String code;
  final String message;
  final Map<String, dynamic>? details;
  final int? statusCode;

  const AppFailure.unknown()
    : code = unknownCode,
      message = 'Unknown error',
      details = null,
      statusCode = null;

  factory AppFailure.fromDioException(DioException exception) {
    final data = exception.response?.data;
    if (data is Map && data['code'] is String) {
      final rawDetails = data['details'];
      return AppFailure(
        code: data['code'] as String,
        message: (data['message'] ?? '').toString(),
        details: rawDetails is Map
            ? Map<String, dynamic>.from(rawDetails)
            : null,
        statusCode: exception.response?.statusCode,
      );
    }
    if (exception.response == null) {
      return AppFailure(
        code: networkCode,
        message: exception.message ?? 'Network error',
      );
    }
    return AppFailure(
      code: unknownCode,
      message: exception.message ?? 'Unknown error',
      statusCode: exception.response?.statusCode,
    );
  }

  String get userMessage {
    switch (code) {
      case 'VALIDATION_ERROR':
        return _validationMessage();
      case 'NOT_FOUND':
        return _notFoundMessage();
      case 'DUPLICATE':
        return 'Bunday yozuv allaqachon mavjud';
      case 'REFERENCE_ERROR':
        return "Yozuv boshqa ma'lumotlar bilan bog'langan, amalni bajarib bo'lmaydi";
      case 'DOCUMENT_NOT_DRAFT':
        return _notDraftMessage();
      case 'INSUFFICIENT_STOCK':
        return _insufficientStockMessage();
      case 'INSUFFICIENT_CASH':
        return _insufficientCashMessage();
      case 'OVERPAYMENT':
        return _overpaymentMessage();
      case 'COUNTERPARTY_REQUIRED':
        return _counterpartyRequiredMessage();
      case 'OPENING_STOCK_EXISTS':
        return _openingStockMessage();
      case 'INVALID_WAREHOUSE_LEVEL':
        return "Sub-ombor ichida yana sub-ombor yaratib bo'lmaydi";
      case 'HAS_STOCK':
        return _hasStockMessage();
      case 'HAS_BALANCE':
        return _hasBalanceMessage();
      case 'ARCHIVED_ENTITY':
        return _archivedMessage();
      case networkCode:
        return "Serverga ulanib bo'lmadi. Internet va server manzilini tekshirib, qayta urinib ko'ring";
      default:
        return 'Kutilmagan xatolik yuz berdi. Keyinroq qayta urinib ko\'ring';
    }
  }

  static const Map<String, String> _entityNames = {
    'Product': 'mahsulot',
    'Warehouse': 'ombor',
    'Counterparty': 'kontragent',
  };

  List<Map<String, dynamic>> _detailItems() {
    final raw = details?['items'];
    if (raw is! List) {
      return const [];
    }
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _units(Object? value) {
    return value is num ? '${formatInt(value.toInt())} dona' : '?';
  }

  String? _money(Object? value) {
    final parsed = value is String ? Decimal.tryParse(value) : null;
    return parsed == null ? null : formatMoney(parsed);
  }

  String _entityLabel() {
    final entity = details?['entity'];
    return entity is String ? _entityNames[entity] ?? 'yozuv' : 'yozuv';
  }

  String _idList() {
    final ids = details?['ids'];
    return ids is List ? ids.join(', ') : '';
  }

  String _validationMessage() {
    if (details?['paidAmount'] != null && details?['totalAmount'] != null) {
      return "To'langan summa jami summadan oshmasligi kerak";
    }
    if (details?['items'] is List) {
      return "Qatorlardagi tannarx noto'g'ri: boshlang'ich inventarizatsiyada har qatorga tannarx kiritiladi, oddiy inventarizatsiyada kiritilmaydi";
    }
    return "Kiritilgan ma'lumotlar noto'g'ri. Maydonlarni tekshiring";
  }

  String _notFoundMessage() {
    if (details?['entity'] is String) {
      final ids = _idList();
      final suffix = ids.isEmpty ? '' : ' (ID: $ids)';
      return 'Tanlangan ${_entityLabel()} topilmadi$suffix';
    }
    return 'Yozuv topilmadi';
  }

  String _notDraftMessage() {
    if (details?['status'] == 'POSTED') {
      return "Hujjat allaqachon bajarilgan, uni o'zgartirib yoki o'chirib bo'lmaydi";
    }
    return "Hujjat qoralama holatida emas, o'zgartirib bo'lmaydi";
  }

  String _insufficientStockMessage() {
    final items = _detailItems();
    if (items.isEmpty) {
      return 'Omborda mahsulot yetarli emas';
    }
    final lines = items.map(
      (item) =>
          '• ${item['productName']} (${item['warehouseName']}): mavjud ${_units(item['available'])}, kerak ${_units(item['requested'])}',
    );
    return "Omborda mahsulot yetarli emas:\n${lines.join('\n')}";
  }

  String _insufficientCashMessage() {
    final balance = _money(details?['balance']);
    final required = _money(details?['required']);
    if (balance == null || required == null) {
      return "Kassada mablag' yetarli emas";
    }
    return "Kassada mablag' yetarli emas.\nKassa qoldig'i: $balance\nKerakli summa: $required";
  }

  String _overpaymentMessage() {
    final amount = _money(details?['amount']);
    final rawBalance = details?['balance'];
    final balance = rawBalance is String ? Decimal.tryParse(rawBalance) : null;
    if (amount == null || balance == null) {
      return "To'lov summasi qarzdan oshib ketdi";
    }
    return "To'lov summasi ($amount) kontragent qarzidan oshib ketdi.\nKontragent balansi: ${formatBalance(balance)}";
  }

  String _counterpartyRequiredMessage() {
    final unpaid = _money(details?['unpaidAmount']);
    if (unpaid == null) {
      if (details?['category'] != null) {
        return 'Bu turkum uchun kontragent tanlanishi shart';
      }
      return "To'lanmagan qism bor, kontragent tanlanishi shart";
    }
    return "To'lanmagan qism bor ($unpaid), shuning uchun kontragent tanlanishi shart";
  }

  String _openingStockMessage() {
    final items = _detailItems();
    if (items.isEmpty) {
      return "Bu omborda boshlang'ich qoldiq allaqachon kiritilgan";
    }
    final lines = items.map(
      (item) => '• ${item['productName']}: ${_units(item['expectedQty'])}',
    );
    return "Bu omborda quyidagi mahsulotlar bo'yicha qoldiq allaqachon bor, boshlang'ich inventarizatsiya mumkin emas:\n${lines.join('\n')}";
  }

  String _archivedMessage() {
    if (details?['entity'] is String) {
      final ids = _idList();
      final suffix = ids.isEmpty ? '' : ' (ID: $ids)';
      return 'Arxivlangan ${_entityLabel()} ishlatilgan$suffix. Boshqasini tanlang';
    }
    return "Arxivlangan yozuv bilan amalni bajarib bo'lmaydi";
  }

  String _hasStockMessage() {
    final reason = details?['reason'];
    if (reason == 'HAS_ACTIVE_CHILDREN') {
      return "Omborda faol sub-omborlar bor. Avval ularni arxivlang";
    }
    if (reason == 'WAREHOUSE_HAS_STOCK') {
      return "Omborda mahsulot qoldig'i bor, arxivlab bo'lmaydi";
    }
    final qty = details?['qty'];
    if (qty is num) {
      return "Mahsulot qoldig'i bor (${formatInt(qty.toInt())} dona), arxivlab bo'lmaydi";
    }
    return "Qoldiq bor, arxivlab bo'lmaydi";
  }

  String _hasBalanceMessage() {
    final balance = _money(details?['balance']);
    if (balance == null) {
      return "Kontragentning hisob-kitobi nolga teng emas, arxivlab bo'lmaydi";
    }
    return "Kontragentda hisob-kitob qoldig'i bor ($balance), arxivlab bo'lmaydi";
  }

  @override
  List<Object?> get props => [code, message, details, statusCode];
}
