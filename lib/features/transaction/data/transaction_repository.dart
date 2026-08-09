import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database_provider.dart';
import '../../wallet/domain/wallet.dart';
import '../domain/transaction.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return TransactionRepository(isar);
});

class MonthlySummary {
  final double totalIncome;
  final double totalExpense;

  const MonthlySummary({
    required this.totalIncome,
    required this.totalExpense,
  });
}

class TransactionRepository {
  final Isar _isar;
  final _uuid = const Uuid();

  TransactionRepository(this._isar);

  /// Watch recent transactions sorted by date descending
  Stream<List<Transaction>> watchRecentTransactions({int limit = 10}) {
    return _isar.transactions
        .where()
        .sortByDateDesc()
        .limit(limit)
        .watch(fireImmediately: true);
  }

  /// Watch all transactions stream for real-time aggregation recalculation
  Stream<void> watchTransactionsChanged() {
    return _isar.transactions.watchLazy(fireImmediately: true);
  }

  /// Menabung ke Tujuan Tabungan menggunakan 3-Transaction Transfer Pattern (AGENTS.md §4)
  Future<void> allocateSavings({
    required String sourceWalletSyncId,
    required String goalWalletSyncId,
    required double amount,
    required DateTime date,
  }) async {
    final sourceWallet = await _isar.wallets.filter().syncIdEqualTo(sourceWalletSyncId).findFirst();
    final goalWallet = await _isar.wallets.filter().syncIdEqualTo(goalWalletSyncId).findFirst();

    if (sourceWallet == null || goalWallet == null) {
      throw Exception('Kantong sumber atau Kantong tujuan tidak ditemukan.');
    }

    final now = DateTime.now();
    final groupId = _uuid.v4();

    await _isar.writeTxn(() async {
      // 1. Potong saldo dompet sumber
      sourceWallet.balance -= amount;
      sourceWallet.updatedAt = now;
      await _isar.wallets.put(sourceWallet);

      // 2. Tambah saldo dompet tujuan tabungan
      goalWallet.balance += amount;
      goalWallet.updatedAt = now;
      await _isar.wallets.put(goalWallet);

      // 3. Buat catatan transaksi TRANSFER_OUT pada dompet sumber
      final outTx = Transaction()
        ..syncId = _uuid.v4()
        ..type = 'TRANSFER_OUT'
        ..amount = amount
        ..date = date
        ..walletSyncId = sourceWalletSyncId
        ..transactionGroupId = groupId
        ..description = 'Menabung ke ${goalWallet.name}'
        ..createdAt = now
        ..updatedAt = now;

      // 4. Buat catatan transaksi TRANSFER_IN pada dompet tujuan
      final inTx = Transaction()
        ..syncId = _uuid.v4()
        ..type = 'TRANSFER_IN'
        ..amount = amount
        ..date = date
        ..walletSyncId = goalWalletSyncId
        ..transactionGroupId = groupId
        ..description = 'Tabungan dari ${sourceWallet.name}'
        ..createdAt = now
        ..updatedAt = now;

      await _isar.transactions.put(outTx);
      await _isar.transactions.put(inTx);
    });
  }

  /// Calculate monthly total income and expense off-main-thread using Isolate.run()
  Future<MonthlySummary> calculateMonthlySummary(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1).subtract(const Duration(microseconds: 1));

    // Fetch raw transactions for the month
    final transactions = await _isar.transactions
        .filter()
        .dateBetween(startDate, endDate)
        .findAll();

    // Map to lightweight isolate data to avoid pass-by-reference issues
    final transactionData = transactions.map((t) => {
      'type': t.type,
      'amount': t.amount,
    }).toList();

    // Execute aggregation inside Isolate.run() to prevent UI jank (AGENTS.md §5)
    return await Isolate.run(() {
      double income = 0.0;
      double expense = 0.0;

      for (final tx in transactionData) {
        final type = tx['type'] as String;
        final amount = tx['amount'] as double;

        if (type == 'INCOME') {
          income += amount;
        } else if (type == 'EXPENSE') {
          expense += amount;
        }
      }

      return MonthlySummary(
        totalIncome: income,
        totalExpense: expense,
      );
    });
  }
}
