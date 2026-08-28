import 'dart:isolate';

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/exceptions/locked_period_exception.dart';
import '../../category/domain/category.dart';
import '../../settings/domain/app_settings.dart';
import '../../transaction/domain/transaction.dart';
import '../domain/budget.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return BudgetRepository(isar);
});

enum BudgetStatus {
  safe, // < 75%
  warning, // 75% - 99.9%
  overbudget, // >= 100%
}

class CategoryBudgetUsage {
  final Budget budget;
  final String categoryName;
  final String categoryIcon;
  final int categoryColor;
  final double spentAmount;
  final double limitAmount;
  final double remainingAmount;
  final double percentage;
  final BudgetStatus status;

  const CategoryBudgetUsage({
    required this.budget,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.spentAmount,
    required this.limitAmount,
    required this.remainingAmount,
    required this.percentage,
    required this.status,
  });
}

class MonthlyBudgetSummary {
  final int year;
  final int month;
  final double totalBudgetLimit;
  final double totalBudgetSpent;
  final double totalBudgetRemaining;
  final double totalPercentage;
  final BudgetStatus overallStatus;
  final List<CategoryBudgetUsage> items;

  const MonthlyBudgetSummary({
    required this.year,
    required this.month,
    required this.totalBudgetLimit,
    required this.totalBudgetSpent,
    required this.totalBudgetRemaining,
    required this.totalPercentage,
    required this.overallStatus,
    required this.items,
  });

  const MonthlyBudgetSummary.empty(this.year, this.month)
      : totalBudgetLimit = 0.0,
        totalBudgetSpent = 0.0,
        totalBudgetRemaining = 0.0,
        totalPercentage = 0.0,
        overallStatus = BudgetStatus.safe,
        items = const [];
}

class BudgetRepository {
  final Isar _isar;
  final _uuid = const Uuid();

  BudgetRepository(this._isar);

  /// Watch active budgets for a specific month and year
  Stream<List<Budget>> watchActiveBudgets(int year, int month) {
    return _isar.budgets
        .filter()
        .isActiveEqualTo(true)
        .and()
        .yearEqualTo(year)
        .and()
        .monthEqualTo(month)
        .watch(fireImmediately: true);
  }

  /// Get active budgets for a month
  Future<List<Budget>> getActiveBudgets(int year, int month) async {
    return await _isar.budgets
        .filter()
        .isActiveEqualTo(true)
        .and()
        .yearEqualTo(year)
        .and()
        .monthEqualTo(month)
        .findAll();
  }

  /// Create or update budget for a category in a specific month
  Future<Budget> setBudget({
    required String categorySyncId,
    required double monthlyLimit,
    required int year,
    required int month,
  }) async {
    // 1. Period locking check (AGENTS.md §4)
    final settings = await _isar.appSettings.where().findFirst();
    final budgetPeriodEnd = DateTime(year, month + 1, 1).subtract(const Duration(microseconds: 1));
    if (settings?.lockedUntil != null && !budgetPeriodEnd.isAfter(settings!.lockedUntil!)) {
      throw LockedPeriodException();
    }

    if (monthlyLimit <= 0) {
      throw Exception('Nominal batas anggaran harus lebih dari 0.');
    }

    final category = await _isar.categorys
        .filter()
        .syncIdEqualTo(categorySyncId)
        .findFirst();

    if (category == null) {
      throw Exception('Kategori tidak ditemukan.');
    }

    final existing = await _isar.budgets
        .filter()
        .categorySyncIdEqualTo(categorySyncId)
        .and()
        .yearEqualTo(year)
        .and()
        .monthEqualTo(month)
        .findFirst();

    final now = DateTime.now();
    late Budget targetBudget;

    await _isar.writeTxn(() async {
      if (existing != null) {
        existing.monthlyLimit = monthlyLimit;
        existing.isActive = true;
        existing.updatedAt = now;
        await _isar.budgets.put(existing);
        targetBudget = existing;
      } else {
        targetBudget = Budget()
          ..syncId = _uuid.v4()
          ..categorySyncId = categorySyncId
          ..monthlyLimit = monthlyLimit
          ..year = year
          ..month = month
          ..isActive = true
          ..createdAt = now
          ..updatedAt = now;
        await _isar.budgets.put(targetBudget);
      }
    });

    return targetBudget;
  }

