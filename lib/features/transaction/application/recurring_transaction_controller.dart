import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/application/dashboard_providers.dart';
import '../../notification/application/notification_providers.dart';
import '../data/recurring_transaction_repository.dart';
import '../domain/recurring_schedule_helper.dart';
import '../domain/recurring_transaction.dart';

/// Stream seluruh jadwal transaksi berulang (aktif, dijeda, maupun selesai)
final recurringTransactionListStreamProvider = StreamProvider<List<RecurringTransaction>>((ref) {
  final repo = ref.watch(recurringTransactionRepositoryProvider);
  return repo.watchAllRecurring();
});

/// Stream jadwal transaksi berulang yang aktif saja
final activeRecurringStreamProvider = StreamProvider<List<RecurringTransaction>>((ref) {
  final repo = ref.watch(recurringTransactionRepositoryProvider);
  return repo.watchActiveRecurring();
});

/// Provider daftar transaksi berulang yang jatuh tempo (membutuhkan konfirmasi manual)
final dueManualRecurringProvider = FutureProvider<List<RecurringTransaction>>((ref) async {
  // Listen to active stream so it updates when a recurring transaction is executed, skipped, or updated
  ref.listen(activeRecurringStreamProvider, (_, _) => ref.invalidateSelf());
  final repo = ref.watch(recurringTransactionRepositoryProvider);
  final now = DateTime.now();
  final allDue = await repo.getDueRecurring(RecurringScheduleHelper.endOfDay(now));
  return allDue.where((r) => !r.autoExecute && r.isActive).toList();
});

/// StateNotifier Controller untuk manajemen transaksi berulang dan eksekusi otomatis
final recurringTransactionControllerProvider =
    StateNotifierProvider<RecurringTransactionController, AsyncValue<void>>((ref) {
  final repository = ref.watch(recurringTransactionRepositoryProvider);
  return RecurringTransactionController(repository, ref);
});

class RecurringTransactionController extends StateNotifier<AsyncValue<void>> {
  final RecurringTransactionRepository _repository;
  final Ref _ref;

  // In-memory mutex lock to prevent concurrent double-execution on app launch
  bool _isProcessingAutoRecurring = false;

  RecurringTransactionController(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  bool get isProcessingAutoRecurring => _isProcessingAutoRecurring;

  Future<RecurringTransaction?> createRecurring({
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
    state = const AsyncValue.loading();
    try {
      final recurring = await _repository.createRecurring(
        type: type,
        amount: amount,
        walletSyncId: walletSyncId,
        frequency: frequency,
        interval: interval,
        startDate: startDate,
        endDate: endDate,
        maxOccurrences: maxOccurrences,
        description: description,
        categorySyncId: categorySyncId,
        targetWalletSyncId: targetWalletSyncId,
        adminFee: adminFee,
        autoExecute: autoExecute,
      );
      _invalidateDownstreamProviders();
      state = const AsyncValue.data(null);
      return recurring;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> updateRecurring(RecurringTransaction updated) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateRecurring(updated);
      _invalidateDownstreamProviders();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> toggleActive(String syncId, bool isActive) async {
    state = const AsyncValue.loading();
    try {
      await _repository.toggleActive(syncId, isActive);
      _invalidateDownstreamProviders();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> softDelete(String syncId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.softDelete(syncId);
      _invalidateDownstreamProviders();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> hardDelete(String syncId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.hardDelete(syncId);
      _invalidateDownstreamProviders();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> confirmExecution(
    String syncId, {
    DateTime? executionDate,
    double? customAmount,
  }) async {
    state = const AsyncValue.loading();
    try {
      final date = executionDate ?? DateTime.now();
      await _repository.executeRecurring(
        recurringSyncId: syncId,
        executionDate: date,
        customAmount: customAmount,
      );
      _invalidateDownstreamProviders();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> skipCurrentCycle(String syncId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.skipCurrentCycle(syncId);
      _invalidateDownstreamProviders();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Memproses semua transaksi berulang yang aktif dengan autoExecute == true
  /// yang telah jatuh tempo (termasuk penanganan catch-up multi-cycle jika aplikasi lama tidak dibuka).
  /// Dilindungi in-memory mutex lock agar pemanggilan simultan aman.
  Future<int> processDueAutoTransactions() async {
    if (_isProcessingAutoRecurring) {
      return 0; // Abaikan pemanggilan paralel
    }

    _isProcessingAutoRecurring = true;
    int totalExecuted = 0;

    try {
      final now = DateTime.now();
      final endOfToday = RecurringScheduleHelper.endOfDay(now);
      final allDue = await _repository.getDueRecurring(endOfToday);
      final autoDueList = allDue.where((r) => r.autoExecute && r.isActive).toList();

      for (final recurring in autoDueList) {
        // Ambil daftar siklus terlewat (maksimal 12 siklus per jadwal)
        final missedDueDates = RecurringScheduleHelper.getMissedDueDates(
          recurring,
          endOfToday,
          maxCycles: 12,
        );

        for (final dueDate in missedDueDates) {
          try {
            await _repository.executeRecurring(
              recurringSyncId: recurring.syncId,
              executionDate: dueDate,
            );
            totalExecuted++;
          } catch (_) {
            // Lanjutkan siklus lain jika satu jadwal gagal
            break;
          }
        }
      }

      if (totalExecuted > 0) {
        _invalidateDownstreamProviders();
      }
    } finally {
      _isProcessingAutoRecurring = false;
    }

    return totalExecuted;
  }

  void _invalidateDownstreamProviders() {
    _ref.invalidate(activeRecurringStreamProvider);
    _ref.invalidate(recurringTransactionListStreamProvider);
    _ref.invalidate(dueManualRecurringProvider);
    _ref.invalidate(activeWalletsStreamProvider);
    _ref.invalidate(recentTransactionsStreamProvider);
    _ref.invalidate(dashboardSummaryProvider);
    _ref.invalidate(activeRemindersProvider);
  }
}
