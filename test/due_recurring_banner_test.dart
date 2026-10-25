import 'package:catatuang/features/dashboard/presentation/widgets/due_recurring_banner.dart';
import 'package:catatuang/features/transaction/application/recurring_transaction_controller.dart';
import 'package:catatuang/features/transaction/domain/recurring_transaction.dart';
import 'package:catatuang/features/transaction/presentation/widgets/confirm_recurring_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class TestRecurringTransactionController extends StateNotifier<AsyncValue<void>>
    implements RecurringTransactionController {
  String? confirmedSyncId;
  double? confirmedAmount;
  String? skippedSyncId;

  TestRecurringTransactionController() : super(const AsyncValue.data(null));

  @override
  bool get isProcessingAutoRecurring => false;

  @override
  Future<bool> confirmExecution(
    String syncId, {
    DateTime? executionDate,
    double? customAmount,
  }) async {
    confirmedSyncId = syncId;
    confirmedAmount = customAmount;
    return true;
  }

  @override
  Future<bool> skipCurrentCycle(String syncId) async {
    skippedSyncId = syncId;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  group('DueRecurringBanner Widget Tests', () {
    testWidgets('renders SizedBox.shrink when no due recurring transactions exist', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dueManualRecurringProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DueRecurringBanner(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(DueRecurringBanner), findsOneWidget);
      expect(find.text('Jadwal Rutin Jatuh Tempo'), findsNothing);
      expect(find.text('Catat Sekarang'), findsNothing);
    });

    testWidgets('renders banner with due item details, amount, and buttons', (tester) async {
      final now = DateTime.now();
      final recurring = RecurringTransaction()
        ..syncId = 'rec_wifi_1'
        ..type = 'EXPENSE'
        ..amount = 350000
        ..walletSyncId = 'wallet_bca'
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = now.subtract(const Duration(days: 30))
        ..nextDueDate = now
        ..autoExecute = false
        ..isActive = true
        ..description = 'Tagihan Wi-Fi Rumah'
        ..createdAt = now
        ..updatedAt = now;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dueManualRecurringProvider.overrideWith((ref) => Future.value([recurring])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DueRecurringBanner(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Jadwal Rutin Jatuh Tempo'), findsOneWidget);
      expect(find.text('HARI INI'), findsOneWidget);
      expect(find.text('Tagihan Wi-Fi Rumah'), findsOneWidget);
      expect(find.text('Rp 350.000'), findsOneWidget);
      expect(find.text('Catat Sekarang'), findsOneWidget);
      expect(find.text('Lewati'), findsOneWidget);
    });

    testWidgets('renders TERLEWAT badge when nextDueDate is in the past', (tester) async {
      final pastDate = DateTime.now().subtract(const Duration(days: 3));
      final recurring = RecurringTransaction()
        ..syncId = 'rec_overdue'
        ..type = 'EXPENSE'
        ..amount = 120000
        ..walletSyncId = 'wallet_bca'
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = pastDate
        ..nextDueDate = pastDate
        ..autoExecute = false
        ..isActive = true
        ..description = 'Gym Bulanan'
        ..createdAt = pastDate
        ..updatedAt = pastDate;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dueManualRecurringProvider.overrideWith((ref) => Future.value([recurring])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DueRecurringBanner(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('TERLEWAT'), findsOneWidget);
      expect(find.text('Gym Bulanan'), findsOneWidget);
    });

    testWidgets('tapping Lewati button directly on card calls skipCurrentCycle', (tester) async {
      final now = DateTime.now();
      final recurring = RecurringTransaction()
        ..syncId = 'rec_skip_direct'
        ..type = 'EXPENSE'
        ..amount = 75000
        ..walletSyncId = 'wallet_bca'
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = now
        ..nextDueDate = now
        ..autoExecute = false
        ..isActive = true
        ..description = 'Langganan Majalah'
        ..createdAt = now
        ..updatedAt = now;

      final mockController = TestRecurringTransactionController();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dueManualRecurringProvider.overrideWith((ref) => Future.value([recurring])),
            recurringTransactionControllerProvider.overrideWith((ref) => mockController),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DueRecurringBanner(),
            ),
          ),
        ),
      );

      await tester.pump();

      final lewatiBtn = find.widgetWithText(OutlinedButton, 'Lewati');
      expect(lewatiBtn, findsOneWidget);
      await tester.tap(lewatiBtn);
      await tester.pump();

      expect(mockController.skippedSyncId, 'rec_skip_direct');
    });

    testWidgets(
        'tapping Catat Sekarang opens quick edit dialog, adjusts amount, and confirms execution',
        (tester) async {
      final now = DateTime.now();
      final recurring = RecurringTransaction()
        ..syncId = 'rec_pln'
        ..type = 'EXPENSE'
        ..amount = 250000
        ..walletSyncId = 'wallet_bca'
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = now
        ..nextDueDate = now
        ..autoExecute = false
        ..isActive = true
        ..description = 'Tagihan Listrik PLN'
        ..createdAt = now
        ..updatedAt = now;

      final mockController = TestRecurringTransactionController();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dueManualRecurringProvider.overrideWith((ref) => Future.value([recurring])),
            recurringTransactionControllerProvider.overrideWith((ref) => mockController),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DueRecurringBanner(),
            ),
          ),
        ),
      );

      await tester.pump();

      // Tap "Catat Sekarang" on card
      final catatCardBtn = find.widgetWithText(ElevatedButton, 'Catat Sekarang');
      expect(catatCardBtn, findsOneWidget);
      await tester.tap(catatCardBtn);
      await tester.pump();

      // Verify dialog is shown with prefilled amount
      expect(find.text('Catat Transaksi Rutin'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Tagihan Listrik PLN'),
        ),
        findsOneWidget,
      );
      expect(find.text('250000'), findsOneWidget);

      // Edit amount to 280000
      await tester.enterText(find.byType(TextFormField), '280000');
      await tester.pump();

      // Tap "Catat Sekarang" in dialog
      final catatDialogBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Catat Sekarang'),
      );
      expect(catatDialogBtn, findsOneWidget);
      await tester.tap(catatDialogBtn);
      await tester.pump();

      // Verify controller confirmExecution called with new amount
      expect(mockController.confirmedSyncId, 'rec_pln');
      expect(mockController.confirmedAmount, 280000);
    });

    testWidgets('tapping Batal in dialog dismisses dialog without calling controller', (tester) async {
      final now = DateTime.now();
      final recurring = RecurringTransaction()
        ..syncId = 'rec_cancel_test'
        ..type = 'EXPENSE'
        ..amount = 100000
        ..walletSyncId = 'wallet_bca'
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = now
        ..nextDueDate = now
        ..autoExecute = false
        ..isActive = true
        ..description = 'Uang Kebersihan'
        ..createdAt = now
        ..updatedAt = now;

      final mockController = TestRecurringTransactionController();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dueManualRecurringProvider.overrideWith((ref) => Future.value([recurring])),
            recurringTransactionControllerProvider.overrideWith((ref) => mockController),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DueRecurringBanner(),
            ),
          ),
        ),
      );

      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Catat Sekarang'));
      await tester.pump();

      expect(find.text('Catat Transaksi Rutin'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pump();

      // Dialog dismissed
      expect(find.text('Catat Transaksi Rutin'), findsNothing);
      expect(mockController.confirmedSyncId, isNull);
      expect(mockController.skippedSyncId, isNull);
    });

    testWidgets('entering thousands with dot (250.000) parses properly to 250000.0 and shows SnackBar',
        (tester) async {
      final now = DateTime.now();
      final recurring = RecurringTransaction()
        ..syncId = 'rec_thousand_dot'
        ..type = 'EXPENSE'
        ..amount = 200000
        ..walletSyncId = 'wallet_bca'
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = now
        ..nextDueDate = now
        ..autoExecute = false
        ..isActive = true
        ..description = 'Iuran Warga'
        ..createdAt = now
        ..updatedAt = now;

      final mockController = TestRecurringTransactionController();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dueManualRecurringProvider.overrideWith((ref) => Future.value([recurring])),
            recurringTransactionControllerProvider.overrideWith((ref) => mockController),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DueRecurringBanner(),
            ),
          ),
        ),
      );

      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Catat Sekarang'));
      await tester.pump();

      // Enter thousands with dot
      await tester.enterText(find.byType(TextFormField), '250.000');
      await tester.pump();

      final catatDialogBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Catat Sekarang'),
      );
      await tester.tap(catatDialogBtn);
      await tester.pump(); // Dialog closes
      await tester.pump(); // SnackBar renders

      expect(mockController.confirmedSyncId, 'rec_thousand_dot');
      expect(mockController.confirmedAmount, 250000.0);
      expect(find.text('Transaksi rutin berhasil dicatat!'), findsOneWidget);
    });

    testWidgets('entering decimals with comma (150000,75) and dot (150.50) parses correctly',
        (tester) async {
      final now = DateTime.now();
      final recurring = RecurringTransaction()
        ..syncId = 'rec_decimal_test'
        ..type = 'EXPENSE'
        ..amount = 100000
        ..walletSyncId = 'wallet_bca'
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = now
        ..nextDueDate = now
        ..autoExecute = false
        ..isActive = true
        ..description = 'Tagihan Fleksibel'
        ..createdAt = now
        ..updatedAt = now;

      final mockController = TestRecurringTransactionController();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dueManualRecurringProvider.overrideWith((ref) => Future.value([recurring])),
            recurringTransactionControllerProvider.overrideWith((ref) => mockController),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DueRecurringBanner(),
            ),
          ),
        ),
      );

      await tester.pump();

      // 1. Test comma decimal (150000,75)
      await tester.tap(find.widgetWithText(ElevatedButton, 'Catat Sekarang'));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), '150000,75');
      await tester.pump();

      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Catat Sekarang'),
      ));
      await tester.pump();

      expect(mockController.confirmedAmount, 150000.75);

      // 2. Test dot decimal (150.50)
      await tester.tap(find.widgetWithText(ElevatedButton, 'Catat Sekarang'));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), '150.50');
      await tester.pump();

      await tester.tap(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Catat Sekarang'),
      ));
      await tester.pump();

      expect(mockController.confirmedAmount, 150.5);
    });

    testWidgets('initial value formats decimal with comma (150.5 -> 150,5)', (tester) async {
      final now = DateTime.now();
      final recurring = RecurringTransaction()
        ..syncId = 'rec_decimal_initial'
        ..type = 'EXPENSE'
        ..amount = 150.5
        ..walletSyncId = 'wallet_bca'
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = now
        ..nextDueDate = now
        ..autoExecute = false
        ..isActive = true
        ..description = 'Langganan Cloud'
        ..createdAt = now
        ..updatedAt = now;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dueManualRecurringProvider.overrideWith((ref) => Future.value([recurring])),
            recurringTransactionControllerProvider
                .overrideWith((ref) => TestRecurringTransactionController()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DueRecurringBanner(),
            ),
          ),
        ),
      );

      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Catat Sekarang'));
      await tester.pump();

      // Non-integer amount displays with comma
      expect(find.text('150,5'), findsOneWidget);
    });

    testWidgets('skipping cycle from dialog calls skipCurrentCycle and shows SnackBar',
        (tester) async {
      final now = DateTime.now();
      final recurring = RecurringTransaction()
        ..syncId = 'rec_skip_dialog'
        ..type = 'EXPENSE'
        ..amount = 50000
        ..walletSyncId = 'wallet_bca'
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = now
        ..nextDueDate = now
        ..autoExecute = false
        ..isActive = true
        ..description = 'Langganan Buku'
        ..createdAt = now
        ..updatedAt = now;

      final mockController = TestRecurringTransactionController();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dueManualRecurringProvider.overrideWith((ref) => Future.value([recurring])),
            recurringTransactionControllerProvider.overrideWith((ref) => mockController),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DueRecurringBanner(),
            ),
          ),
        ),
      );

      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Catat Sekarang'));
      await tester.pump();

      final lewatiDialogBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, 'Lewati'),
      );
      expect(lewatiDialogBtn, findsOneWidget);
      await tester.tap(lewatiDialogBtn);
      await tester.pump(); // Dialog closes
      await tester.pump(); // SnackBar renders

      expect(mockController.skippedSyncId, 'rec_skip_dialog');
      expect(find.text('Siklus transaksi berhasil dilewati.'), findsOneWidget);
    });
  });

  group('ConfirmRecurringDialog Unit Tests (Parsing & Formatting)', () {
    test('formatInitialAmount formats integer and decimal correctly', () {
      expect(ConfirmRecurringDialog.formatInitialAmount(250000.0), '250000');
      expect(ConfirmRecurringDialog.formatInitialAmount(0.0), '0');
      expect(ConfirmRecurringDialog.formatInitialAmount(150.5), '150,5');
      expect(ConfirmRecurringDialog.formatInitialAmount(150000.75), '150000,75');
    });

    test('parseAmount parses Indonesian thousands separator with dot', () {
      expect(ConfirmRecurringDialog.parseAmount('250.000'), 250000.0);
      expect(ConfirmRecurringDialog.parseAmount('5.000'), 5000.0);
      expect(ConfirmRecurringDialog.parseAmount('25.000'), 25000.0);
      expect(ConfirmRecurringDialog.parseAmount('1.250.000'), 1250000.0);
      expect(ConfirmRecurringDialog.parseAmount('250.000.000'), 250000000.0);
    });

    test('parseAmount parses decimals with comma or dot correctly', () {
      expect(ConfirmRecurringDialog.parseAmount('150,5'), 150.5);
      expect(ConfirmRecurringDialog.parseAmount('150000,75'), 150000.75);
      expect(ConfirmRecurringDialog.parseAmount('150.5'), 150.5);
      expect(ConfirmRecurringDialog.parseAmount('150.50'), 150.5);
      expect(ConfirmRecurringDialog.parseAmount('150.000,50'), 150000.5);
      expect(ConfirmRecurringDialog.parseAmount('0.5'), 0.5);
      expect(ConfirmRecurringDialog.parseAmount('0.123'), 0.123);
      expect(ConfirmRecurringDialog.parseAmount('250000'), 250000.0);
    });

    test('parseAmount returns null on invalid or empty input', () {
      expect(ConfirmRecurringDialog.parseAmount(null), isNull);
      expect(ConfirmRecurringDialog.parseAmount(''), isNull);
      expect(ConfirmRecurringDialog.parseAmount('   '), isNull);
      expect(ConfirmRecurringDialog.parseAmount('abc'), isNull);
    });
  });
}
