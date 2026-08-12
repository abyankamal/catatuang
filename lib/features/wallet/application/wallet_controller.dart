import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/wallet_repository.dart';
import '../domain/wallet.dart';

final regularWalletsStreamProvider = StreamProvider<List<Wallet>>((ref) {
  final repository = ref.watch(walletRepositoryProvider);
  return repository.watchActiveRegularWallets();
});

class WalletController extends StateNotifier<AsyncValue<void>> {
  final WalletRepository _repository;

  WalletController(this._repository) : super(const AsyncValue.data(null));

  Future<bool> createWallet({
    required String name,
    required double initialBalance,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createWallet(
        name: name,
        initialBalance: initialBalance,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateWallet({
    required int id,
    required String name,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateWallet(
        id: id,
        name: name,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteWallet(int id) async {
    state = const AsyncValue.loading();
    try {
      // Menggunakan soft delete agar history tetap utuh
      await _repository.softDeleteWallet(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final walletControllerProvider =
    StateNotifierProvider<WalletController, AsyncValue<void>>((ref) {
  return WalletController(ref.watch(walletRepositoryProvider));
});
