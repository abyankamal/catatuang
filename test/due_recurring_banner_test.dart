import 'package:catatuang/features/dashboard/presentation/widgets/due_recurring_banner.dart';
import 'package:catatuang/features/transaction/application/recurring_transaction_controller.dart';
import 'package:catatuang/features/transaction/domain/recurring_transaction.dart';
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
  });
}
