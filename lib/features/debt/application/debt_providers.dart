import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/application/dashboard_providers.dart';
import '../../wallet/data/wallet_repository.dart';
import '../../wallet/domain/wallet.dart';
import '../data/debt_repository.dart';
import '../domain/debt.dart';

export '../data/debt_repository.dart';

/// Stream for active regular wallets (non-goal)
final activeRegularWalletsStreamProvider = StreamProvider<List<Wallet>>((ref) {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.watchActiveRegularWallets();
});

/// Filter type: 'ALL', 'PAYABLE', 'RECEIVABLE'
final debtTypeFilterProvider = StateProvider<String>((ref) => 'ALL');

/// Filter status: 'ALL', 'UNPAID', 'OVERDUE', 'COMPLETED'
final debtStatusFilterProvider = StateProvider<String>((ref) => 'ALL');

/// Watch active debts from Isar
final activeDebtsStreamProvider = StreamProvider<List<Debt>>((ref) {
  final repo = ref.watch(debtRepositoryProvider);
  final typeFilter = ref.watch(debtTypeFilterProvider);
  return repo.watchActiveDebts(type: typeFilter);
});

/// Debt summary provider
final debtSummaryProvider = FutureProvider<DebtSummary>((ref) async {
  // Watch active debts so summary auto-recalculates when debt data changes
  ref.watch(activeDebtsStreamProvider);
  final repo = ref.watch(debtRepositoryProvider);
  return await repo.calculateDebtSummary();
});

class DebtController extends StateNotifier<AsyncValue<void>> {
  final DebtRepository _repo;
  final Ref _ref;

  DebtController(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<bool> createDebt({
    required String type,
    required String contactSyncId,
    required String title,
    required double totalAmount,
    required DateTime startDate,
    DateTime? dueDate,
    String? notes,
    String? walletSyncId,
    bool affectWallet = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createDebt(
        type: type,
        contactSyncId: contactSyncId,
        title: title,
        totalAmount: totalAmount,
        startDate: startDate,
        dueDate: dueDate,
        notes: notes,
        walletSyncId: walletSyncId,
        affectWallet: affectWallet,
      );

      // Invalidate related dashboard / wallet providers if wallet balance was affected
      if (affectWallet) {
        _ref.invalidate(activeWalletsStreamProvider);
        _ref.invalidate(recentTransactionsStreamProvider);
        _ref.invalidate(dashboardSummaryProvider);
      }
      _ref.invalidate(activeDebtsStreamProvider);
      _ref.invalidate(debtSummaryProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> recordPayment({
    required int debtId,
    required double paymentAmount,
    required DateTime date,
    required String walletSyncId,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.recordPayment(
        debtId: debtId,
        paymentAmount: paymentAmount,
        date: date,
        walletSyncId: walletSyncId,
        notes: notes,
      );

      _ref.invalidate(activeWalletsStreamProvider);
      _ref.invalidate(recentTransactionsStreamProvider);
      _ref.invalidate(dashboardSummaryProvider);
      _ref.invalidate(activeDebtsStreamProvider);
      _ref.invalidate(debtSummaryProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateDebt({
    required int id,
    required String title,
    required double totalAmount,
    DateTime? dueDate,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateDebt(
        id: id,
        title: title,
        totalAmount: totalAmount,
        dueDate: dueDate,
        notes: notes,
      );

      _ref.invalidate(activeDebtsStreamProvider);
      _ref.invalidate(debtSummaryProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteDebt(int id, {bool revertLinkedTransactions = true}) async {
    state = const AsyncValue.loading();
    try {
      await _repo.softDeleteDebt(id, revertLinkedTransactions: revertLinkedTransactions);

      _ref.invalidate(activeWalletsStreamProvider);
      _ref.invalidate(recentTransactionsStreamProvider);
      _ref.invalidate(dashboardSummaryProvider);
      _ref.invalidate(activeDebtsStreamProvider);
      _ref.invalidate(debtSummaryProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final debtControllerProvider = StateNotifierProvider<DebtController, AsyncValue<void>>((ref) {
  final repo = ref.watch(debtRepositoryProvider);
  return DebtController(repo, ref);
});
