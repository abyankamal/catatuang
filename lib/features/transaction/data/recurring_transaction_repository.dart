import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database_provider.dart';
import '../../category/domain/category.dart';
import '../../settings/domain/app_settings.dart';
import '../../wallet/domain/wallet.dart';
import '../domain/recurring_schedule_helper.dart';
import '../domain/recurring_transaction.dart';
import '../domain/transaction.dart';

final recurringTransactionRepositoryProvider = Provider<RecurringTransactionRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return RecurringTransactionRepository(isar);
});

class RecurringTransactionRepository {
  final Isar _isar;
  final _uuid = const Uuid();

  RecurringTransactionRepository(this._isar);

  /// Aliran data jadwal transaksi berulang yang aktif
  Stream<List<RecurringTransaction>> watchActiveRecurring() {
    return _isar.recurringTransactions
        .filter()
        .isActiveEqualTo(true)
        .sortByNextDueDate()
        .watch(fireImmediately: true);
  }

  /// Aliran seluruh jadwal transaksi berulang (aktif, dijeda, maupun selesai)
  Stream<List<RecurringTransaction>> watchAllRecurring() {
    return _isar.recurringTransactions
        .where()
        .sortByNextDueDate()
        .watch(fireImmediately: true);
  }

  /// Mengambil semua jadwal berulang yang aktif dan jatuh tempo pada atau sebelum batas akhir hari [untilDate]
  Future<List<RecurringTransaction>> getDueRecurring(DateTime untilDate) async {
    final normalizedUntil = RecurringScheduleHelper.endOfDay(untilDate);
    return await _isar.recurringTransactions
        .filter()
        .isActiveEqualTo(true)
        .and()
        .nextDueDateLessThan(normalizedUntil.add(const Duration(milliseconds: 1)))
        .sortByNextDueDate()
        .findAll();
  }

  /// Mengambil jadwal berulang berdasarkan syncId
  Future<RecurringTransaction?> getBySyncId(String syncId) async {
    return await _isar.recurringTransactions
        .filter()
        .syncIdEqualTo(syncId)
        .findFirst();
  }

  /// Membuat jadwal transaksi berulang baru
  Future<RecurringTransaction> createRecurring({
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
    if (amount <= 0 || !amount.isFinite) {
      throw ArgumentError('Nominal transaksi harus bernilai lebih dari 0 dan valid.');
    }

    final sourceWallet = await _isar.wallets.filter().syncIdEqualTo(walletSyncId).findFirst();
    if (sourceWallet == null) {
      throw Exception('Dompet sumber tidak ditemukan.');
    }
    if (!sourceWallet.isActive) {
      throw Exception('Tidak dapat menjadwalkan transaksi pada dompet yang dinonaktifkan.');
    }

    if (type == 'TRANSFER') {
      if (targetWalletSyncId == null || targetWalletSyncId.isEmpty) {
        throw ArgumentError('Dompet tujuan harus ditentukan untuk transaksi bertipe transfer.');
      }
      if (walletSyncId == targetWalletSyncId) {
        throw ArgumentError('Dompet sumber dan dompet tujuan tidak boleh sama.');
      }
      final targetWallet = await _isar.wallets.filter().syncIdEqualTo(targetWalletSyncId).findFirst();
      if (targetWallet == null || !targetWallet.isActive) {
        throw Exception('Dompet tujuan tidak ditemukan atau telah dinonaktifkan.');
      }
    }

    final now = DateTime.now();
    final recurring = RecurringTransaction()
      ..syncId = _uuid.v4()
      ..type = type
      ..amount = amount
      ..description = description
      ..walletSyncId = walletSyncId
      ..targetWalletSyncId = targetWalletSyncId
      ..categorySyncId = categorySyncId
      ..adminFee = adminFee
      ..frequency = frequency
      ..interval = interval < 1 ? 1 : interval
      ..startDate = startDate
      ..endDate = endDate
      ..maxOccurrences = maxOccurrences
      ..occurrenceCount = 0
      ..nextDueDate = startDate
      ..lastExecutedDate = null
      ..autoExecute = autoExecute
      ..isActive = true
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.recurringTransactions.put(recurring);
    });

