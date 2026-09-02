import 'dart:convert';
import 'package:catatuang/features/report/data/csv_report_service.dart';
import 'package:catatuang/features/report/data/report_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CSV Export Tests', () {
    test('CsvReportService generates valid CSV with UTF-8 BOM', () async {
      final transactions = [
        DetailedTransactionItem(
          date: DateTime(2026, 8, 14, 10, 30, 0),
          type: 'EXPENSE',
          amount: 50000,
          walletName: 'BCA Utama',
          categoryName: 'Makanan & Minuman',
          notes: 'Makan siang nasi padang',
        ),
        DetailedTransactionItem(
          date: DateTime(2026, 8, 14, 14, 0, 0),
          type: 'INCOME',
          amount: 5000000,
          walletName: 'Mandiri',
          categoryName: 'Gaji',
          notes: 'Gaji bulanan',
        ),
      ];

      final csvBytes = await CsvReportService.generateCsvBytes(transactions);

      // Verify UTF-8 BOM (0xEF, 0xBB, 0xBF)
      expect(csvBytes.length, greaterThan(3));
      expect(csvBytes[0], 0xEF);
      expect(csvBytes[1], 0xBB);
      expect(csvBytes[2], 0xBF);

      // Decode CSV string after BOM
      final csvString = utf8.decode(csvBytes.sublist(3));

      // Verify header columns
      expect(
        csvString.contains(
          'Tanggal,Waktu,Tipe Transaksi,Kategori,Dompet,Nominal (Rp),Nominal Terformat,Catatan',
        ),
        true,
      );

      // Verify rows
      expect(csvString.contains('2026-08-14'), true);
      expect(csvString.contains('Pengeluaran'), true);
      expect(csvString.contains('Makanan & Minuman'), true);
      expect(csvString.contains('50000'), true);
      expect(csvString.contains('Pemasukan'), true);
      expect(csvString.contains('5000000'), true);
      expect(csvString.contains('Makan siang nasi padang'), true);
    });

    test('CsvReportService properly escapes commas, quotes, and newlines in notes (RFC 4180)', () async {
      final transactions = [
        DetailedTransactionItem(
          date: DateTime(2026, 8, 14, 15, 0, 0),
          type: 'EXPENSE',
          amount: 75000,
          walletName: 'Cash',
          categoryName: 'Belanja, Supermarket', // comma in category
          notes: 'Beli "Kopi", Teh,\ndan Gula', // comma, quote, newline
        ),
      ];

      final csvBytes = await CsvReportService.generateCsvBytes(transactions);
      final csvString = utf8.decode(csvBytes.sublist(3));

      // Comma in category should be wrapped in double quotes
      expect(csvString.contains('"Belanja, Supermarket"'), true);

      // Double quotes in notes should be escaped as "" and wrapped in quotes
      expect(csvString.contains('"Beli ""Kopi"", Teh,\ndan Gula"'), true);
    });

    test('CsvReportService neutralizes CSV Formula Injection attempts (CWE-1236)', () async {
      final transactions = [
        DetailedTransactionItem(
          date: DateTime(2026, 8, 14, 16, 0, 0),
          type: 'EXPENSE',
          amount: 100000,
          walletName: '=WalletDDE()',
          categoryName: '@CategoryMacro',
          notes: '=SUM(1+1)*cmd|/C calc!A0',
        ),
        DetailedTransactionItem(
          date: DateTime(2026, 8, 14, 16, 5, 0),
          type: 'INCOME',
          amount: 250000,
          walletName: '+BonusWallet',
          categoryName: '-DeductionCat',
          notes: '\tTabLeadingNote',
        ),
      ];

      final csvBytes = await CsvReportService.generateCsvBytes(transactions);
      final csvString = utf8.decode(csvBytes.sublist(3));

      // Formula characters must be sanitized with leading single quote
      expect(csvString.contains("'=WalletDDE()"), true);
      expect(csvString.contains("'@CategoryMacro"), true);
      expect(csvString.contains("''=SUM(1+1)*cmd|/C calc!A0"), false); // properly sanitized
      expect(csvString.contains("'+BonusWallet"), true);
      expect(csvString.contains("'-DeductionCat"), true);
      expect(csvString.contains("'\tTabLeadingNote"), true);
    });
  });
}
