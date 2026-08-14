import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:catatuang/features/budget/data/budget_repository.dart';
import 'package:catatuang/features/budget/domain/budget.dart';
import 'package:catatuang/features/category/domain/category.dart';
import 'package:catatuang/features/contact/domain/contact.dart';
import 'package:catatuang/features/debt/domain/debt.dart';
import 'package:catatuang/features/notification/data/notification_repository.dart';
import 'package:catatuang/features/search/data/search_repository.dart';
import 'package:catatuang/features/settings/domain/app_settings.dart';
import 'package:catatuang/features/transaction/domain/transaction.dart';
import 'package:catatuang/features/wallet/domain/wallet.dart';

void main() {
  late Isar isar;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    isar = await Isar.open(
      [
        WalletSchema,
        CategorySchema,
        ContactSchema,
        DebtSchema,
        TransactionSchema,
        AppSettingsSchema,
        BudgetSchema,
      ],
      directory: '',
    );
  });

  tearDownAll(() async {
    await isar.close(deleteFromDisk: true);
  });

  setUp(() async {
    await isar.writeTxn(() async {
      await isar.clear();
    });
  });

  test('BudgetRepository calculates summary safely across Isolate with large data', () async {
    final now = DateTime.now();
    final repo = BudgetRepository(isar);

    await isar.writeTxn(() async {
      // Create 25 categories and budgets
      for (int i = 0; i < 25; i++) {
        final cat = Category()
          ..syncId = 'cat_$i'
          ..name = 'Kategori $i'
          ..type = 'EXPENSE'
          ..icon = 'category'
          ..colorValue = 0xFFFF0000
          ..isActive = true
          ..createdAt = now
          ..updatedAt = now;
        await isar.categorys.put(cat);

        final b = Budget()
          ..syncId = 'b_$i'
          ..categorySyncId = 'cat_$i'
          ..monthlyLimit = 100000
          ..year = now.year
          ..month = now.month
          ..isActive = true
          ..createdAt = now
          ..updatedAt = now;
        await isar.budgets.put(b);
      }

      // Create 60 expense transactions for cat_0 (triggers isolate threshold)
      for (int i = 0; i < 60; i++) {
        final tx = Transaction()
          ..syncId = 'tx_$i'
          ..type = 'EXPENSE'
          ..amount = 1000
          ..date = now
          ..walletSyncId = 'w_1'
          ..categorySyncId = 'cat_0'
          ..createdAt = now
          ..updatedAt = now;
        await isar.transactions.put(tx);
      }
    });

    final summary = await repo.calculateMonthlyBudgetSummary(now.year, now.month);
    expect(summary.items.isNotEmpty, true);
    expect(summary.totalBudgetSpent, 60000.0);
  });

  test('NotificationRepository computes reminders safely across Isolate with large data', () async {
    final now = DateTime.now();
    final repo = NotificationRepository(isar);

    await isar.writeTxn(() async {
      final contact = Contact()
        ..syncId = 'c_1'
        ..name = 'Teman'
        ..isActive = true
        ..createdAt = now
        ..updatedAt = now;
      await isar.contacts.put(contact);

      // Create 60 active debts with due dates (triggers isolate threshold)
      for (int i = 0; i < 60; i++) {
        final debt = Debt()
          ..syncId = 'd_$i'
          ..title = 'Utang $i'
          ..type = 'PAYABLE'
          ..contactSyncId = 'c_1'
          ..totalAmount = 50000
          ..paidAmount = 0
          ..startDate = now.subtract(const Duration(days: 10))
          ..dueDate = now.add(const Duration(days: 1))
          ..isActive = true
          ..createdAt = now
          ..updatedAt = now;
        await isar.debts.put(debt);
      }
    });

    final reminders = await repo.getActiveDebtReminders();
    expect(reminders.length, 60);
  });

  test('SearchRepository filters and matches safely across Isolate with large data', () async {
    final now = DateTime.now();
    final repo = SearchRepository(isar);

    await isar.writeTxn(() async {
      final wallet = Wallet()
        ..syncId = 'w_1'
        ..name = 'Dompet Utama'
        ..balance = 1000000
        ..isActive = true
        ..createdAt = now
        ..updatedAt = now;
      await isar.wallets.put(wallet);

      final cat = Category()
        ..syncId = 'cat_1'
        ..name = 'Belanja'
        ..type = 'EXPENSE'
        ..icon = 'shopping_bag'
        ..colorValue = 0xFF5D5CFF
        ..isActive = true
        ..createdAt = now
        ..updatedAt = now;
      await isar.categorys.put(cat);

      // Create 120 transactions (triggers isolate threshold)
      for (int i = 0; i < 120; i++) {
        final tx = Transaction()
          ..syncId = 'tx_search_$i'
          ..type = 'EXPENSE'
          ..amount = 25000
          ..date = now
          ..description = i % 2 == 0 ? 'Kopi Kenangan' : 'Makan Siang'
          ..walletSyncId = 'w_1'
          ..categorySyncId = 'cat_1'
          ..createdAt = now
          ..updatedAt = now;
        await isar.transactions.put(tx);
      }
    });

    final searchResult = await repo.search(query: 'Kopi');
    expect(searchResult.transactions.length, 60);
    expect(searchResult.totalExpense, 60 * 25000.0);
  });
}
