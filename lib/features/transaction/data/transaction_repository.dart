import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/exceptions/locked_period_exception.dart';
import '../../category/domain/category.dart';
import '../../settings/domain/app_settings.dart';
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

  /// Add standard INCOME or EXPENSE transaction
  Future<Transaction> addTransaction({
    required String type,
    required double amount,
    required DateTime date,
    required String walletSyncId,
    String? categorySyncId,
    String? description,
  }) async {
    // 1. Period locking check (AGENTS.md §4)
    final settings = await _isar.appSettings.where().findFirst();
    if (settings?.lockedUntil != null && !date.isAfter(settings!.lockedUntil!)) {
      throw LockedPeriodException();
    }

    final wallet = await _isar.wallets.filter().syncIdEqualTo(walletSyncId).findFirst();
    if (wallet == null) {
      throw Exception('Dompet tidak ditemukan.');
    }

    final now = DateTime.now();
    final tx = Transaction()
      ..syncId = _uuid.v4()
      ..type = type
      ..amount = amount
      ..date = date
      ..walletSyncId = walletSyncId
      ..categorySyncId = categorySyncId
      ..description = description
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      if (type == 'INCOME') {
        wallet.balance += amount;
      } else if (type == 'EXPENSE') {
        wallet.balance -= amount;
      }
      wallet.updatedAt = now;

      await _isar.wallets.put(wallet);
      await _isar.transactions.put(tx);
    });

    return tx;
  }

  /// Transfer antar dompet reguler menggunakan 3-Transaction Transfer Pattern (AGENTS.md §4)
  Future<void> transferBetweenWallets({
    required String sourceWalletSyncId,
    required String destinationWalletSyncId,
    required double amount,
    required DateTime date,
    double adminFee = 0.0,
    String? description,
  }) async {
    // 1. Period locking check (AGENTS.md §4)
    final settings = await _isar.appSettings.where().findFirst();
    if (settings?.lockedUntil != null && !date.isAfter(settings!.lockedUntil!)) {
      throw LockedPeriodException();
    }

    if (sourceWalletSyncId == destinationWalletSyncId) {
      throw Exception('Dompet sumber dan tujuan tidak boleh sama.');
    }

    if (amount <= 0) {
      throw Exception('Nominal transfer harus lebih dari 0.');
    }

    final sourceWallet = await _isar.wallets.filter().syncIdEqualTo(sourceWalletSyncId).findFirst();
    final destWallet = await _isar.wallets.filter().syncIdEqualTo(destinationWalletSyncId).findFirst();

    if (sourceWallet == null || destWallet == null) {
      throw Exception('Dompet sumber atau dompet tujuan tidak ditemukan.');
    }

    final now = DateTime.now();
    final groupId = _uuid.v4();

    // Cari kategori transfer fee jika ada admin fee
    String? feeCatSyncId;
    if (adminFee > 0) {
      final feeCat = await _isar.categorys.filter().syncIdEqualTo('cat_transfer_fee').findFirst();
      feeCatSyncId = feeCat?.syncId;
    }

    await _isar.writeTxn(() async {
      // 1. Potong saldo dompet sumber
      sourceWallet.balance -= amount;
      if (adminFee > 0) {
        sourceWallet.balance -= adminFee;
      }
      sourceWallet.updatedAt = now;
      await _isar.wallets.put(sourceWallet);

      // 2. Tambah saldo dompet tujuan
      destWallet.balance += amount;
      destWallet.updatedAt = now;
      await _isar.wallets.put(destWallet);

      // 3. Buat TRANSFER_OUT pada dompet sumber
      final outDesc = description != null && description.isNotEmpty
          ? 'Transfer ke ${destWallet.name} ($description)'
          : 'Transfer ke ${destWallet.name}';

      final outTx = Transaction()
        ..syncId = _uuid.v4()
        ..type = 'TRANSFER_OUT'
        ..amount = amount
        ..date = date
        ..walletSyncId = sourceWalletSyncId
        ..transactionGroupId = groupId
        ..description = outDesc
        ..createdAt = now
        ..updatedAt = now;

      // 4. Buat TRANSFER_IN pada dompet tujuan
      final inDesc = description != null && description.isNotEmpty
          ? 'Transfer dari ${sourceWallet.name} ($description)'
          : 'Transfer dari ${sourceWallet.name}';

      final inTx = Transaction()
        ..syncId = _uuid.v4()
        ..type = 'TRANSFER_IN'
        ..amount = amount
        ..date = date
        ..walletSyncId = destinationWalletSyncId
        ..transactionGroupId = groupId
        ..description = inDesc
        ..createdAt = now
        ..updatedAt = now;

      await _isar.transactions.put(outTx);
      await _isar.transactions.put(inTx);

      // 5. Catat EXPENSE untuk biaya admin jika ada (AGENTS.md §4)
      if (adminFee > 0) {
        final feeTx = Transaction()
          ..syncId = _uuid.v4()
          ..type = 'EXPENSE'
          ..amount = adminFee
          ..date = date
          ..walletSyncId = sourceWalletSyncId
          ..categorySyncId = feeCatSyncId
          ..transactionGroupId = groupId
          ..description = 'Biaya Transfer ke ${destWallet.name}'
          ..createdAt = now
          ..updatedAt = now;

        await _isar.transactions.put(feeTx);
      }
    });
  }

  /// Menabung ke Tujuan Tabungan menggunakan 3-Transaction Transfer Pattern (AGENTS.md §4)
  Future<void> allocateSavings({
    required String sourceWalletSyncId,
    required String goalWalletSyncId,
    required double amount,
    required DateTime date,
  }) async {
    // 1. Period locking check (AGENTS.md §4)
    final settings = await _isar.appSettings.where().findFirst();
    if (settings?.lockedUntil != null && !date.isAfter(settings!.lockedUntil!)) {
      throw LockedPeriodException();
    }

    if (amount <= 0) {
      throw Exception('Nominal tabungan harus lebih dari 0.');
    }

    final sourceWallet = await _isar.wallets.filter().syncIdEqualTo(sourceWalletSyncId).findFirst();
    final goalWallet = await _isar.wallets.filter().syncIdEqualTo(goalWalletSyncId).findFirst();

    if (sourceWallet == null || goalWallet == null) {
      throw Exception('Kantong sumber atau Kantong tujuan tidak ditemukan.');
    }

    if (sourceWallet.balance < amount) {
      throw Exception('Saldo kantong "${sourceWallet.name}" tidak mencukupi untuk menabung.');
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

  /// Tarik Dana / Realisasi Tabungan dari Target Tabungan ke Dompet Reguler (AGENTS.md §4)
  Future<void> withdrawSavings({
    required String goalWalletSyncId,
    required String destinationWalletSyncId,
    required double amount,
    required DateTime date,
    String? notes,
  }) async {
    // 1. Period locking check (AGENTS.md §4)
    final settings = await _isar.appSettings.where().findFirst();
    if (settings?.lockedUntil != null && !date.isAfter(settings!.lockedUntil!)) {
      throw LockedPeriodException();
    }

    if (amount <= 0) {
      throw Exception('Nominal penarikan harus lebih dari 0.');
    }

    final goalWallet = await _isar.wallets.filter().syncIdEqualTo(goalWalletSyncId).findFirst();
    final destWallet = await _isar.wallets.filter().syncIdEqualTo(destinationWalletSyncId).findFirst();

    if (goalWallet == null || destWallet == null) {
      throw Exception('Target tabungan atau dompet tujuan tidak ditemukan.');
    }

    if (goalWallet.balance < amount) {
      throw Exception('Saldo tabungan "${goalWallet.name}" tidak mencukupi untuk ditarik.');
    }

    final now = DateTime.now();
    final groupId = _uuid.v4();

    await _isar.writeTxn(() async {
      // 1. Potong saldo goal
      goalWallet.balance -= amount;
      goalWallet.updatedAt = now;
      await _isar.wallets.put(goalWallet);

      // 2. Tambah saldo dompet reguler penerima dana
      destWallet.balance += amount;
      destWallet.updatedAt = now;
      await _isar.wallets.put(destWallet);

      // 3. Catat TRANSFER_OUT dari goal wallet
      final outDesc = notes != null && notes.isNotEmpty
          ? 'Pencairan ke ${destWallet.name} ($notes)'
          : 'Pencairan ke ${destWallet.name}';

      final outTx = Transaction()
        ..syncId = _uuid.v4()
        ..type = 'TRANSFER_OUT'
        ..amount = amount
        ..date = date
        ..walletSyncId = goalWalletSyncId
        ..transactionGroupId = groupId
        ..description = outDesc
        ..createdAt = now
        ..updatedAt = now;

      // 4. Catat TRANSFER_IN ke destination wallet
      final inDesc = notes != null && notes.isNotEmpty
          ? 'Pencairan tabungan dari ${goalWallet.name} ($notes)'
          : 'Pencairan tabungan dari ${goalWallet.name}';

      final inTx = Transaction()
        ..syncId = _uuid.v4()
        ..type = 'TRANSFER_IN'
        ..amount = amount
        ..date = date
        ..walletSyncId = destinationWalletSyncId
        ..transactionGroupId = groupId
        ..description = inDesc
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

    if (transactions.isEmpty) {
      return const MonthlySummary(totalIncome: 0.0, totalExpense: 0.0);
    }

    // For Web or small transaction counts, compute directly on main thread
    if (kIsWeb || transactions.length < 50) {
      double income = 0.0;
      double expense = 0.0;

      for (final tx in transactions) {
        if (tx.type == 'INCOME') {
          income += tx.amount;
        } else if (tx.type == 'EXPENSE') {
          expense += tx.amount;
        }
      }

      return MonthlySummary(
        totalIncome: income,
        totalExpense: expense,
      );
    }

    // Map to lightweight isolate data to avoid pass-by-reference issues
    final transactionData = transactions.map((t) => {
      'type': t.type,
      'amount': t.amount,
    }).toList();

    // Execute aggregation inside Isolate.run() for large datasets (AGENTS.md §5)
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

  /// Watch transactions for a given month with optional wallet and type filters
  Stream<List<Transaction>> watchTransactionsByMonth(
    int year,
    int month, {
    String? walletSyncId,
    String? typeFilter,
  }) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1).subtract(const Duration(microseconds: 1));

    var query = _isar.transactions
        .filter()
        .dateBetween(startDate, endDate);

    if (walletSyncId != null && walletSyncId.isNotEmpty) {
      query = query.walletSyncIdEqualTo(walletSyncId);
    }

    if (typeFilter != null && typeFilter.isNotEmpty && typeFilter != 'ALL') {
      if (typeFilter == 'TRANSFER' || typeFilter == 'TRANSFER_OUT') {
        query = query.group((q) => q.typeEqualTo('TRANSFER_OUT').or().typeEqualTo('TRANSFER_IN'));
      } else {
        query = query.typeEqualTo(typeFilter);
      }
    }

    return query.sortByDateDesc().watch(fireImmediately: true);
  }

  /// Delete transaction using the Reversal Pattern (AGENTS.md §4)
  Future<void> deleteTransaction(int transactionId) async {
    final tx = await _isar.transactions.get(transactionId);
    if (tx == null) return;

    // Period locking check
    final settings = await _isar.appSettings.where().findFirst();
    if (settings?.lockedUntil != null && !tx.date.isAfter(settings!.lockedUntil!)) {
      throw LockedPeriodException();
    }

    await _isar.writeTxn(() async {
      if (tx.transactionGroupId != null && tx.transactionGroupId!.isNotEmpty) {
        // Grouped transaction (e.g., Transfer / Savings)
        final groupTxs = await _isar.transactions
            .filter()
            .transactionGroupIdEqualTo(tx.transactionGroupId!)
            .findAll();

        for (final groupTx in groupTxs) {
          final wallet = await _isar.wallets
              .filter()
              .syncIdEqualTo(groupTx.walletSyncId)
              .findFirst();

          if (wallet != null) {
            if (groupTx.type == 'TRANSFER_OUT' || groupTx.type == 'EXPENSE') {
              wallet.balance += groupTx.amount;
            } else if (groupTx.type == 'TRANSFER_IN' || groupTx.type == 'INCOME') {
              wallet.balance -= groupTx.amount;
            }
            wallet.updatedAt = DateTime.now();
            await _isar.wallets.put(wallet);
          }
          await _isar.transactions.delete(groupTx.id);
        }
      } else {
        // Standalone Income / Expense
        final wallet = await _isar.wallets
            .filter()
            .syncIdEqualTo(tx.walletSyncId)
            .findFirst();

        if (wallet != null) {
          if (tx.type == 'INCOME') {
            wallet.balance -= tx.amount;
          } else if (tx.type == 'EXPENSE') {
            wallet.balance += tx.amount;
          }
          wallet.updatedAt = DateTime.now();
          await _isar.wallets.put(wallet);
        }
        await _isar.transactions.delete(tx.id);
      }
    });
  }

  /// Update existing transaction using the Reversal Pattern (AGENTS.md §4)
  Future<void> updateTransaction({
    required int id,
    required String type,
    required double amount,
    required DateTime date,
    required String walletSyncId,
    String? categorySyncId,
    String? description,
  }) async {
    final oldTx = await _isar.transactions.get(id);
    if (oldTx == null) {
      throw Exception('Transaksi tidak ditemukan.');
    }

    // Period locking check for both old & new date
    final settings = await _isar.appSettings.where().findFirst();
    final lockedUntil = settings?.lockedUntil;
    if (lockedUntil != null) {
      if (!oldTx.date.isAfter(lockedUntil) || !date.isAfter(lockedUntil)) {
        throw LockedPeriodException();
      }
    }


    final now = DateTime.now();

    await _isar.writeTxn(() async {
      // 1. Revert old transaction effect on old wallet
      final oldWallet = await _isar.wallets
          .filter()
          .syncIdEqualTo(oldTx.walletSyncId)
          .findFirst();

      if (oldWallet != null) {
        if (oldTx.type == 'INCOME') {
          oldWallet.balance -= oldTx.amount;
        } else if (oldTx.type == 'EXPENSE') {
          oldWallet.balance += oldTx.amount;
        }
        oldWallet.updatedAt = now;
        await _isar.wallets.put(oldWallet);
      }

      // 2. Apply new transaction effect on new (or same) wallet
      final newWallet = (oldWallet != null && oldWallet.syncId == walletSyncId)
          ? oldWallet
          : await _isar.wallets.filter().syncIdEqualTo(walletSyncId).findFirst();

      if (newWallet == null) {
        throw Exception('Dompet tidak ditemukan.');
      }

      if (type == 'INCOME') {
        newWallet.balance += amount;
      } else if (type == 'EXPENSE') {
        newWallet.balance -= amount;
      }
      newWallet.updatedAt = now;
      await _isar.wallets.put(newWallet);

      // 3. Update the transaction record
      oldTx
        ..type = type
        ..amount = amount
        ..date = date
        ..walletSyncId = walletSyncId
        ..categorySyncId = categorySyncId
        ..description = description
        ..updatedAt = now;

      await _isar.transactions.put(oldTx);
    });
  }
}