    return recurring;
  }

  /// Memperbarui jadwal transaksi berulang
  Future<void> updateRecurring(RecurringTransaction updated) async {
    updated.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.recurringTransactions.put(updated);
    });
  }

  /// Menjeda (*pause*) atau mengaktifkan kembali (*resume*) jadwal
  Future<void> toggleActive(String syncId, bool isActive) async {
    final existing = await getBySyncId(syncId);
    if (existing == null) {
      throw Exception('Jadwal transaksi tidak ditemukan.');
    }

    existing.isActive = isActive;
    existing.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.recurringTransactions.put(existing);
    });
  }

  /// Menghapus jadwal berulang secara soft delete (menonaktifkan)
  Future<void> softDelete(String syncId) async {
    await toggleActive(syncId, false);
  }

  /// Menghapus jadwal berulang secara permanen dari Isar
  Future<void> hardDelete(String syncId) async {
    await _isar.writeTxn(() async {
      await _isar.recurringTransactions.filter().syncIdEqualTo(syncId).deleteAll();
    });
  }

  /// Melewati siklus saat ini tanpa mencatat transaksi dan langsung memajukan `nextDueDate`
  Future<void> skipCurrentCycle(String syncId) async {
    final existing = await getBySyncId(syncId);
    if (existing == null) {
      throw Exception('Jadwal transaksi tidak ditemukan.');
    }

    final now = DateTime.now();
    existing.nextDueDate = RecurringScheduleHelper.calculateNextDueDate(
      currentDueDate: existing.nextDueDate,
      frequency: existing.frequency,
      interval: existing.interval,
      anchorDay: existing.startDate.day,
    );

    if (RecurringScheduleHelper.isCompleted(existing)) {
      existing.isActive = false;
    }
    existing.updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.recurringTransactions.put(existing);
    });
  }

  /// Mengeksekusi jadwal transaksi berulang secara atomik (ACID):
  /// 1. Membuat transaksi riil (atau 3 record jika TRANSFER).
  /// 2. Memperbarui saldo dompet (diizinkan minus jika saldo kurang).
  /// 3. Menangani penyesuaian periode tutup buku (`lockedUntil`) jika jatuh di masa lalu.
  /// 4. Memajukan `nextDueDate`, menambah `occurrenceCount`, dan mengevaluasi `isCompleted`.
  Future<Transaction> executeRecurring({
    required String recurringSyncId,
    required DateTime executionDate,
    double? customAmount,
  }) async {
    final recurring = await getBySyncId(recurringSyncId);
    if (recurring == null) {
      throw Exception('Jadwal transaksi tidak ditemukan.');
    }
    if (!recurring.isActive) {
      throw Exception('Jadwal transaksi berulang sedang dinonaktifkan.');
    }

    final finalAmount = customAmount ?? recurring.amount;
    if (finalAmount <= 0 || !finalAmount.isFinite) {
      throw ArgumentError('Nominal transaksi harus bernilai lebih dari 0 dan valid.');
    }

    // 1. Periksa dompet sumber
    final sourceWallet = await _isar.wallets.filter().syncIdEqualTo(recurring.walletSyncId).findFirst();
    if (sourceWallet == null) {
      throw Exception('Dompet sumber tidak ditemukan.');
    }
    if (!sourceWallet.isActive) {
      throw Exception('Dompet sumber telah dinonaktifkan.');
    }

    // 2. Jika bertipe TRANSFER, periksa dompet tujuan dan cari kategori biaya transfer sebelum transaksi penulisan
    Wallet? destWallet;
    String? feeCatSyncId;
    final adminFee = recurring.adminFee ?? 0.0;

    if (recurring.type == 'TRANSFER') {
      destWallet = await _isar.wallets
          .filter()
          .syncIdEqualTo(recurring.targetWalletSyncId ?? '')
          .findFirst();

      if (destWallet == null || !destWallet.isActive) {
        throw Exception('Dompet tujuan transfer tidak ditemukan atau tidak aktif.');
      }

      if (adminFee > 0) {
        final feeCat = await _isar.categorys.filter().syncIdEqualTo('cat_transfer_fee').findFirst();
        feeCatSyncId = feeCat?.syncId;
      }
    }

    // 3. Periksa periode tutup buku (AGENTS.md §4) & transisi aman
    final settings = await _isar.appSettings.where().findFirst();
    final lockedUntil = settings?.lockedUntil;
    DateTime effectiveDate = executionDate;
    String auditNote = '';

    if (lockedUntil != null && !executionDate.isAfter(lockedUntil)) {
      // Tanggal jatuh tempo lampau berada pada periode tutup buku:
      // Alihkan tanggal ke awal periode terbuka dan tambahkan catatan audit
      effectiveDate = lockedUntil.add(const Duration(seconds: 1));
      final day = executionDate.day.toString().padLeft(2, '0');
      final month = executionDate.month.toString().padLeft(2, '0');
      final year = executionDate.year.toString();
      auditNote = ' (Dijadwalkan dari tanggal $day/$month/$year yang telah tutup buku)';
    }

    final now = DateTime.now();
    late Transaction primaryTx;

    await _isar.writeTxn(() async {
      final baseDesc = recurring.description != null && recurring.description!.isNotEmpty
          ? '${recurring.description}$auditNote'
          : auditNote.isNotEmpty
              ? auditNote.trim()
              : null;

      if (recurring.type == 'INCOME') {
        sourceWallet.balance += finalAmount;
        sourceWallet.updatedAt = now;
        await _isar.wallets.put(sourceWallet);

        primaryTx = Transaction()
          ..syncId = _uuid.v4()
          ..type = 'INCOME'
          ..amount = finalAmount
          ..date = effectiveDate
          ..walletSyncId = sourceWallet.syncId
          ..categorySyncId = recurring.categorySyncId
          ..recurringSyncId = recurring.syncId
          ..description = baseDesc
          ..createdAt = now
          ..updatedAt = now;

        await _isar.transactions.put(primaryTx);
      } else if (recurring.type == 'EXPENSE') {
        // Potong saldo (diizinkan minus sesuai preferensi pengguna)
        sourceWallet.balance -= finalAmount;
        sourceWallet.updatedAt = now;
        await _isar.wallets.put(sourceWallet);

        primaryTx = Transaction()
          ..syncId = _uuid.v4()
          ..type = 'EXPENSE'
          ..amount = finalAmount
          ..date = effectiveDate
          ..walletSyncId = sourceWallet.syncId
          ..categorySyncId = recurring.categorySyncId
          ..recurringSyncId = recurring.syncId
          ..description = baseDesc
          ..createdAt = now
          ..updatedAt = now;

        await _isar.transactions.put(primaryTx);
      } else if (recurring.type == 'TRANSFER') {
        final target = destWallet!;

        // Potong saldo dompet sumber (nominal + biaya admin)
        sourceWallet.balance -= (finalAmount + adminFee);
        sourceWallet.updatedAt = now;
        await _isar.wallets.put(sourceWallet);

        // Tambah saldo dompet tujuan
        target.balance += finalAmount;
        target.updatedAt = now;
        await _isar.wallets.put(target);

        final groupId = _uuid.v4();

        final outDesc = recurring.description != null && recurring.description!.isNotEmpty
            ? 'Transfer ke ${target.name} (${recurring.description})$auditNote'
            : 'Transfer ke ${target.name}$auditNote';

        final inDesc = recurring.description != null && recurring.description!.isNotEmpty
            ? 'Transfer dari ${sourceWallet.name} (${recurring.description})$auditNote'
            : 'Transfer dari ${sourceWallet.name}$auditNote';

        // 1. Record TRANSFER_OUT
        primaryTx = Transaction()
          ..syncId = _uuid.v4()
          ..type = 'TRANSFER_OUT'
          ..amount = finalAmount
          ..date = effectiveDate
          ..walletSyncId = sourceWallet.syncId
          ..recurringSyncId = recurring.syncId
          ..transactionGroupId = groupId
          ..description = outDesc
          ..createdAt = now
          ..updatedAt = now;

        // 2. Record TRANSFER_IN
        final inTx = Transaction()
          ..syncId = _uuid.v4()
          ..type = 'TRANSFER_IN'
          ..amount = finalAmount
          ..date = effectiveDate
          ..walletSyncId = target.syncId
          ..recurringSyncId = recurring.syncId
          ..transactionGroupId = groupId
          ..description = inDesc
          ..createdAt = now
          ..updatedAt = now;

        await _isar.transactions.put(primaryTx);
        await _isar.transactions.put(inTx);

        // 3. Record EXPENSE biaya admin jika ada (AGENTS.md §4)
        if (adminFee > 0) {
          final feeTx = Transaction()
            ..syncId = _uuid.v4()
            ..type = 'EXPENSE'
            ..amount = adminFee
            ..date = effectiveDate
            ..walletSyncId = sourceWallet.syncId
            ..categorySyncId = feeCatSyncId
            ..recurringSyncId = recurring.syncId
            ..transactionGroupId = groupId
            ..description = 'Biaya Transfer ke ${target.name}$auditNote'
            ..createdAt = now
            ..updatedAt = now;

          await _isar.transactions.put(feeTx);
        }
      }

      // 4. Majukan siklus pada RecurringTransaction
      recurring.occurrenceCount += 1;
      recurring.lastExecutedDate = effectiveDate;
      recurring.nextDueDate = RecurringScheduleHelper.calculateNextDueDate(
        currentDueDate: recurring.nextDueDate,
        frequency: recurring.frequency,
        interval: recurring.interval,
        anchorDay: recurring.startDate.day,
      );

      if (RecurringScheduleHelper.isCompleted(recurring)) {
        recurring.isActive = false;
      }
      recurring.updatedAt = now;

      await _isar.recurringTransactions.put(recurring);
    });

    return primaryTx;
  }
}
