import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/exceptions/locked_period_exception.dart';
import '../../settings/domain/app_settings.dart';
import '../../transaction/domain/transaction.dart';
import '../../wallet/domain/wallet.dart';
import '../domain/debt.dart';

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return DebtRepository(isar);
});

class DebtSummary {
  final double totalPayable;
  final double paidPayable;
  final double remainingPayable;
  final double totalReceivable;
  final double paidReceivable;
  final double remainingReceivable;
  final int overdueCount;

  const DebtSummary({
    required this.totalPayable,
    required this.paidPayable,
    required this.remainingPayable,
    required this.totalReceivable,
    required this.paidReceivable,
    required this.remainingReceivable,
    required this.overdueCount,
  });

  const DebtSummary.empty()
      : totalPayable = 0.0,
        paidPayable = 0.0,
        remainingPayable = 0.0,
        totalReceivable = 0.0,
        paidReceivable = 0.0,
        remainingReceivable = 0.0,
        overdueCount = 0;
}

class DebtRepository {
  final Isar _isar;
  final _uuid = const Uuid();

  DebtRepository(this._isar);

  /// Watch active debts, optionally filtered by type ('PAYABLE' or 'RECEIVABLE')
  Stream<List<Debt>> watchActiveDebts({String? type}) {
    var query = _isar.debts.filter().isActiveEqualTo(true);
    if (type != null && type != 'ALL') {
      query = query.typeEqualTo(type);
    }
    return query.sortByCreatedAtDesc().watch(fireImmediately: true);
  }

  /// Get active debts
  Future<List<Debt>> getActiveDebts({String? type}) async {
    var query = _isar.debts.filter().isActiveEqualTo(true);
    if (type != null && type != 'ALL') {
      query = query.typeEqualTo(type);
    }
    return await query.sortByCreatedAtDesc().findAll();
  }

  /// Find debt by id
  Future<Debt?> getDebtById(int id) async {
    return await _isar.debts.get(id);
  }

  /// Find debt by syncId
  Future<Debt?> getDebtBySyncId(String syncId) async {
    return await _isar.debts.filter().syncIdEqualTo(syncId).findFirst();
  }

  /// Calculate summary of all active debts and receivables
  Future<DebtSummary> calculateDebtSummary() async {
    final debts = await _isar.debts.filter().isActiveEqualTo(true).findAll();
    if (debts.isEmpty) {
      return const DebtSummary.empty();
    }

    // Convert to lightweight data for Isolate calculation if needed
    final rawData = debts.map((d) => {
      'type': d.type,
      'totalAmount': d.totalAmount,
      'paidAmount': d.paidAmount,
      'dueDate': d.dueDate?.millisecondsSinceEpoch,
    }).toList();

    if (kIsWeb || rawData.length < 50) {
      return _computeSummary(rawData);
    }

    return await Isolate.run(() => _computeSummary(rawData));
  }

  static DebtSummary _computeSummary(List<Map<String, dynamic>> items) {
    double totalPayable = 0.0;
    double paidPayable = 0.0;
    double totalReceivable = 0.0;
    double paidReceivable = 0.0;
    int overdueCount = 0;
    final now = DateTime.now();

    for (final item in items) {
      final type = item['type'] as String;
      final total = item['totalAmount'] as double;
      final paid = item['paidAmount'] as double;
      final dueMillis = item['dueDate'] as int?;

      final isCompleted = paid >= total;

      if (type == 'PAYABLE') {
        totalPayable += total;
        paidPayable += paid;
      } else if (type == 'RECEIVABLE') {
        totalReceivable += total;
        paidReceivable += paid;
      }

      if (!isCompleted && dueMillis != null) {
        final dueDate = DateTime.fromMillisecondsSinceEpoch(dueMillis);
        if (now.isAfter(dueDate)) {
          overdueCount++;
        }
      }
    }

    return DebtSummary(
      totalPayable: totalPayable,
      paidPayable: paidPayable,
      remainingPayable: totalPayable - paidPayable,
      totalReceivable: totalReceivable,
      paidReceivable: paidReceivable,
      remainingReceivable: totalReceivable - paidReceivable,
      overdueCount: overdueCount,
    );
  }

