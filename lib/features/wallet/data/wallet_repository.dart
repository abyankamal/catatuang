import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database_provider.dart';
import '../domain/wallet.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return WalletRepository(isar);
});

class WalletRepository {
  final Isar _isar;
  final _uuid = const Uuid();

  WalletRepository(this._isar);

  /// Watch semua kantong aktif (isActive == true)
  Stream<List<Wallet>> watchActiveWallets() {
    return _isar.wallets
        .filter()
        .isActiveEqualTo(true)
        .watch(fireImmediately: true);
  }

  /// Watch kantong reguler aktif (isActive == true && isGoal == false)
  Stream<List<Wallet>> watchActiveRegularWallets() {
    return _isar.wallets
        .filter()
        .isActiveEqualTo(true)
        .isGoalEqualTo(false)
        .watch(fireImmediately: true);
  }

  /// Watch semua tujuan tabungan aktif (isActive == true && isGoal == true)
  Stream<List<Wallet>> watchActiveGoals() {
    return _isar.wallets
        .filter()
        .isActiveEqualTo(true)
        .isGoalEqualTo(true)
        .watch(fireImmediately: true);
  }

  /// Ambil semua kantong aktif secara synchronous / async
  Future<List<Wallet>> getActiveWallets() async {
    return await _isar.wallets
        .filter()
        .isActiveEqualTo(true)
        .findAll();
  }

  /// Buat Tujuan Tabungan (Savings Goal) baru
  Future<Wallet> createGoal({
    required String name,
    required double targetAmount,
    DateTime? targetDate,
    double initialBalance = 0.0,
  }) async {
    final now = DateTime.now();
    final goal = Wallet()
      ..syncId = _uuid.v4()
      ..name = name
      ..balance = initialBalance
      ..targetAmount = targetAmount
      ..targetDate = targetDate
      ..isGoal = true
      ..isActive = true
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.wallets.put(goal);
    });

    return goal;
  }

  /// Update Tujuan Tabungan (Savings Goal)
  Future<Wallet> updateGoal({
    required int id,
    required String name,
    required double targetAmount,
    DateTime? targetDate,
  }) async {
    final goal = await _isar.wallets.get(id);
    if (goal == null || !goal.isGoal) {
      throw Exception('Tujuan tabungan tidak ditemukan');
    }

    goal.name = name;
    goal.targetAmount = targetAmount;
    goal.targetDate = targetDate;
    goal.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.wallets.put(goal);
    });

    return goal;
  }

  /// Buat Dompet Reguler baru
  Future<Wallet> createWallet({
    required String name,
    double initialBalance = 0.0,
  }) async {
    final now = DateTime.now();
    final wallet = Wallet()
      ..syncId = _uuid.v4()
      ..name = name
      ..balance = initialBalance
      ..isGoal = false
      ..isActive = true
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.wallets.put(wallet);
    });

    return wallet;
  }

  /// Update nama dompet
  Future<Wallet> updateWallet({
    required int id,
    required String name,
  }) async {
    final wallet = await _isar.wallets.get(id);
    if (wallet == null) {
      throw Exception('Dompet tidak ditemukan');
    }

    wallet.name = name;
    wallet.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.wallets.put(wallet);
    });

    return wallet;
  }

  /// Soft Delete dompet (Ubah isActive menjadi false)
  Future<void> softDeleteWallet(int id) async {
    final wallet = await _isar.wallets.get(id);
    if (wallet == null) {
      throw Exception('Dompet tidak ditemukan');
    }

    // DILARANG keras menghapus data permanen agar history transaksi tidak rusak
    wallet.isActive = false;
    wallet.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.wallets.put(wallet);
    });
  }
}
