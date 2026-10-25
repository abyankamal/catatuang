import 'dart:io';

import 'package:catatuang/core/database/database_provider.dart';
import 'package:catatuang/features/transaction/application/recurring_transaction_controller.dart';
import 'package:catatuang/features/transaction/data/recurring_transaction_repository.dart';
import 'package:catatuang/features/transaction/domain/recurring_transaction.dart';
import 'package:catatuang/features/transaction/domain/transaction.dart';
import 'package:catatuang/features/wallet/domain/wallet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

void main() {
  late Isar isar;
  late Directory tempDir;
  late RecurringTransactionRepository repository;
  late ProviderContainer container;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Isar.initializeIsarCore(download: true);
    tempDir = await Directory.systemTemp.createTemp('recurring_ctrl_test_');
    isar = await Isar.open(
      isarSchemas,
      directory: tempDir.path,
      name: 'recurring_ctrl_test_db',
    );
    repository = RecurringTransactionRepository(isar);
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

    container = ProviderContainer(
      overrides: [
        isarProvider.overrideWith((ref) => IsarStateNotifier(isar)),
        recurringTransactionRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  Future<Wallet> createTestWallet({
    String syncId = 'wallet_main',
    String name = 'Dompet Utama',
    double balance = 1000000,
  }) async {
    final wallet = Wallet()
      ..syncId = syncId
      ..name = name
      ..balance = balance
      ..isActive = true
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.wallets.put(wallet);
    });
    return wallet;
  }

  group('RecurringTransactionController CRUD & State', () {
    test('createRecurring persists item and sets state to data(null)', () async {
      await createTestWallet();
      final controller = container.read(recurringTransactionControllerProvider.notifier);

      final success = await controller.createRecurring(
        type: 'EXPENSE',
        amount: 50000,
        walletSyncId: 'wallet_main',
        frequency: 'MONTHLY',
        startDate: DateTime(2026, 1, 1),
        description: 'Langganan Netflix',
      );

      expect(success, isTrue);
      expect(container.read(recurringTransactionControllerProvider).hasError, isFalse);
      expect(container.read(recurringTransactionControllerProvider).isLoading, isFalse);

      final all = await isar.recurringTransactions.where().findAll();
      expect(all.length, 1);
      expect(all.first.description, 'Langganan Netflix');
      expect(all.first.amount, 50000);
      expect(all.first.isActive, isTrue);
    });

    test('toggleActive updates isActive state', () async {
      await createTestWallet();
      final controller = container.read(recurringTransactionControllerProvider.notifier);

      await controller.createRecurring(
        type: 'EXPENSE',
        amount: 25000,
        walletSyncId: 'wallet_main',
        frequency: 'WEEKLY',
        startDate: DateTime(2026, 1, 1),
        description: 'Gym',
      );

      final item = await isar.recurringTransactions.where().findFirst();
      expect(item, isNotNull);

      final toggled = await controller.toggleActive(item!.syncId, false);
      expect(toggled, isTrue);

      final updated = await isar.recurringTransactions.getBySyncId(item.syncId);
      expect(updated?.isActive, isFalse);
    });

    test('softDelete sets isActive to false', () async {
      await createTestWallet();
      final controller = container.read(recurringTransactionControllerProvider.notifier);

      await controller.createRecurring(
        type: 'EXPENSE',
        amount: 30000,
        walletSyncId: 'wallet_main',
        frequency: 'MONTHLY',
        startDate: DateTime(2026, 1, 1),
        description: 'Spotify',
      );

      final item = (await isar.recurringTransactions.where().findFirst())!;
      final deleted = await controller.softDelete(item.syncId);
      expect(deleted, isTrue);

      final updated = await isar.recurringTransactions.getBySyncId(item.syncId);
      expect(updated, isNotNull);
      expect(updated?.isActive, isFalse);
    });

    test('hardDelete completely removes item from database', () async {
      await createTestWallet();
      final controller = container.read(recurringTransactionControllerProvider.notifier);

      await controller.createRecurring(
        type: 'EXPENSE',
        amount: 10000,
        walletSyncId: 'wallet_main',
        frequency: 'DAILY',
        startDate: DateTime(2026, 1, 1),
        description: 'Kopi Harian',
      );

      final item = (await isar.recurringTransactions.where().findFirst())!;
      final deleted = await controller.hardDelete(item.syncId);
      expect(deleted, isTrue);

      final updated = await isar.recurringTransactions.getBySyncId(item.syncId);
      expect(updated, isNull);
    });
  });

  group('Manual Recurring & Action Handlers', () {
    test('skipCurrentCycle advances nextDueDate without executing transaction', () async {
      await createTestWallet();
      final controller = container.read(recurringTransactionControllerProvider.notifier);

      await controller.createRecurring(
        type: 'EXPENSE',
        amount: 100000,
        walletSyncId: 'wallet_main',
        frequency: 'MONTHLY',
        startDate: DateTime(2026, 1, 15),
        description: 'Tagihan Listrik',
      );

      final item = (await isar.recurringTransactions.where().findFirst())!;
      final oldDueDate = item.nextDueDate;

      final success = await controller.skipCurrentCycle(item.syncId);
      expect(success, isTrue);

      final updated = (await isar.recurringTransactions.getBySyncId(item.syncId))!;
      expect(updated.nextDueDate.isAfter(oldDueDate), isTrue);
      expect(updated.nextDueDate, DateTime(2026, 2, 15));

      // No transactions created
      final txCount = await isar.transactions.count();
      expect(txCount, 0);

      // Wallet balance remains unchanged
      final wallet = await isar.wallets.getBySyncId('wallet_main');
      expect(wallet?.balance, 1000000);
    });

    test('confirmExecution executes transaction with correct balance deduction', () async {
      await createTestWallet(balance: 500000);
      final controller = container.read(recurringTransactionControllerProvider.notifier);

      await controller.createRecurring(
        type: 'EXPENSE',
        amount: 120000,
        walletSyncId: 'wallet_main',
        frequency: 'MONTHLY',
        startDate: DateTime(2026, 1, 10),
        description: 'Internet Indihome',
      );

      final item = (await isar.recurringTransactions.where().findFirst())!;

      final confirmed = await controller.confirmExecution(
        item.syncId,
        executionDate: DateTime(2026, 1, 10),
      );
      expect(confirmed, isTrue);

      // Transaction created with recurringSyncId
      final tx = await isar.transactions.where().findFirst();
      expect(tx, isNotNull);
      expect(tx?.amount, 120000);
      expect(tx?.recurringSyncId, item.syncId);
      expect(tx?.walletSyncId, 'wallet_main');

      // Wallet balance deducted
      final wallet = await isar.wallets.getBySyncId('wallet_main');
      expect(wallet?.balance, 380000);

      // Next due date moved forward
      final updated = (await isar.recurringTransactions.getBySyncId(item.syncId))!;
      expect(updated.nextDueDate, DateTime(2026, 2, 10));
      expect(updated.lastExecutedDate, DateTime(2026, 1, 10));
    });

    test('dueManualRecurringProvider filters only manual and due items', () async {
      await createTestWallet();
      final now = DateTime.now();

      // 1. Manual item, due in past -> should be in dueManualRecurringProvider
      await repository.createRecurring(
        type: 'EXPENSE',
        amount: 50000,
        walletSyncId: 'wallet_main',
        frequency: 'MONTHLY',
        startDate: now.subtract(const Duration(days: 2)),
        autoExecute: false,
        description: 'Manual Past Due',
      );

      // 2. Auto-execute item, due in past -> should NOT be in dueManualRecurringProvider
      await repository.createRecurring(
        type: 'EXPENSE',
        amount: 75000,
        walletSyncId: 'wallet_main',
        frequency: 'MONTHLY',
        startDate: now.subtract(const Duration(days: 2)),
        autoExecute: true,
        description: 'Auto Past Due',
      );

      // 3. Manual item, future due -> should NOT be in dueManualRecurringProvider
      await repository.createRecurring(
        type: 'EXPENSE',
        amount: 100000,
        walletSyncId: 'wallet_main',
        frequency: 'MONTHLY',
        startDate: now.add(const Duration(days: 5)),
        autoExecute: false,
        description: 'Manual Future',
      );

      final dueManual = await container.read(dueManualRecurringProvider.future);
      expect(dueManual.length, 1);
      expect(dueManual.first.description, 'Manual Past Due');
    });

    test('dueManualRecurringProvider returns same-day schedule with late hour when queried in morning',
        () async {
      await createTestWallet();

      final now = DateTime.now();
      // Schedule due at 22:00 tonight
      final tonightDueDate = DateTime(now.year, now.month, now.day, 22, 0, 0);

      await repository.createRecurring(
        type: 'EXPENSE',
        amount: 350000,
        walletSyncId: 'wallet_main',
        frequency: 'MONTHLY',
        startDate: tonightDueDate,
        autoExecute: false,
        description: 'Tagihan Listrik Malam Ini',
      );

      // Tomorrow schedule at 08:00
      final tomorrowDueDate = DateTime(now.year, now.month, now.day + 1, 8, 0, 0);
      await repository.createRecurring(
        type: 'EXPENSE',
        amount: 50000,
        walletSyncId: 'wallet_main',
        frequency: 'MONTHLY',
        startDate: tomorrowDueDate,
        autoExecute: false,
        description: 'Jadwal Esok Hari',
      );

      final dueManual = await container.read(dueManualRecurringProvider.future);
      // Must include today's evening schedule, but exclude tomorrow's schedule
      expect(dueManual.length, 1);
      expect(dueManual.first.description, 'Tagihan Listrik Malam Ini');
    });
  });

  group('Auto-Execution & In-Memory Mutex Lock', () {
    test('processDueAutoTransactions executes due auto-recurring transactions', () async {
      await createTestWallet(balance: 1000000);
      final controller = container.read(recurringTransactionControllerProvider.notifier);

      final pastDate = DateTime(2026, 1, 1);
      // Auto-recurring past due
      await repository.createRecurring(
        type: 'EXPENSE',
        amount: 200000,
        walletSyncId: 'wallet_main',
        frequency: 'MONTHLY',
        startDate: pastDate,
        autoExecute: true,
        description: 'Auto Netflix',
      );

      final count = await controller.processDueAutoTransactions();
      expect(count, greaterThan(0));

      final tx = await isar.transactions.where().findFirst();
      expect(tx, isNotNull);
      expect(tx?.description, 'Auto Netflix');

      final wallet = await isar.wallets.getBySyncId('wallet_main');
      expect(wallet?.balance, lessThan(1000000));
    });

    test('mutex lock blocks concurrent processDueAutoTransactions executions', () async {
      await createTestWallet(balance: 1000000);
      final controller = container.read(recurringTransactionControllerProvider.notifier);

      final pastDate = DateTime(2026, 1, 1);
      await repository.createRecurring(
        type: 'EXPENSE',
        amount: 50000,
        walletSyncId: 'wallet_main',
        frequency: 'MONTHLY',
        startDate: pastDate,
        autoExecute: true,
        description: 'Auto Cloud',
      );

      // Launch two processDueAutoTransactions concurrently
      final futures = await Future.wait([
        controller.processDueAutoTransactions(),
        controller.processDueAutoTransactions(),
      ]);

      // One should execute (> 0), while the second should be blocked by mutex lock and return 0
      final totalExecuted = futures[0] + futures[1];
      expect(futures.contains(0), isTrue);
      expect(totalExecuted, greaterThan(0));

      // Ensure mutex is reset after completion
      expect(controller.isProcessingAutoRecurring, isFalse);
    });

    test('processDueAutoTransactions handles multi-cycle catch-up capped at maxCycles', () async {
      await createTestWallet(balance: 2000000);
      final controller = container.read(recurringTransactionControllerProvider.notifier);

      // Set start date 3 months in the past
      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);

      await repository.createRecurring(
        type: 'EXPENSE',
        amount: 50000,
        walletSyncId: 'wallet_main',
        frequency: 'MONTHLY',
        startDate: threeMonthsAgo,
        autoExecute: true,
        description: 'Multi-cycle Catch-up',
      );

      final executedCount = await controller.processDueAutoTransactions();
      // Should have caught up multiple cycles (at least 3 cycles: T-3, T-2, T-1, and possibly T-0 depending on day)
      expect(executedCount, greaterThanOrEqualTo(3));

      final item = (await isar.recurringTransactions.where().findFirst())!;
      expect(item.nextDueDate.isAfter(now), isTrue);

      final wallet = await isar.wallets.getBySyncId('wallet_main');
      expect(wallet?.balance, 2000000 - (50000 * executedCount));
    });

    test(
        'processDueAutoTransactions executes same-day schedule with late hour and excludes tomorrow',
        () async {
      await createTestWallet(balance: 1000000);
      final controller = container.read(recurringTransactionControllerProvider.notifier);

      final now = DateTime.now();
      // Auto-schedule due at 23:00 tonight
      final tonightDueDate = DateTime(now.year, now.month, now.day, 23, 0, 0);

      await repository.createRecurring(
        type: 'EXPENSE',
        amount: 75000,
        walletSyncId: 'wallet_main',
        frequency: 'MONTHLY',
        startDate: tonightDueDate,
        autoExecute: true,
        description: 'Auto Malam Hari',
      );

      // Auto-schedule due tomorrow at 06:00
      final tomorrowDueDate = DateTime(now.year, now.month, now.day + 1, 6, 0, 0);
      await repository.createRecurring(
        type: 'EXPENSE',
        amount: 50000,
        walletSyncId: 'wallet_main',
        frequency: 'MONTHLY',
        startDate: tomorrowDueDate,
        autoExecute: true,
        description: 'Auto Esok Hari',
      );

      final executedCount = await controller.processDueAutoTransactions();
      // Only today's schedule should execute
      expect(executedCount, 1);

      final transactions = await isar.transactions.where().findAll();
      expect(transactions.length, 1);
      expect(transactions.first.description, 'Auto Malam Hari');

      // Tomorrow's recurring schedule remains untouched
      final tomorrowRec = await isar.recurringTransactions
          .filter()
          .descriptionEqualTo('Auto Esok Hari')
          .findFirst();
      expect(tomorrowRec, isNotNull);
      expect(tomorrowRec?.occurrenceCount, 0);
    });
  });
}
