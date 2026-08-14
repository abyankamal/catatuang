import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../wallet/data/wallet_repository.dart';
import '../../wallet/domain/wallet.dart';
import '../../transaction/data/transaction_repository.dart';

final activeGoalsStreamProvider = StreamProvider<List<Wallet>>((ref) {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.watchActiveGoals();
});

final activeRegularWalletsStreamProvider = StreamProvider<List<Wallet>>((ref) {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.watchActiveRegularWallets();
});

class GoalController extends StateNotifier<AsyncValue<void>> {
  final WalletRepository _walletRepo;
  final TransactionRepository _transactionRepo;

  GoalController(this._walletRepo, this._transactionRepo) : super(const AsyncValue.data(null));

  Future<void> addGoal({
    required String name,
    required double targetAmount,
    DateTime? targetDate,
    double initialBalance = 0.0,
    String? sourceWalletSyncId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final goal = await _walletRepo.createGoal(
        name: name,
        targetAmount: targetAmount,
        targetDate: targetDate,
        initialBalance: 0, // We will use allocateSavings to transfer the initial balance
      );

      if (initialBalance > 0 && sourceWalletSyncId != null) {
        await _transactionRepo.allocateSavings(
          sourceWalletSyncId: sourceWalletSyncId,
          goalWalletSyncId: goal.syncId,
          amount: initialBalance,
          date: DateTime.now(),
        );
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> topUpGoal({
    required String goalWalletSyncId,
    required String sourceWalletSyncId,
    required double amount,
    required DateTime date,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _transactionRepo.allocateSavings(
        sourceWalletSyncId: sourceWalletSyncId,
        goalWalletSyncId: goalWalletSyncId,
        amount: amount,
        date: date,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> withdrawGoal({
    required String goalWalletSyncId,
    required String destinationWalletSyncId,
    required double amount,
    required DateTime date,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _transactionRepo.withdrawSavings(
        goalWalletSyncId: goalWalletSyncId,
        destinationWalletSyncId: destinationWalletSyncId,
        amount: amount,
        date: date,
        notes: notes,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateGoal({
    required int id,
    required String name,
    required double targetAmount,
    DateTime? targetDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _walletRepo.updateGoal(
        id: id,
        name: name,
        targetAmount: targetAmount,
        targetDate: targetDate,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteGoal(Wallet goal) async {
    state = const AsyncValue.loading();
    try {
      // Pencegahan (Opsi A): Tidak bisa menghapus jika masih ada saldo tersisa
      if (goal.balance > 0) {
        throw Exception(
          'Tidak dapat menghapus tabungan yang masih memiliki saldo Rp ${goal.balance.toInt()}. Silakan kosongkan saldo terlebih dahulu.',
        );
      }

      await _walletRepo.softDeleteWallet(goal.id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final goalControllerProvider = StateNotifierProvider<GoalController, AsyncValue<void>>((ref) {
  final walletRepo = ref.watch(walletRepositoryProvider);
  final txRepo = ref.watch(transactionRepositoryProvider);
  return GoalController(walletRepo, txRepo);
});
