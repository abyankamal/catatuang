import 'package:catatuang/features/category/domain/category.dart';
import 'package:catatuang/features/dashboard/application/dashboard_providers.dart';
import 'package:catatuang/features/goal/application/goal_providers.dart';
import 'package:catatuang/features/transaction/application/recurring_transaction_controller.dart';
import 'package:catatuang/features/transaction/application/transaction_controller.dart';
import 'package:catatuang/features/transaction/domain/recurring_transaction.dart';
import 'package:catatuang/features/transaction/domain/transaction.dart';
import 'package:catatuang/features/transaction/presentation/add_transaction_screen.dart';
import 'package:catatuang/features/transaction/presentation/widgets/recurring_interval_picker.dart';
import 'package:catatuang/features/wallet/domain/wallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class FakeRecurringTransactionController
    extends StateNotifier<AsyncValue<void>>
    implements RecurringTransactionController {
  FakeRecurringTransactionController() : super(const AsyncValue.data(null));

  RecurringTransaction? createdRecurring;
  String? confirmedSyncId;
  DateTime? confirmedExecutionDate;

  @override
  bool get isProcessingAutoRecurring => false;

  @override
  Future<RecurringTransaction?> createRecurring({
    required String type,
    required double amount,
    required String walletSyncId,
    required String frequency,
    int interval = 1,
    required DateTime startDate,
    DateTime? endDate,
    int? maxOccurrences,
    String? description,
    String? categorySyncId,
    String? targetWalletSyncId,
    double? adminFee,
    bool autoExecute = false,
  }) async {
    final rec = RecurringTransaction()
      ..syncId = 'rec_test_sync_id'
      ..type = type
      ..amount = amount
      ..walletSyncId = walletSyncId
      ..frequency = frequency
      ..interval = interval
      ..startDate = startDate
      ..endDate = endDate
      ..description = description
      ..categorySyncId = categorySyncId
      ..targetWalletSyncId = targetWalletSyncId
      ..adminFee = adminFee
      ..autoExecute = autoExecute
      ..isActive = true
      ..nextDueDate = startDate;
    createdRecurring = rec;
    return rec;
  }

  @override
  Future<bool> confirmExecution(
    String syncId, {
    DateTime? executionDate,
    double? customAmount,
  }) async {
    confirmedSyncId = syncId;
    confirmedExecutionDate = executionDate;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTransactionController extends StateNotifier<AsyncValue<void>>
    implements TransactionController {
  FakeTransactionController() : super(const AsyncValue.data(null));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  final testWallet = Wallet()
    ..id = 1
    ..syncId = 'wallet_main'
    ..name = 'Dompet Utama'
    ..balance = 1000000
    ..isActive = true
    ..isGoal = false;

  final testCategory = Category()
    ..id = 1
    ..syncId = 'cat_food'
    ..name = 'Makanan'
    ..type = 'EXPENSE'
    ..isActive = true;

  group('AddTransactionScreen - Recurring Option Visibility & UI State', () {
    testWidgets(
        'Recurring toggle is hidden when existingTransaction != null (isEditMode)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final existingTx = Transaction()
        ..syncId = 'tx_1'
        ..type = 'EXPENSE'
        ..amount = 50000
        ..walletSyncId = 'wallet_main'
        ..date = DateTime.now();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeRegularWalletsStreamProvider
                .overrideWith((ref) => Stream.value([testWallet])),
            activeCategoriesStreamProvider
                .overrideWith((ref) => Stream.value([testCategory])),
            transactionControllerProvider
                .overrideWith((ref) => FakeTransactionController()),
            recurringTransactionControllerProvider
                .overrideWith((ref) => FakeRecurringTransactionController()),
          ],
          child: MaterialApp(
            home: AddTransactionScreen(existingTransaction: existingTx),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(RecurringIntervalPicker), findsNothing);
      expect(find.text('Jadikan Transaksi Berulang'), findsNothing);
      expect(find.text('Simpan Transaksi'), findsOneWidget);
    });

    testWidgets(
        'Recurring toggle is visible for new transaction and expands frequency options when toggled',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeRegularWalletsStreamProvider
                .overrideWith((ref) => Stream.value([testWallet])),
            activeCategoriesStreamProvider
                .overrideWith((ref) => Stream.value([testCategory])),
            transactionControllerProvider
                .overrideWith((ref) => FakeTransactionController()),
            recurringTransactionControllerProvider
                .overrideWith((ref) => FakeRecurringTransactionController()),
          ],
          child: const MaterialApp(
            home: AddTransactionScreen(),
          ),
        ),
      );

      await tester.pump();

      // Recurring picker should be present in inactive state
      expect(find.byType(RecurringIntervalPicker), findsOneWidget);
      expect(find.text('Jadikan Transaksi Berulang'), findsOneWidget);
      expect(find.text('Frekuensi Pengulangan'), findsNothing);
      expect(find.text('Simpan Transaksi'), findsOneWidget);

      // Scroll to recurring section if needed and toggle switch
      await tester.ensureVisible(find.byType(Switch).first);
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      // Should now show recurring configuration options
      expect(find.text('Frekuensi Pengulangan'), findsOneWidget);
      expect(find.text('Harian'), findsOneWidget);
      expect(find.text('Mingguan'), findsOneWidget);
      expect(find.text('Bulanan'), findsOneWidget);
      expect(find.text('Tahunan'), findsOneWidget);
      expect(find.text('Konfirmasi Manual'), findsOneWidget);
      expect(find.text('Simpan Transaksi Rutin'), findsOneWidget);
    });
  });

  group('AddTransactionScreen - Anti-Double Charge & Future Scheduling Logic', () {
    testWidgets(
        'Same-day recurring start date triggers immediate cycle 1 execution (Anti-Double Charge)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeRecurringController = FakeRecurringTransactionController();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeRegularWalletsStreamProvider
                .overrideWith((ref) => Stream.value([testWallet])),
            activeCategoriesStreamProvider
                .overrideWith((ref) => Stream.value([testCategory])),
            transactionControllerProvider
                .overrideWith((ref) => FakeTransactionController()),
            recurringTransactionControllerProvider
                .overrideWith((ref) => fakeRecurringController),
          ],
          child: const MaterialApp(
            home: AddTransactionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Fill in nominal: 150000
      final amountField = find.byType(TextFormField).first;
      await tester.enterText(amountField, '150000');
      await tester.pumpAndSettle();

      // Turn on recurring toggle
      await tester.ensureVisible(find.byType(Switch).first);
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      // Submit form
      final submitButton = find.text('Simpan Transaksi Rutin');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify recurring schedule created
      expect(fakeRecurringController.createdRecurring, isNotNull);
      expect(fakeRecurringController.createdRecurring!.amount, 150000);
      expect(fakeRecurringController.createdRecurring!.frequency, 'MONTHLY');

      // Verify immediate first cycle execution called (Anti-Double Charge)
      expect(fakeRecurringController.confirmedSyncId, 'rec_test_sync_id');
      expect(fakeRecurringController.confirmedExecutionDate, isNotNull);

      // Verify user feedback SnackBar
      expect(
        find.text('Transaksi rutin berhasil dibuat dan dicatat untuk hari ini.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'Future recurring start date schedules without executing cycle 1 today',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeRecurringController = FakeRecurringTransactionController();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeRegularWalletsStreamProvider
                .overrideWith((ref) => Stream.value([testWallet])),
            activeCategoriesStreamProvider
                .overrideWith((ref) => Stream.value([testCategory])),
            transactionControllerProvider
                .overrideWith((ref) => FakeTransactionController()),
            recurringTransactionControllerProvider
                .overrideWith((ref) => fakeRecurringController),
          ],
          child: const MaterialApp(
            home: AddTransactionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Fill in nominal: 250000
      final amountField = find.byType(TextFormField).first;
      await tester.enterText(amountField, '250000');
      await tester.pumpAndSettle();

      // Turn on recurring toggle
      await tester.ensureVisible(find.byType(Switch).first);
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      // Tap on DatePicker to pick future date
      await tester.ensureVisible(find.byIcon(Icons.calendar_today_rounded));
      await tester.tap(find.byIcon(Icons.calendar_today_rounded));
      await tester.pumpAndSettle();

      // Verify helpText reflects recurring mode
      expect(find.text('Pilih Tanggal Mulai Transaksi Rutin'), findsOneWidget);

      // Navigate to next month in date picker dialog
      final nextMonthBtn = find.byTooltip('Next month');
      if (nextMonthBtn.evaluate().isNotEmpty) {
        await tester.tap(nextMonthBtn);
        await tester.pumpAndSettle();
      }
      // Tap day 15 and confirm OK on DatePicker
      await tester.tap(find.text('15').first, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // For non-today date, showTimePicker is opened automatically; tap OK to confirm time
      if (find.text('OK').evaluate().isNotEmpty) {
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      }

      // Submit form
      final submitButton = find.text('Simpan Transaksi Rutin');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify recurring schedule created
      expect(fakeRecurringController.createdRecurring, isNotNull);
      expect(fakeRecurringController.createdRecurring!.amount, 250000);
      expect(
        fakeRecurringController.createdRecurring!.startDate.isAfter(DateTime.now()),
        isTrue,
      );

      // Verify cycle 1 execution was NOT called because start date is in future
      expect(fakeRecurringController.confirmedSyncId, isNull);

      // Verify user feedback SnackBar
      expect(
        find.text('Jadwal transaksi rutin berhasil didaftarkan.'),
        findsOneWidget,
      );
    });
  });
}
