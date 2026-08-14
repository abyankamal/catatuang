import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/transaction_repository.dart';

final transactionControllerProvider =
    StateNotifierProvider<TransactionController, AsyncValue<void>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return TransactionController(repo);
});

class TransactionController extends StateNotifier<AsyncValue<void>> {
  final TransactionRepository _repository;

  TransactionController(this._repository) : super(const AsyncValue.data(null));

  Future<bool> addTransaction({
    required String type,
    required double amount,
    required DateTime date,
    required String walletSyncId,
    String? categorySyncId,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addTransaction(
        type: type,
        amount: amount,
        date: date,
        walletSyncId: walletSyncId,
        categorySyncId: categorySyncId,
        description: description,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateTransaction({
    required int id,
    required String type,
    required double amount,
    required DateTime date,
    required String walletSyncId,
    String? categorySyncId,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateTransaction(
        id: id,
        type: type,
        amount: amount,
        date: date,
        walletSyncId: walletSyncId,
        categorySyncId: categorySyncId,
        description: description,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> transferBetweenWallets({
    required String sourceWalletSyncId,
    required String destinationWalletSyncId,
    required double amount,
    required DateTime date,
    double adminFee = 0.0,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.transferBetweenWallets(
        sourceWalletSyncId: sourceWalletSyncId,
        destinationWalletSyncId: destinationWalletSyncId,
        amount: amount,
        date: date,
        adminFee: adminFee,
        description: description,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteTransaction(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}


