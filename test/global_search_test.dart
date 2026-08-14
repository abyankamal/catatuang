import 'package:catatuang/features/category/domain/category.dart';
import 'package:catatuang/features/search/application/search_providers.dart';
import 'package:catatuang/features/search/domain/search_result.dart';
import 'package:catatuang/features/search/presentation/global_search_screen.dart';
import 'package:catatuang/features/transaction/domain/transaction.dart';
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

  group('Global Search Tests', () {
    test('GlobalSearchResult properties and counts calculation', () {
      final mockTx = Transaction()
        ..id = 1
        ..syncId = 'tx_1'
        ..type = 'EXPENSE'
        ..amount = 35000
        ..date = DateTime.now()
        ..walletSyncId = 'w_1'
        ..description = 'Kopi Susu Gula Aren'
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      final mockWallet = Wallet()
        ..id = 1
        ..syncId = 'w_1'
        ..name = 'BCA'
        ..balance = 500000
        ..isActive = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      final mockCategory = Category()
        ..id = 1
        ..syncId = 'c_1'
        ..name = 'Makanan & Minuman'
        ..type = 'EXPENSE'
        ..icon = 'restaurant'
        ..colorValue = 0xFF5D5CFF
        ..isActive = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      final searchResult = GlobalSearchResult(
        query: 'kopi',
        transactions: [
          EnrichedTransactionItem(
            transaction: mockTx,
            wallet: mockWallet,
            category: mockCategory,
          ),
        ],
        debts: const [],
        goals: const [],
        totalIncome: 0,
        totalExpense: 35000,
      );

      expect(searchResult.isEmpty, false);
      expect(searchResult.totalMatchesCount, 1);
      expect(searchResult.totalExpense, 35000);
      expect(searchResult.transactions.first.transaction.description, 'Kopi Susu Gula Aren');
    });

    testWidgets('GlobalSearchScreen renders initial empty search state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GlobalSearchScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Pencarian Cerdas'), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Pengeluaran'), findsOneWidget);
      expect(find.text('Pemasukan'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('Utang/Piutang'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('GlobalSearchScreen renders matched search results', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockTx = Transaction()
        ..id = 1
        ..syncId = 'tx_1'
        ..type = 'EXPENSE'
        ..amount = 50000
        ..date = DateTime.now()
        ..walletSyncId = 'w_1'
        ..description = 'Beli Bensin Pertamax'
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      final mockWallet = Wallet()
        ..id = 1
        ..syncId = 'w_1'
        ..name = 'Dompet Utama'
        ..balance = 1000000
        ..isActive = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      final mockCategory = Category()
        ..id = 1
        ..syncId = 'c_1'
        ..name = 'Transportasi'
        ..type = 'EXPENSE'
        ..icon = 'directions_car'
        ..colorValue = 0xFF5D5CFF
        ..isActive = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      final searchResult = GlobalSearchResult(
        query: 'bensin',
        transactions: [
          EnrichedTransactionItem(
            transaction: mockTx,
            wallet: mockWallet,
            category: mockCategory,
          ),
        ],
        debts: const [],
        goals: const [],
        totalIncome: 0,
        totalExpense: 50000,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            searchFilterProvider.overrideWith(
              (ref) => SearchFilterNotifier()..setQuery('bensin'),
            ),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(searchResult),
            ),
          ],
          child: const MaterialApp(
            home: GlobalSearchScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Beli Bensin Pertamax'), findsOneWidget);
      expect(find.text('1 Transaksi Ditemukan'), findsOneWidget);
      expect(find.text('Dompet Utama'), findsOneWidget);
    });
  });
}
