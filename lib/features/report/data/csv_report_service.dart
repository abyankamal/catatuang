import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/currency_formatter.dart';
import 'report_repository.dart';

class CsvReportService {
  static final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFormatter = DateFormat('HH:mm:ss');

  /// Generate CSV Bytes with UTF-8 BOM (\uFEFF) for Excel compatibility (RFC 4180)
  static Future<Uint8List> generateCsvBytes(List<DetailedTransactionItem> transactions) async {
    final rawData = transactions.map((t) => {
      'date': t.date.toIso8601String(),
      'type': t.type,
      'amount': t.amount,
      'walletName': t.walletName,
      'categoryName': t.categoryName,
      'notes': t.notes,
    }).toList();

    String csvString;
    if (kIsWeb || rawData.length < 100) {
      csvString = _buildCsvString(rawData);
    } else {
      // Run CSV generation inside Isolate.run() for large datasets (AGENTS.md §5)
      csvString = await Isolate.run(() => _buildCsvString(rawData));
    }

    // UTF-8 BOM bytes: 0xEF, 0xBB, 0xBF
    final bom = [0xEF, 0xBB, 0xBF];
    final encoded = utf8.encode(csvString);
    return Uint8List.fromList([...bom, ...encoded]);
  }

  static String _buildCsvString(List<Map<String, dynamic>> items) {
    final buffer = StringBuffer();

    // CSV Header (RFC 4180 standard)
    buffer.writeln(
      'Tanggal,Waktu,Tipe Transaksi,Kategori,Dompet,Nominal (Rp),Nominal Terformat,Catatan',
    );

    for (final item in items) {
      final date = DateTime.parse(item['date'] as String);
      final type = item['type'] as String;
      final amount = item['amount'] as double;
      final walletName = item['walletName'] as String;
      final categoryName = item['categoryName'] as String;
      final notes = item['notes'] as String?;

      final typeLabel = _getTypeLabel(type);
      final dateStr = _dateFormatter.format(date);
      final timeStr = _timeFormatter.format(date);
      final rawAmountStr = amount.toStringAsFixed(0);
      final formattedAmountStr = CurrencyFormatter.format(amount);


      final row = [
        _escapeCsvCell(dateStr),
        _escapeCsvCell(timeStr),
        _escapeCsvCell(typeLabel),
        _escapeCsvCell(categoryName),
        _escapeCsvCell(walletName),
        rawAmountStr, // Raw numeric string for Excel formula computation
        _escapeCsvCell(formattedAmountStr),
        _escapeCsvCell(notes ?? ''),
      ];

      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  static String _getTypeLabel(String type) {
    switch (type) {
      case 'INCOME':
        return 'Pemasukan';
      case 'EXPENSE':
        return 'Pengeluaran';
      case 'TRANSFER_OUT':
        return 'Transfer Keluar';
      case 'TRANSFER_IN':
        return 'Transfer Masuk';
      default:
        return type;
    }
  }

  /// Escape string cell according to RFC 4180 rules
  static String _escapeCsvCell(String input) {
    if (input.contains(',') ||
        input.contains('"') ||
        input.contains('\n') ||
        input.contains('\r')) {
      final escaped = input.replaceAll('"', '""');
      return '"$escaped"';
    }
    return input;
  }
}