  /// Create a new Debt or Receivable record
  Future<Debt> createDebt({
    required String type, // 'PAYABLE' or 'RECEIVABLE'
    required String contactSyncId,
    required String title,
    required double totalAmount,
    required DateTime startDate,
    DateTime? dueDate,
    String? notes,
    String? walletSyncId,
    bool affectWallet = false,
  }) async {
    // 1. Period locking check (AGENTS.md §4)
    final settings = await _isar.appSettings.where().findFirst();
    if (settings?.lockedUntil != null && !startDate.isAfter(settings!.lockedUntil!)) {
      throw LockedPeriodException();
    }

    final now = DateTime.now();
    final debt = Debt()
      ..syncId = _uuid.v4()
      ..type = type
      ..contactSyncId = contactSyncId
      ..title = title.trim()
      ..totalAmount = totalAmount
      ..paidAmount = 0.0
      ..startDate = startDate
      ..dueDate = dueDate
      ..notes = notes?.trim().isEmpty == true ? null : notes?.trim()
      ..isActive = true
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      // If user chooses to immediately affect the wallet balance:
      if (affectWallet && walletSyncId != null && walletSyncId.isNotEmpty) {
        final wallet = await _isar.wallets.filter().syncIdEqualTo(walletSyncId).findFirst();
        if (wallet == null) {
          throw Exception('Dompet tidak ditemukan.');
        }

        final tx = Transaction()
          ..syncId = _uuid.v4()
          ..amount = totalAmount
          ..date = startDate
          ..walletSyncId = walletSyncId
          ..debtSyncId = debt.syncId
          ..createdAt = now
          ..updatedAt = now;

        if (type == 'PAYABLE') {
          // Uang pinjaman masuk ke dompet kita -> Income
          wallet.balance += totalAmount;
          tx.type = 'INCOME';
          tx.description = 'Pinjaman Utang: $title';
        } else {
          // Uang kita pinjamkan keluar -> Expense
          wallet.balance -= totalAmount;
          tx.type = 'EXPENSE';
          tx.description = 'Pinjaman Piutang: $title';
        }

        wallet.updatedAt = now;
        await _isar.wallets.put(wallet);
        await _isar.transactions.put(tx);
      }

      await _isar.debts.put(debt);
    });

    return debt;
  }

  /// Record an installment or full payment for a Debt / Receivable
  Future<void> recordPayment({
    required int debtId,
    required double paymentAmount,
    required DateTime date,
    required String walletSyncId,
    String? notes,
  }) async {
    // 1. Period locking check
    final settings = await _isar.appSettings.where().findFirst();
    if (settings?.lockedUntil != null && !date.isAfter(settings!.lockedUntil!)) {
      throw LockedPeriodException();
    }

    final debt = await _isar.debts.get(debtId);
    if (debt == null) {
      throw Exception('Catatan utang/piutang tidak ditemukan.');
    }

    final remaining = debt.totalAmount - debt.paidAmount;
    if (paymentAmount <= 0) {
      throw Exception('Nominal pembayaran harus lebih dari 0.');
    }
    if (paymentAmount > remaining + 0.01) { // small tolerance for floating point
      throw Exception('Nominal pembayaran melebihi sisa kewajiban.');
    }

    final wallet = await _isar.wallets.filter().syncIdEqualTo(walletSyncId).findFirst();
    if (wallet == null) {
      throw Exception('Dompet tidak ditemukan.');
    }

    final now = DateTime.now();

    await _isar.writeTxn(() async {
      final tx = Transaction()
        ..syncId = _uuid.v4()
        ..amount = paymentAmount
        ..date = date
        ..walletSyncId = walletSyncId
        ..debtSyncId = debt.syncId
        ..createdAt = now
        ..updatedAt = now;

      if (debt.type == 'PAYABLE') {
        // Kita bayar utang -> Saldo dompet berkurang (EXPENSE)
        wallet.balance -= paymentAmount;
        tx.type = 'EXPENSE';
        tx.description = 'Bayar Utang: ${debt.title}${notes != null && notes.isNotEmpty ? " ($notes)" : ""}';
      } else {
        // Kita terima cicilan piutang -> Saldo dompet bertambah (INCOME)
        wallet.balance += paymentAmount;
        tx.type = 'INCOME';
        tx.description = 'Terima Piutang: ${debt.title}${notes != null && notes.isNotEmpty ? " ($notes)" : ""}';
      }

      debt.paidAmount += paymentAmount;
      debt.updatedAt = now;
      wallet.updatedAt = now;

      await _isar.wallets.put(wallet);
      await _isar.transactions.put(tx);
      await _isar.debts.put(debt);
    });
  }

  /// Update metadata of an existing debt
  Future<Debt> updateDebt({
    required int id,
    required String title,
    required double totalAmount,
    DateTime? dueDate,
    String? notes,
  }) async {
    final debt = await _isar.debts.get(id);
    if (debt == null) {
      throw Exception('Catatan utang/piutang tidak ditemukan.');
    }

    // Period locking check
    final settings = await _isar.appSettings.where().findFirst();
    if (settings?.lockedUntil != null && !debt.startDate.isAfter(settings!.lockedUntil!)) {
      throw LockedPeriodException();
    }

    if (totalAmount < debt.paidAmount) {
      throw Exception('Total nominal tidak boleh lebih kecil dari jumlah yang sudah dibayar/diterima.');
    }

    debt.title = title.trim();
    debt.totalAmount = totalAmount;
    debt.dueDate = dueDate;
    debt.notes = notes?.trim().isEmpty == true ? null : notes?.trim();
    debt.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.debts.put(debt);
    });

    return debt;
  }

  /// Soft delete a debt record
  Future<void> softDeleteDebt(int id) async {
    final debt = await _isar.debts.get(id);
    if (debt == null) {
      throw Exception('Catatan utang/piutang tidak ditemukan.');
    }

    // Period locking check
    final settings = await _isar.appSettings.where().findFirst();
    if (settings?.lockedUntil != null && !debt.startDate.isAfter(settings!.lockedUntil!)) {
      throw LockedPeriodException();
    }

    debt.isActive = false;
    debt.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.debts.put(debt);
    });
  }
}
