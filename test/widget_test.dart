import 'package:catatuang/core/utils/dummy_data.dart';
import 'package:catatuang/features/dashboard/application/dashboard_providers.dart';
import 'package:catatuang/features/dashboard/presentation/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:catatuang/features/category/data/category_repository.dart';
import 'package:catatuang/features/wallet/data/wallet_repository.dart';

import 'package:catatuang/features/transaction/data/transaction_repository.dart';

class MockWalletRepository implements WalletRepository {
  @override
  Future<void> seedDefaultWalletIfEmpty() async {}
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCategoryRepository implements CategoryRepository {
  @override
  Future<void> seedDefaultCategoriesIfEmpty() async {}
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTransactionRepository implements TransactionRepository {
  @override
  Future<void> seedDemoTransactionsIfEmpty() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  testWidgets('DashboardScreen renders without error', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletRepositoryProvider.overrideWithValue(MockWalletRepository()),
          categoryRepositoryProvider.overrideWithValue(MockCategoryRepository()),
          transactionRepositoryProvider.overrideWithValue(MockTransactionRepository()),
          activeWalletsStreamProvider.overrideWith((ref) => Stream.value(DummyData.wallets)),
          activeCategoriesStreamProvider.overrideWith((ref) => Stream.value(DummyData.categories)),
          recentTransactionsStreamProvider.overrideWith((ref) => Stream.value(DummyData.transactions)),
          dashboardSummaryProvider.overrideWith((ref) => Future.value(DummyData.summary)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DashboardScreen()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Catat Uang'), findsOneWidget);
  });
}
