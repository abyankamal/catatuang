import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/application/dashboard_providers.dart';
import '../data/budget_repository.dart';
import '../domain/budget.dart';

class BudgetFilterState {
  final int year;
  final int month;

  const BudgetFilterState({
    required this.year,
    required this.month,
  });

  BudgetFilterState copyWith({int? year, int? month}) {
    return BudgetFilterState(
      year: year ?? this.year,
      month: month ?? this.month,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetFilterState &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => year.hashCode ^ month.hashCode;
}

final budgetFilterProvider = StateProvider<BudgetFilterState>((ref) {
  final now = DateTime.now();
  return BudgetFilterState(year: now.year, month: now.month);
});

final activeBudgetsStreamProvider = StreamProvider<List<Budget>>((ref) {
  final filter = ref.watch(budgetFilterProvider);
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.watchActiveBudgets(filter.year, filter.month);
});

/// Aggregated monthly budget summary (reaktif terhadap perubahan transaksi, kategori, dan anggaran)
final monthlyBudgetSummaryProvider = FutureProvider<MonthlyBudgetSummary>((ref) async {
  final filter = ref.watch(budgetFilterProvider);
  final repo = ref.watch(budgetRepositoryProvider);

  // Pantau stream untuk update otomatis secara reaktif
  ref.watch(activeBudgetsStreamProvider);
  ref.watch(recentTransactionsStreamProvider);
  ref.watch(activeCategoriesStreamProvider);

  return await repo.calculateMonthlyBudgetSummary(filter.year, filter.month);
});

/// Current month budget summary for Dashboard quick card
final currentMonthBudgetSummaryProvider = FutureProvider<MonthlyBudgetSummary>((ref) async {
  final repo = ref.watch(budgetRepositoryProvider);
  final now = DateTime.now();

  ref.watch(activeBudgetsStreamProvider);
  ref.watch(recentTransactionsStreamProvider);
  ref.watch(activeCategoriesStreamProvider);

  return await repo.calculateMonthlyBudgetSummary(now.year, now.month);
});

class BudgetController extends StateNotifier<AsyncValue<void>> {
  final BudgetRepository _repository;

  BudgetController(this._repository) : super(const AsyncValue.data(null));

  Future<bool> setBudget({
    required String categorySyncId,
    required double monthlyLimit,
    required int year,
    required int month,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.setBudget(
        categorySyncId: categorySyncId,
        monthlyLimit: monthlyLimit,
        year: year,
        month: month,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteBudget(int id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.softDeleteBudget(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<int> copyBudgetsFromPreviousMonth({
    required int fromYear,
    required int fromMonth,
    required int toYear,
    required int toMonth,
  }) async {
    state = const AsyncValue.loading();
    try {
      final count = await _repository.copyBudgetsFromPreviousMonth(
        fromYear: fromYear,
        fromMonth: fromMonth,
        toYear: toYear,
        toMonth: toMonth,
      );
      state = const AsyncValue.data(null);
      return count;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return 0;
    }
  }
}

final budgetControllerProvider = StateNotifierProvider<BudgetController, AsyncValue<void>>((ref) {
  final repo = ref.watch(budgetRepositoryProvider);
  return BudgetController(repo);
});
