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

  /// Inisialisasi wallet default ("Dompet Utama") jika database masih kosong
  Future<void> seedDefaultWalletIfEmpty() async {
    final count = await _isar.wallets.count();
    if (count == 0) {
      await _isar.writeTxn(() async {
        final now = DateTime.now();
        final defaultWallet = Wallet()
          ..syncId = _uuid.v4()
          ..name = 'Dompet Utama'
          ..balance = 0.0
          ..isGoal = false
          ..isActive = true
          ..createdAt = now
          ..updatedAt = now;
        await _isar.wallets.put(defaultWallet);
      });
    }
  }
}
