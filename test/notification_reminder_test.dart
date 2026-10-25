import 'dart:io';

import 'package:catatuang/core/database/database_provider.dart';
import 'package:catatuang/features/contact/domain/contact.dart';
import 'package:catatuang/features/debt/domain/debt.dart';
import 'package:catatuang/features/notification/application/notification_providers.dart';
import 'package:catatuang/features/notification/data/notification_repository.dart';
import 'package:catatuang/features/notification/domain/app_notification.dart';
import 'package:catatuang/features/notification/presentation/widgets/notification_sheet.dart';
import 'package:catatuang/features/transaction/application/recurring_transaction_controller.dart';
import 'package:catatuang/features/transaction/domain/recurring_transaction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:isar/isar.dart';

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
  late Isar isar;
  late Directory tempDir;
  late NotificationRepository notificationRepo;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
    await Isar.initializeIsarCore(download: true);
    tempDir = await Directory.systemTemp.createTemp('notif_repo_test_');
    isar = await Isar.open(
      isarSchemas,
      directory: tempDir.path,
      name: 'notif_repo_test_db',
    );
    notificationRepo = NotificationRepository(isar);
  });

  tearDownAll(() async {
    await isar.close(deleteFromDisk: true);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  setUp(() async {
    await isar.writeTxn(() async {
      await isar.clear();
    });
  });

  group('Notification & Debt Reminders Integration Tests', () {
    test('AppNotificationItem calculates correct urgency levels and properties', () {
      final now = DateTime.now();

      final mockDebt = Debt()
        ..id = 1
        ..syncId = 'd_1'
        ..title = 'Pinjaman Usaha'
        ..type = 'PAYABLE'
        ..contactSyncId = 'c_1'
        ..totalAmount = 1000000
        ..paidAmount = 200000
        ..startDate = now.subtract(const Duration(days: 30))
        ..dueDate = now
        ..isActive = true
        ..createdAt = now
        ..updatedAt = now;

      final item = AppNotificationItem(
        id: 'notif_1',
        title: 'Utang Jatuh Tempo Hari Ini',
        message: 'Segera lunasi utang Pinjaman Usaha hari ini.',
        type: 'PAYABLE',
        urgency: NotificationUrgency.dueToday,
        debtId: 1,
        debt: mockDebt,
        dueDate: now,
        remainingAmount: 800000,
      );

      expect(item.urgency, NotificationUrgency.dueToday);
      expect(item.remainingAmount, 800000);
      expect(item.type, 'PAYABLE');
      expect(item.isPayable, isTrue);
      expect(item.isRecurring, isFalse);
    });

    test('NotificationRepository.getActiveReminders combines debt and recurring reminders in order',
        () async {
      final now = DateTime.now();

      // Create a debt
      final debt = Debt()
        ..syncId = 'debt_1'
        ..title = 'Cicilan Motor'
        ..type = 'PAYABLE'
        ..contactSyncId = 'c_1'
        ..totalAmount = 500000
        ..paidAmount = 0
        ..startDate = now.subtract(const Duration(days: 10))
        ..dueDate = now.subtract(const Duration(days: 1)) // Overdue
        ..isActive = true
        ..createdAt = now
        ..updatedAt = now;

      // Create a recurring transaction
      final recurring = RecurringTransaction()
        ..syncId = 'rec_1'
        ..type = 'EXPENSE'
        ..amount = 150000
        ..walletSyncId = 'wallet_main'
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = now.subtract(const Duration(days: 30))
        ..nextDueDate = now // Due today
        ..autoExecute = false
        ..isActive = true
        ..description = 'Langganan Wi-Fi'
        ..createdAt = now
        ..updatedAt = now;

      await isar.writeTxn(() async {
        await isar.debts.put(debt);
        await isar.recurringTransactions.put(recurring);
      });

      final reminders = await notificationRepo.getActiveReminders();
      expect(reminders.length, 2);

      // Overdue debt comes first, then due today recurring
      expect(reminders[0].urgency, NotificationUrgency.overdue);
      expect(reminders[0].isRecurring, isFalse);

      expect(reminders[1].urgency, NotificationUrgency.dueToday);
      expect(reminders[1].isRecurring, isTrue);
      expect(reminders[1].title, 'Transaksi Rutin Hari Ini');
      expect(reminders[1].remainingAmount, 150000);
    });
  });

  group('NotificationSheet Widget Tests', () {
    testWidgets('NotificationSheet renders empty state when no reminders exist', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeRemindersProvider.overrideWith((ref) => Future.value(const [])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationSheet(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Pusat Pengingat'), findsOneWidget);
      expect(find.text('Semua Tagihan Beres!'), findsOneWidget);
    });

    testWidgets('NotificationSheet renders list of active debt reminders', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now();
      final mockContact = Contact()
        ..id = 1
        ..syncId = 'c_1'
        ..name = 'Budi Santoso'
        ..phoneNumber = '08123456789'
        ..isActive = true
        ..createdAt = now
        ..updatedAt = now;

      final mockDebt = Debt()
        ..id = 1
        ..syncId = 'd_1'
        ..title = 'Uang Kos'
        ..type = 'PAYABLE'
        ..contactSyncId = 'c_1'
        ..totalAmount = 1500000
        ..paidAmount = 0
        ..startDate = now.subtract(const Duration(days: 20))
        ..dueDate = now
        ..isActive = true
        ..createdAt = now
        ..updatedAt = now;

      final item = AppNotificationItem(
        id: 'notif_1',
        title: 'Utang Jatuh Tempo Hari Ini',
        message: 'Segera lunasi utang "Uang Kos" ke Budi Santoso hari ini.',
        type: 'PAYABLE',
        urgency: NotificationUrgency.dueToday,
        debtId: 1,
        debt: mockDebt,
        contact: mockContact,
        dueDate: now,
        remainingAmount: 1500000,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeRemindersProvider.overrideWith((ref) => Future.value([item])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationSheet(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Pusat Pengingat'), findsOneWidget);
      expect(find.text('Utang Jatuh Tempo Hari Ini'), findsOneWidget);
      expect(find.text('HARI INI'), findsOneWidget);
      expect(find.text('Bayar'), findsOneWidget);
    });

    testWidgets(
        'NotificationSheet renders recurring item and opens dialog allowing quick edit nominal and confirm',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now();
      final recurring = RecurringTransaction()
        ..syncId = 'rec_wifi'
        ..type = 'EXPENSE'
        ..amount = 350000
        ..walletSyncId = 'wallet_main'
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = now.subtract(const Duration(days: 30))
        ..nextDueDate = now
        ..autoExecute = false
        ..isActive = true
        ..description = 'Indihome Bulanan'
        ..createdAt = now
        ..updatedAt = now;

      final item = AppNotificationItem(
        id: 'rec_notif_1',
        title: 'Transaksi Rutin Hari Ini',
        message: 'Saatnya mencatat jadwal "Indihome Bulanan" hari ini.',
        type: 'RECURRING',
        urgency: NotificationUrgency.dueToday,
        recurring: recurring,
        dueDate: now,
        remainingAmount: 350000,
      );

      final mockController = TestRecurringTransactionController();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeRemindersProvider.overrideWith((ref) => Future.value([item])),
            recurringTransactionControllerProvider.overrideWith((ref) => mockController),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationSheet(),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify recurring item is shown
      expect(find.text('Pusat Pengingat'), findsOneWidget);
      expect(find.text('Transaksi Rutin Hari Ini'), findsOneWidget);
      expect(find.text('Nominal Tagihan'), findsOneWidget);
      expect(find.text('Catat Sekarang'), findsOneWidget);

      // Tap "Catat Sekarang" to open quick edit dialog
      await tester.tap(find.text('Catat Sekarang'));
      await tester.pump();

      // Verify dialog is opened
      expect(find.text('Catat Transaksi Rutin'), findsOneWidget);
      expect(find.text('Indihome Bulanan'), findsOneWidget);
      expect(find.text('350000'), findsOneWidget);

      // Quick edit: change nominal to 385000 (bill variation)
      await tester.enterText(find.byType(TextFormField), '385000');
      await tester.pump();

      // Tap "Catat Sekarang" inside dialog (ElevatedButton)
      final dialogCatatBtn = find.widgetWithText(ElevatedButton, 'Catat Sekarang');
      expect(dialogCatatBtn, findsOneWidget);
      await tester.tap(dialogCatatBtn);
      await tester.pump();

      // Verify controller confirmExecution was called with new custom amount
      expect(mockController.confirmedSyncId, 'rec_wifi');
      expect(mockController.confirmedAmount, 385000);
    });

    testWidgets('NotificationSheet skip cycle via dialog calls skipCurrentCycle', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now();
      final recurring = RecurringTransaction()
        ..syncId = 'rec_skip_test'
        ..type = 'EXPENSE'
        ..amount = 50000
        ..walletSyncId = 'wallet_main'
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = now.subtract(const Duration(days: 30))
        ..nextDueDate = now
        ..autoExecute = false
        ..isActive = true
        ..description = 'Langganan Koran'
        ..createdAt = now
        ..updatedAt = now;

      final item = AppNotificationItem(
        id: 'rec_notif_2',
        title: 'Transaksi Rutin Hari Ini',
        message: 'Saatnya mencatat jadwal "Langganan Koran" hari ini.',
        type: 'RECURRING',
        urgency: NotificationUrgency.dueToday,
        recurring: recurring,
        dueDate: now,
        remainingAmount: 50000,
      );

      final mockController = TestRecurringTransactionController();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeRemindersProvider.overrideWith((ref) => Future.value([item])),
            recurringTransactionControllerProvider.overrideWith((ref) => mockController),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationSheet(),
            ),
          ),
        ),
      );

      await tester.pump();

      // Tap "Catat Sekarang" to open dialog
      await tester.tap(find.text('Catat Sekarang'));
      await tester.pump();

      // Tap "Lewati" in dialog
      final lewatiBtn = find.widgetWithText(TextButton, 'Lewati');
      expect(lewatiBtn, findsOneWidget);
      await tester.tap(lewatiBtn);
      await tester.pump();

      // Verify controller skipCurrentCycle was called
      expect(mockController.skippedSyncId, 'rec_skip_test');
    });

    testWidgets(
        'NotificationSheet dialog supports thousand dot format and parses correctly',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final now = DateTime.now();
      final recurring = RecurringTransaction()
        ..syncId = 'rec_notif_thousand'
        ..type = 'EXPENSE'
        ..amount = 200000
        ..walletSyncId = 'wallet_main'
        ..frequency = 'MONTHLY'
        ..interval = 1
        ..startDate = now.subtract(const Duration(days: 30))
        ..nextDueDate = now
        ..autoExecute = false
        ..isActive = true
        ..description = 'Tagihan PDAM'
        ..createdAt = now
        ..updatedAt = now;

      final item = AppNotificationItem(
        id: 'rec_notif_pdam',
        title: 'Transaksi Rutin Hari Ini',
        message: 'Saatnya mencatat jadwal "Tagihan PDAM" hari ini.',
        type: 'RECURRING',
        urgency: NotificationUrgency.dueToday,
        recurring: recurring,
        dueDate: now,
        remainingAmount: 200000,
      );

      final mockController = TestRecurringTransactionController();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeRemindersProvider.overrideWith((ref) => Future.value([item])),
            recurringTransactionControllerProvider.overrideWith((ref) => mockController),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotificationSheet(),
            ),
          ),
        ),
      );

      await tester.pump();

      await tester.tap(find.text('Catat Sekarang'));
      await tester.pump();

      // Enter thousands with dot
      await tester.enterText(find.byType(TextFormField), '225.000');
      await tester.pump();

      final dialogCatatBtn = find.widgetWithText(ElevatedButton, 'Catat Sekarang');
      await tester.tap(dialogCatatBtn);
      await tester.pump();

      expect(mockController.confirmedSyncId, 'rec_notif_thousand');
      expect(mockController.confirmedAmount, 225000.0);
    });
  });
}
