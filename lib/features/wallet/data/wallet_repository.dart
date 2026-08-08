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

  /// Ambil semua kantong aktif secara synchronous / async
  Future<List<Wallet>> getActiveWallets() async {
    return await _isar.wallets
        .filter()
        .isActiveEqualTo(true)
        .findAll();
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
          ..isActive = true
          ..createdAt = now
          ..updatedAt = now;
        await _isar.wallets.put(defaultWallet);
      });
    }
  }
}
