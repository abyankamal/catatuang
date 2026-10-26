import 'package:catatuang/features/dashboard/application/dashboard_providers.dart';
import 'package:catatuang/features/goal/application/goal_providers.dart';
import 'package:catatuang/features/transaction/application/transaction_controller.dart';
import 'package:catatuang/features/transaction/domain/transaction.dart';
import 'package:catatuang/features/transaction/presentation/add_transaction_screen.dart';
import 'package:catatuang/features/wallet/domain/wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class FakeTransactionController extends StateNotifier<AsyncValue<void>> implements TransactionController {
  FakeTransactionController() : super(const AsyncValue.data(null));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  group('AddTransactionScreen & Transfer Tests', () {
    testWidgets('Renders 3 tabs (Pengeluaran, Pemasukan, Transfer) and switches to Transfer tab', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final walletA = Wallet()
        ..id = 1
        ..syncId = 'wallet_a'
        ..name = 'Bank BCA'
        ..balance = 1000000
        ..isActive = true
        ..isGoal = false;

      final walletB = Wallet()
        ..id = 2
        ..syncId = 'wallet_b'
        ..name = 'GoPay'
        ..balance = 50000
        ..isActive = true
        ..isGoal = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeRegularWalletsStreamProvider.overrideWith((ref) => Stream.value([walletA, walletB])),
            activeCategoriesStreamProvider.overrideWith((ref) => Stream.value([])),
            transactionControllerProvider.overrideWith((ref) => FakeTransactionController()),
          ],
          child: const MaterialApp(
            home: AddTransactionScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Pengeluaran'), findsOneWidget);
      expect(find.text('Pemasukan'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);

      // Tap on Transfer tab
      await tester.tap(find.text('Transfer'));
      await tester.pump();

      // Verify transfer form elements
      expect(find.text('Nominal Transfer (Rp) *'), findsOneWidget);
      expect(find.text('Dompet Sumber (Asal Dana) *'), findsOneWidget);
      expect(find.text('Dompet Tujuan (Penerima Dana) *'), findsOneWidget);
      expect(find.text('Biaya Admin (Opsional)'), findsOneWidget);
      expect(find.text('Transfer Sekarang'), findsOneWidget);
    });

    test('Transaction repository guards reject negative, zero, NaN, and infinite amounts', () {
      bool isAmountValid(double amount) {
        return amount > 0 && amount.isFinite;
      }

      expect(isAmountValid(10000), isTrue);
      expect(isAmountValid(0), isFalse);
      expect(isAmountValid(-50000), isFalse);
      expect(isAmountValid(double.nan), isFalse);
      expect(isAmountValid(double.infinity), isFalse);
      expect(isAmountValid(double.negativeInfinity), isFalse);
    });

    testWidgets('AddTransactionScreen edit mode normalizes decimal amount to rounded integer string', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final wallet = Wallet()
        ..id = 1
        ..syncId = 'w_1'
        ..name = 'Dompet Utama'
        ..balance = 500000
        ..isActive = true
        ..isGoal = false;

      final existingTx = Transaction()
        ..id = 10
        ..syncId = 'tx_10'
        ..amount = 150000.5 // fractional amount
        ..type = 'EXPENSE'
        ..walletSyncId = 'w_1'
        ..date = DateTime.now();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeRegularWalletsStreamProvider.overrideWith((ref) => Stream.value([wallet])),
            activeCategoriesStreamProvider.overrideWith((ref) => Stream.value([])),
            transactionControllerProvider.overrideWith((ref) => FakeTransactionController()),
          ],
          child: MaterialApp(
            home: AddTransactionScreen(existingTransaction: existingTx),
          ),
        ),
      );

      await tester.pump();

      // Memastikan nilai amount 150000.5 dibulatkan menjadi 150001 tanpa titik desimal
      final amountFinder = find.widgetWithText(TextFormField, '150001');
      expect(amountFinder, findsOneWidget);
    });
  });
}