  /// Soft delete budget (AGENTS.md §3)
  Future<void> softDeleteBudget(int id) async {
    final budget = await _isar.budgets.get(id);
    if (budget == null) return;

    // Period locking check
    final settings = await _isar.appSettings.where().findFirst();
    final budgetPeriodEnd = DateTime(budget.year, budget.month + 1, 1).subtract(const Duration(microseconds: 1));
    if (settings?.lockedUntil != null && !budgetPeriodEnd.isAfter(settings!.lockedUntil!)) {
      throw LockedPeriodException();
    }

    budget.isActive = false;
    budget.updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.budgets.put(budget);
    });
  }

  /// Copy all active budgets from previous month to current/target month
  Future<int> copyBudgetsFromPreviousMonth({
    required int fromYear,
    required int fromMonth,
    required int toYear,
    required int toMonth,
  }) async {
    // Period lock check
    final settings = await _isar.appSettings.where().findFirst();
    final targetPeriodEnd = DateTime(toYear, toMonth + 1, 1).subtract(const Duration(microseconds: 1));
    if (settings?.lockedUntil != null && !targetPeriodEnd.isAfter(settings!.lockedUntil!)) {
      throw LockedPeriodException();
    }

    final previousBudgets = await getActiveBudgets(fromYear, fromMonth);
    if (previousBudgets.isEmpty) return 0;

    int copiedCount = 0;
    for (final prev in previousBudgets) {
      await setBudget(
        categorySyncId: prev.categorySyncId,
        monthlyLimit: prev.monthlyLimit,
        year: toYear,
        month: toMonth,
      );
      copiedCount++;
    }

    return copiedCount;
  }

  /// Calculate monthly budget progress & category usage off-main-thread (AGENTS.md §5)
  Future<MonthlyBudgetSummary> calculateMonthlyBudgetSummary(int year, int month) async {
    final activeBudgets = await getActiveBudgets(year, month);
    if (activeBudgets.isEmpty) {
      return MonthlyBudgetSummary.empty(year, month);
    }

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1).subtract(const Duration(microseconds: 1));

    // Ambil semua transaksi EXPENSE di bulan ini
    final expenses = await _isar.transactions
        .filter()
        .typeEqualTo('EXPENSE')
        .and()
        .dateBetween(startDate, endDate)
        .findAll();

    final categories = await _isar.categorys.where().findAll();
    final catMap = {for (final c in categories) c.syncId: c};

    // 1. Direct computation on main thread for smaller datasets
    if (kIsWeb || (expenses.length < 50 && activeBudgets.length < 20)) {
      return _computeBudgetDirect(activeBudgets, expenses, catMap, year, month);
    }

    // 2. Lightweight Isolate computation for larger datasets
    final expenseMap = <String, double>{};
    for (final exp in expenses) {
      final catId = exp.categorySyncId;
      if (catId != null) {
        expenseMap[catId] = (expenseMap[catId] ?? 0.0) + exp.amount;
      }
    }

    final payload = _BudgetIsolatePayload(
      budgetLimits: {for (final b in activeBudgets) b.syncId: b.monthlyLimit},
      budgetCategoryIds: {for (final b in activeBudgets) b.syncId: b.categorySyncId},
      expenseByCategory: expenseMap,
    );

    final aggregatedResults = await Isolate.run(() => _computeBudgetInIsolate(payload));

    final budgetMap = {for (final b in activeBudgets) b.syncId: b};
    final items = <CategoryBudgetUsage>[];

    for (final itemDto in aggregatedResults.items) {
      final budget = budgetMap[itemDto.syncId];
      if (budget == null) continue;
      final cat = catMap[budget.categorySyncId];

      items.add(
        CategoryBudgetUsage(
          budget: budget,
          categoryName: cat?.name ?? 'Tanpa Kategori',
          categoryIcon: cat?.icon ?? 'category',
          categoryColor: cat?.colorValue ?? 0xFF5D5CFF,
          spentAmount: itemDto.spent,
          limitAmount: itemDto.limit,
          remainingAmount: itemDto.remaining,
          percentage: itemDto.percentage,
          status: itemDto.status,
        ),
      );
    }

    items.sort((a, b) => b.percentage.compareTo(a.percentage));

    return MonthlyBudgetSummary(
      year: year,
      month: month,
      totalBudgetLimit: aggregatedResults.totalLimit,
      totalBudgetSpent: aggregatedResults.totalSpent,
      totalBudgetRemaining: aggregatedResults.totalRemaining,
      totalPercentage: aggregatedResults.totalPercentage,
      overallStatus: aggregatedResults.overallStatus,
      items: items,
    );
  }

  static MonthlyBudgetSummary _computeBudgetDirect(
    List<Budget> activeBudgets,
    List<Transaction> expenses,
    Map<String, Category> catMap,
    int year,
    int month,
  ) {
    final expenseMap = <String, double>{};
    for (final exp in expenses) {
      final catId = exp.categorySyncId;
      if (catId != null) {
        expenseMap[catId] = (expenseMap[catId] ?? 0.0) + exp.amount;
      }
    }

    double totalLimit = 0.0;
    double totalSpent = 0.0;
    final items = <CategoryBudgetUsage>[];

    for (final budget in activeBudgets) {
      final limit = budget.monthlyLimit;
      final spent = expenseMap[budget.categorySyncId] ?? 0.0;
      final remaining = limit - spent;
      final percentage = limit > 0 ? (spent / limit) * 100 : 0.0;

      BudgetStatus status;
      if (percentage >= 100.0) {
        status = BudgetStatus.overbudget;
      } else if (percentage >= 75.0) {
        status = BudgetStatus.warning;
      } else {
        status = BudgetStatus.safe;
      }

      totalLimit += limit;
      totalSpent += spent;

      final cat = catMap[budget.categorySyncId];
      final catName = cat?.name ?? 'Tanpa Kategori';
      final catIcon = cat?.icon ?? 'category';
      final catColor = cat?.colorValue ?? 0xFF5D5CFF;

      items.add(
        CategoryBudgetUsage(
          budget: budget,
          categoryName: catName,
          categoryIcon: catIcon,
          categoryColor: catColor,
          spentAmount: spent,
          limitAmount: limit,
          remainingAmount: remaining,
          percentage: percentage,
          status: status,
        ),
      );
    }

    items.sort((a, b) => b.percentage.compareTo(a.percentage));

    final totalRemaining = totalLimit - totalSpent;
    final totalPercentage = totalLimit > 0 ? (totalSpent / totalLimit) * 100 : 0.0;

    BudgetStatus overallStatus;
    if (totalPercentage >= 100.0) {
      overallStatus = BudgetStatus.overbudget;
    } else if (totalPercentage >= 75.0) {
      overallStatus = BudgetStatus.warning;
    } else {
      overallStatus = BudgetStatus.safe;
    }

    return MonthlyBudgetSummary(
      year: year,
      month: month,
      totalBudgetLimit: totalLimit,
      totalBudgetSpent: totalSpent,
      totalBudgetRemaining: totalRemaining,
      totalPercentage: totalPercentage,
      overallStatus: overallStatus,
      items: items,
    );
  }

  static _BudgetIsolateResult _computeBudgetInIsolate(_BudgetIsolatePayload payload) {
    double totalLimit = 0.0;
    double totalSpent = 0.0;
    final items = <_CategoryBudgetUsageDto>[];

    for (final entry in payload.budgetLimits.entries) {
      final syncId = entry.key;
      final limit = entry.value;
      final catSyncId = payload.budgetCategoryIds[syncId] ?? '';
      final spent = payload.expenseByCategory[catSyncId] ?? 0.0;
      final remaining = limit - spent;
      final percentage = limit > 0 ? (spent / limit) * 100 : 0.0;

      BudgetStatus status;
      if (percentage >= 100.0) {
        status = BudgetStatus.overbudget;
      } else if (percentage >= 75.0) {
        status = BudgetStatus.warning;
      } else {
        status = BudgetStatus.safe;
      }

      totalLimit += limit;
      totalSpent += spent;

      items.add(
        _CategoryBudgetUsageDto(
          syncId: syncId,
          spent: spent,
          limit: limit,
          remaining: remaining,
          percentage: percentage,
          status: status,
        ),
      );
    }

    final totalRemaining = totalLimit - totalSpent;
    final totalPercentage = totalLimit > 0 ? (totalSpent / totalLimit) * 100 : 0.0;

    BudgetStatus overallStatus;
    if (totalPercentage >= 100.0) {
      overallStatus = BudgetStatus.overbudget;
    } else if (totalPercentage >= 75.0) {
      overallStatus = BudgetStatus.warning;
    } else {
      overallStatus = BudgetStatus.safe;
    }

    return _BudgetIsolateResult(
      totalLimit: totalLimit,
      totalSpent: totalSpent,
      totalRemaining: totalRemaining,
      totalPercentage: totalPercentage,
      overallStatus: overallStatus,
      items: items,
    );
  }
}

class _BudgetIsolatePayload {
  final Map<String, double> budgetLimits;
  final Map<String, String> budgetCategoryIds;
  final Map<String, double> expenseByCategory;

  const _BudgetIsolatePayload({
    required this.budgetLimits,
    required this.budgetCategoryIds,
    required this.expenseByCategory,
  });
}

class _CategoryBudgetUsageDto {
  final String syncId;
  final double spent;
  final double limit;
  final double remaining;
  final double percentage;
  final BudgetStatus status;

  const _CategoryBudgetUsageDto({
    required this.syncId,
    required this.spent,
    required this.limit,
    required this.remaining,
    required this.percentage,
    required this.status,
  });
}

class _BudgetIsolateResult {
  final double totalLimit;
  final double totalSpent;
  final double totalRemaining;
  final double totalPercentage;
  final BudgetStatus overallStatus;
  final List<_CategoryBudgetUsageDto> items;

  const _BudgetIsolateResult({
    required this.totalLimit,
    required this.totalSpent,
    required this.totalRemaining,
    required this.totalPercentage,
    required this.overallStatus,
    required this.items,
  });
}

