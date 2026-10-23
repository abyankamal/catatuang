import 'dart:io';
import 'package:catatuang/core/database/database_provider.dart';
import 'package:catatuang/features/category/domain/category.dart';
import 'package:catatuang/features/settings/domain/app_settings.dart';
import 'package:catatuang/features/transaction/data/recurring_transaction_repository.dart';
import 'package:catatuang/features/transaction/domain/transaction.dart';
import 'package:catatuang/features/wallet/domain/wallet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

void main() {
  late Isar isar;
  late RecurringTransactionRepository repository;
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Isar.initializeIsarCore(download: true);
    tempDir = await Directory.systemTemp.createTemp('recurring_test_');
    isar = await Isar.open(
      isarSchemas,
      directory: tempDir.path,
      name: 'recurring_test_db',
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
  });

  group('RecurringTransactionRepository - CRUD Operations', () {
    test('createRecurring successfully persists recurring transaction', () async {
      final wallet = Wallet()
        ..syncId = 'wallet_bca'
        ..name = 'BCA'
        ..balance = 1000000
        ..isActive = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await isar.writeTxn(() async {
        await isar.wallets.put(wallet);
      });

      final recurring = await repository.createRecurring(
        type: 'EXPENSE',
        amount: 150000,
        walletSyncId: 'wallet_bca',
        frequency: 'MONTHLY',
        interval: 1,
        startDate: DateTime(2026, 11, 1),
        description: 'Langganan Internet',
        autoExecute: true,
      );

      expect(recurring.id, isNotNull);
      expect(recurring.syncId.isNotEmpty, isTrue);
      expect(recurring.amount, equals(150000));
      expect(recurring.frequency, equals('MONTHLY'));
      expect(recurring.occurrenceCount, equals(0));
      expect(recurring.isActive, isTrue);

      final retrieved = await repository.getBySyncId(recurring.syncId);
      expect(retrieved, isNotNull);
      expect(retrieved?.description, equals('Langganan Internet'));
    });

    test('createRecurring throws when wallet does not exist or is inactive', () async {
      expect(
        () => repository.createRecurring(
          type: 'EXPENSE',
          amount: 50000,
          walletSyncId: 'non_existent_wallet',
          frequency: 'DAILY',
          startDate: DateTime(2026, 11, 1),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('toggleActive and softDelete pause and resume recurring schedule', () async {
      final wallet = Wallet()
        ..syncId = 'wallet_cash'
        ..name = 'Tunai'
        ..balance = 500000
        ..isActive = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await isar.writeTxn(() async {
        await isar.wallets.put(wallet);
      });

      final recurring = await repository.createRecurring(
        type: 'EXPENSE',
        amount: 25000,
        walletSyncId: 'wallet_cash',
        frequency: 'WEEKLY',
        startDate: DateTime(2026, 11, 1),
      );

      await repository.toggleActive(recurring.syncId, false);
      var updated = await repository.getBySyncId(recurring.syncId);
      expect(updated?.isActive, isFalse);

      await repository.toggleActive(recurring.syncId, true);
      updated = await repository.getBySyncId(recurring.syncId);
      expect(updated?.isActive, isTrue);

      await repository.softDelete(recurring.syncId);
      updated = await repository.getBySyncId(recurring.syncId);
      expect(updated?.isActive, isFalse);
    });
  });

  group('RecurringTransactionRepository - executeRecurring (ACID Engine)', () {
    test('Executes EXPENSE, deducts wallet balance (allows negative), and advances schedule', () async {
      // Wallet with 50.000 balance
      final wallet = Wallet()
        ..syncId = 'wallet_ovo'
        ..name = 'OVO'
        ..balance = 50000
        ..isActive = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await isar.writeTxn(() async {
        await isar.wallets.put(wallet);
      });

      final recurring = await repository.createRecurring(
        type: 'EXPENSE',
        amount: 75000, // Exceeds balance by 25.000 -> balance should become -25.000
        walletSyncId: 'wallet_ovo',
        frequency: 'MONTHLY',
        interval: 1,
        startDate: DateTime(2026, 11, 1, 10, 0),
        description: 'Netflix',
      );

      final tx = await repository.executeRecurring(
        recurringSyncId: recurring.syncId,
        executionDate: DateTime(2026, 11, 1, 10, 0),
      );

      // Verify Transaction record
      expect(tx.type, equals('EXPENSE'));
      expect(tx.amount, equals(75000));
      expect(tx.recurringSyncId, equals(recurring.syncId));
      expect(tx.description, equals('Netflix'));

      // Verify Wallet Balance is -25.000 (negative balance allowed per user spec)
      final updatedWallet = await isar.wallets.filter().syncIdEqualTo('wallet_ovo').findFirst();
      expect(updatedWallet?.balance, equals(-25000));

      // Verify Recurring Schedule state
      final updatedRecurring = await repository.getBySyncId(recurring.syncId);
      expect(updatedRecurring?.occurrenceCount, equals(1));
      expect(updatedRecurring?.lastExecutedDate, equals(DateTime(2026, 11, 1, 10, 0)));
      expect(updatedRecurring?.nextDueDate, equals(DateTime(2026, 12, 1, 10, 0)));
      expect(updatedRecurring?.isActive, isTrue);
    });

    test('Executes EXPENSE with customAmount (variable amount support)', () async {
      final wallet = Wallet()
        ..syncId = 'wallet_pln'
        ..name = 'Bank Mandiri'
        ..balance = 500000
        ..isActive = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await isar.writeTxn(() async {
        await isar.wallets.put(wallet);
      });

      // Default amount is 300.000, but PLN bill this month is 385.000
      final recurring = await repository.createRecurring(
        type: 'EXPENSE',
        amount: 300000,
        walletSyncId: 'wallet_pln',
        frequency: 'MONTHLY',
        startDate: DateTime(2026, 11, 1),
        description: 'Tagihan Listrik PLN',
      );

      final tx = await repository.executeRecurring(
        recurringSyncId: recurring.syncId,
        executionDate: DateTime(2026, 11, 1),
        customAmount: 385000,
      );

      expect(tx.amount, equals(385000));
      final updatedWallet = await isar.wallets.filter().syncIdEqualTo('wallet_pln').findFirst();
      expect(updatedWallet?.balance, equals(115000)); // 500.000 - 385.000
    });

    test('Executes INCOME and increases wallet balance', () async {
      final wallet = Wallet()
        ..syncId = 'wallet_gaji'
        ..name = 'BCA Gaji'
        ..balance = 1000000
        ..isActive = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await isar.writeTxn(() async {
        await isar.wallets.put(wallet);
      });

      final recurring = await repository.createRecurring(
        type: 'INCOME',
        amount: 8000000,
        walletSyncId: 'wallet_gaji',
        frequency: 'MONTHLY',
        startDate: DateTime(2026, 11, 25),
        description: 'Gaji Bulanan',
      );

      final tx = await repository.executeRecurring(
        recurringSyncId: recurring.syncId,
        executionDate: DateTime(2026, 11, 25),
      );

      expect(tx.type, equals('INCOME'));
      expect(tx.amount, equals(8000000));
      expect(tx.recurringSyncId, equals(recurring.syncId));

      final updatedWallet = await isar.wallets.filter().syncIdEqualTo('wallet_gaji').findFirst();
      expect(updatedWallet?.balance, equals(9000000));
    });

    test('Executes TRANSFER using 3-Transaction Pattern with cat_transfer_fee lookup (AGENTS.md §4)', () async {
      final sourceWallet = Wallet()
        ..syncId = 'wallet_src'
        ..name = 'BCA Utama'
        ..balance = 2000000
        ..isActive = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      final destWallet = Wallet()
        ..syncId = 'wallet_dest'
        ..name = 'Kantong Tabungan Goal'
        ..balance = 500000
        ..isGoal = true
        ..isActive = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      final transferFeeCat = Category()
        ..syncId = 'cat_transfer_fee'
        ..name = 'Biaya Transfer'
        ..type = 'EXPENSE'
        ..colorValue = 0xFF64748B
        ..icon = 'swap_horiz'
        ..isActive = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await isar.writeTxn(() async {
        await isar.wallets.putAll([sourceWallet, destWallet]);
        await isar.categorys.put(transferFeeCat);
      });

      final recurring = await repository.createRecurring(
        type: 'TRANSFER',
        amount: 1000000,
        adminFee: 2500,
        walletSyncId: 'wallet_src',
        targetWalletSyncId: 'wallet_dest',
        frequency: 'MONTHLY',
        startDate: DateTime(2026, 11, 25),
        description: 'Alokasi Tabungan Bulanan',
      );

      final primaryTx = await repository.executeRecurring(
        recurringSyncId: recurring.syncId,
        executionDate: DateTime(2026, 11, 25),
      );
      expect(primaryTx.type, equals('TRANSFER_OUT'));
      expect(primaryTx.amount, equals(1000000));

      // Verify wallet balances:
      // Source: 2.000.000 - (1.000.000 + 2.500) = 997.500
      // Dest: 500.000 + 1.000.000 = 1.500.000
      final updatedSrc = await isar.wallets.filter().syncIdEqualTo('wallet_src').findFirst();
      final updatedDest = await isar.wallets.filter().syncIdEqualTo('wallet_dest').findFirst();
      expect(updatedSrc?.balance, equals(997500));
      expect(updatedDest?.balance, equals(1500000));

      // Verify 3 generated transactions bound by transactionGroupId
      final allTx = await isar.transactions.filter().recurringSyncIdEqualTo(recurring.syncId).findAll();
      expect(allTx.length, equals(3));

      final transferOut = allTx.firstWhere((t) => t.type == 'TRANSFER_OUT');
      final transferIn = allTx.firstWhere((t) => t.type == 'TRANSFER_IN');
      final feeExpense = allTx.firstWhere((t) => t.type == 'EXPENSE');

      expect(transferOut.amount, equals(1000000));
      expect(transferOut.walletSyncId, equals('wallet_src'));

      expect(transferIn.amount, equals(1000000));
      expect(transferIn.walletSyncId, equals('wallet_dest'));

      expect(feeExpense.amount, equals(2500));
      expect(feeExpense.walletSyncId, equals('wallet_src'));
      expect(feeExpense.categorySyncId, equals('cat_transfer_fee'));

      // All 3 must share the same groupId
      expect(transferOut.transactionGroupId, isNotNull);
      expect(transferOut.transactionGroupId, equals(transferIn.transactionGroupId));
      expect(transferOut.transactionGroupId, equals(feeExpense.transactionGroupId));
    });

    test('Period locking adjustment: Clamps date and adds audit note if scheduled in locked period', () async {
      final wallet = Wallet()
        ..syncId = 'wallet_locked_test'
        ..name = 'Bank'
        ..balance = 1000000
        ..isActive = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      // App is locked until 31 October 2026
      final settings = AppSettings()
        ..syncId = 'app_settings_1'
        ..lockedUntil = DateTime(2026, 10, 31, 23, 59, 59)
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await isar.writeTxn(() async {
        await isar.wallets.put(wallet);
        await isar.appSettings.put(settings);
      });

      // Scheduled date was 15 October 2026 (inside locked period)
      final recurring = await repository.createRecurring(
        type: 'EXPENSE',
        amount: 100000,
        walletSyncId: 'wallet_locked_test',
        frequency: 'MONTHLY',
        startDate: DateTime(2026, 10, 15),
        description: 'Tagihan Air PDAM',
      );

      final tx = await repository.executeRecurring(
        recurringSyncId: recurring.syncId,
        executionDate: DateTime(2026, 10, 15),
      );

      // Effective date must be clamped to 1 second after lockedUntil
      final expectedEffectiveDate = DateTime(2026, 11, 1, 0, 0, 0);
      expect(tx.date, equals(expectedEffectiveDate));

      // Description must contain audit note
      expect(tx.description, contains('Tagihan Air PDAM'));
      expect(tx.description, contains('Dijadwalkan dari tanggal 15/10/2026 yang telah tutup buku'));
    });

    test('skipCurrentCycle advances nextDueDate without creating transactions', () async {
      final wallet = Wallet()
        ..syncId = 'wallet_skip'
        ..name = 'BCA'
        ..balance = 500000
        ..isActive = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await isar.writeTxn(() async {
        await isar.wallets.put(wallet);
      });

      final recurring = await repository.createRecurring(
        type: 'EXPENSE',
        amount: 50000,
        walletSyncId: 'wallet_skip',
        frequency: 'MONTHLY',
        startDate: DateTime(2026, 11, 1),
      );

      await repository.skipCurrentCycle(recurring.syncId);

      // Verify schedule was advanced to next month
      final updated = await repository.getBySyncId(recurring.syncId);
      expect(updated?.nextDueDate, equals(DateTime(2026, 12, 1)));
      expect(updated?.occurrenceCount, equals(0)); // Did not increment occurrenceCount

      // Verify no transaction was created and wallet balance unchanged
      final txCount = await isar.transactions.filter().recurringSyncIdEqualTo(recurring.syncId).count();
      expect(txCount, equals(0));

      final updatedWallet = await isar.wallets.filter().syncIdEqualTo('wallet_skip').findFirst();
      expect(updatedWallet?.balance, equals(500000));
    });

    test('Deactivates recurring schedule when maxOccurrences is reached', () async {
      final wallet = Wallet()
        ..syncId = 'wallet_max_test'
        ..name = 'BCA'
        ..balance = 500000
        ..isActive = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await isar.writeTxn(() async {
        await isar.wallets.put(wallet);
      });

      final recurring = await repository.createRecurring(
        type: 'EXPENSE',
        amount: 50000,
        walletSyncId: 'wallet_max_test',
        frequency: 'MONTHLY',
        startDate: DateTime(2026, 11, 1),
        maxOccurrences: 1, // Only 1 occurrence
      );

      await repository.executeRecurring(
        recurringSyncId: recurring.syncId,
        executionDate: DateTime(2026, 11, 1),
      );

      final updated = await repository.getBySyncId(recurring.syncId);
      expect(updated?.occurrenceCount, equals(1));
      expect(updated?.isActive, isFalse); // Completed and deactivated
    });
  });
}
