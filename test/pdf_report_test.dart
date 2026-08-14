import 'dart:typed_data';

import 'package:catatuang/features/report/application/report_providers.dart';
import 'package:catatuang/features/report/data/pdf_report_service.dart';
import 'package:catatuang/features/report/data/report_repository.dart';
import 'package:catatuang/features/report/presentation/report_screen.dart';
import 'package:catatuang/features/wallet/domain/wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  group('PDF Financial Report Export Tests', () {
    test('PdfReportService.generatePdf produces valid non-empty PDF bytes with %PDF header', () async {
      final summary = MonthlyReportData(
        totalIncome: 10000000,
        totalExpense: 4000000,
        netIncome: 6000000,
        categoryExpenses: const [
          CategoryExpenseSummary(
            categorySyncId: 'cat_food',
            categoryName: 'Makanan & Minuman',
            categoryIcon: 'restaurant',
            categoryColor: 0xFFFF5722,
            totalAmount: 2500000,
            percentage: 62.5,
          ),
          CategoryExpenseSummary(
            categorySyncId: 'cat_transport',
            categoryName: 'Transportasi',
            categoryIcon: 'directions_car',
            categoryColor: 0xFF2196F3,
            totalAmount: 1500000,
            percentage: 37.5,
          ),
        ],
        categoryIncomes: const [
          CategoryExpenseSummary(
            categorySyncId: 'cat_salary',
            categoryName: 'Gaji',
            categoryIcon: 'attach_money',
            categoryColor: 0xFF4CAF50,
            totalAmount: 10000000,
            percentage: 100.0,
          ),
        ],
      );

      final wallet = Wallet()
        ..id = 1
        ..syncId = 'wallet_bca'
        ..name = 'Bank BCA'
        ..balance = 15000000
        ..isActive = true
        ..isGoal = false;

      final detailedReport = DetailedMonthlyReport(
        year: 2026,
        month: 8,
        userName: 'Abyan',
        summary: summary,
        wallets: [wallet],
        transactions: [
          DetailedTransactionItem(
            date: DateTime(2026, 8, 14, 12, 0),
            type: 'EXPENSE',
            amount: 50000,
            walletName: 'Bank BCA',
            categoryName: 'Makanan & Minuman',
            notes: 'Makan siang',
          ),
          DetailedTransactionItem(
            date: DateTime(2026, 8, 1, 9, 0),
            type: 'INCOME',
            amount: 10000000,
            walletName: 'Bank BCA',
            categoryName: 'Gaji',
            notes: 'Gaji bulanan',
          ),
        ],
      );

      final Uint8List pdfBytes = await PdfReportService.generatePdf(detailedReport);

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(500));

      // Check %PDF magic header
      final header = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(header, '%PDF-');
    });

    testWidgets('ReportScreen displays Export PDF action button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final summary = MonthlyReportData(
        totalIncome: 5000000,
        totalExpense: 2000000,
        netIncome: 3000000,
        categoryExpenses: const [
          CategoryExpenseSummary(
            categorySyncId: 'cat_bills',
            categoryName: 'Tagihan Listrik',
            categoryIcon: 'receipt',
            categoryColor: 0xFF9C27B0,
            totalAmount: 2000000,
            percentage: 100.0,
          ),
        ],
        categoryIncomes: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            monthlyReportProvider.overrideWith((ref) => Future.value(summary)),
          ],
          child: const MaterialApp(
            home: ReportScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Laporan & Grafik'), findsOneWidget);
      expect(find.byIcon(Icons.share_rounded), findsOneWidget); // Ekspor action button di AppBar
    });
  });
}
