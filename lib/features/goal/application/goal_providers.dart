import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/exceptions/locked_period_exception.dart';
import '../../settings/data/app_settings_repository.dart';
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
  final AppSettingsRepository _settingsRepo;

  GoalController(
    this._walletRepo,
    this._transactionRepo,
    this._settingsRepo,
  ) : super(const AsyncValue.data(null));

  Future<void> addGoal({
    required String name,
    required double targetAmount,
    DateTime? targetDate,
    double initialBalance = 0.0,
    String? sourceWalletSyncId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();

      // Strict Pre-Validation (Task 1.3 & AGENTS.md §4)
      if (initialBalance > 0) {
        if (sourceWalletSyncId == null || sourceWalletSyncId.isEmpty) {
          throw Exception('Dompet sumber wajib dipilih jika menyertakan saldo awal.');
        }

        // 1. Pengecekan periode tutup buku sebelum mutasi atau pembuatan goal
        final settings = await _settingsRepo.getOrInitSettings();
        if (settings.lockedUntil != null && !now.isAfter(settings.lockedUntil!)) {
          throw LockedPeriodException();
        }

        // 2. Validasi dompet sumber: ada, aktif, bukan dompet tabungan (isGoal == false)
        final sourceWallet = await _walletRepo.getWalletBySyncId(sourceWalletSyncId);
        if (sourceWallet == null || !sourceWallet.isActive) {
          throw Exception('Dompet sumber tidak ditemukan atau tidak aktif.');
        }

        if (sourceWallet.isGoal) {
          throw Exception('Dompet sumber tidak boleh berupa kantong tabungan impian.');
        }

        // 3. Validasi kecukupan saldo dompet sumber
        if (sourceWallet.balance < initialBalance) {
          throw Exception('Saldo dompet "${sourceWallet.name}" tidak mencukupi untuk saldo awal tabungan.');
        }
      }

      // Setelah seluruh validasi lolos, baru buat entitas goal di Isar
      final goal = await _walletRepo.createGoal(
        name: name,
        targetAmount: targetAmount,
        targetDate: targetDate,
        initialBalance: 0,
      );

      // Alokasikan saldo awal via mekanisme Transfer 3-Transaction
      if (initialBalance > 0 && sourceWalletSyncId != null) {
        await _transactionRepo.allocateSavings(
          sourceWalletSyncId: sourceWalletSyncId,
          goalWalletSyncId: goal.syncId,
          amount: initialBalance,
          date: now,
        );
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
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
  final settingsRepo = ref.watch(appSettingsRepositoryProvider);
  return GoalController(walletRepo, txRepo, settingsRepo);
});
