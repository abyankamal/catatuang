import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../core/database/database_provider.dart';
import '../../category/domain/category.dart';
import '../../transaction/domain/transaction.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return ReportRepository(isar);
});

class CategoryExpenseSummary {
  final String categorySyncId;
  final String categoryName;
  final String categoryIcon;
  final int categoryColor;
  final double totalAmount;
  final double percentage;

  const CategoryExpenseSummary({
    required this.categorySyncId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.totalAmount,
    required this.percentage,
  });
}

class MonthlyReportData {
  final double totalIncome;
  final double totalExpense;
  final double netIncome;
  final List<CategoryExpenseSummary> categoryExpenses;
  final List<CategoryExpenseSummary> categoryIncomes;

  const MonthlyReportData({
    required this.totalIncome,
    required this.totalExpense,
    required this.netIncome,
    required this.categoryExpenses,
    required this.categoryIncomes,
  });
}

class ReportRepository {
  final Isar _isar;

  ReportRepository(this._isar);

  Future<MonthlyReportData> getMonthlyReport(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1).subtract(const Duration(microseconds: 1));

    // Fetch transactions & categories from Isar
    final transactions = await _isar.transactions
        .filter()
        .dateBetween(startDate, endDate)
        .findAll();

    final categories = await _isar.categorys
        .filter()
        .isActiveEqualTo(true)
        .findAll();

    if (transactions.isEmpty) {
      return const MonthlyReportData(
        totalIncome: 0,
        totalExpense: 0,
        netIncome: 0,
        categoryExpenses: [],
        categoryIncomes: [],
      );
    }

    // Convert to lightweight serializable maps for Isolate.run()
    final txData = transactions.map((t) => {
      'type': t.type,
      'amount': t.amount,
      'categorySyncId': t.categorySyncId,
    }).toList();

    final catMap = <String, Map<String, dynamic>>{};
    for (final c in categories) {
      catMap[c.syncId] = {
        'name': c.name,
        'icon': c.icon,
        'color': c.colorValue,
      };
    }

    // Compute directly if small or on Web
    if (kIsWeb || txData.length < 50) {
      return _aggregateData(txData, catMap);
    }

    // Heavy computation inside Isolate.run() (AGENTS.md §5)
    return await Isolate.run(() => _aggregateData(txData, catMap));
  }

  static MonthlyReportData _aggregateData(
    List<Map<String, dynamic>> transactions,
    Map<String, Map<String, dynamic>> categoryMap,
  ) {
    double totalIncome = 0.0;
    double totalExpense = 0.0;

    final expenseCategoryTotals = <String, double>{};
    final incomeCategoryTotals = <String, double>{};

    for (final tx in transactions) {
      final type = tx['type'] as String;
      final amount = tx['amount'] as double;
      final categorySyncId = tx['categorySyncId'] as String?;

      if (type == 'INCOME') {
        totalIncome += amount;
        final catId = categorySyncId ?? 'uncategorized';
        incomeCategoryTotals[catId] = (incomeCategoryTotals[catId] ?? 0.0) + amount;
      } else if (type == 'EXPENSE') {
        totalExpense += amount;
        final catId = categorySyncId ?? 'uncategorized';
        expenseCategoryTotals[catId] = (expenseCategoryTotals[catId] ?? 0.0) + amount;
      }
    }

    List<CategoryExpenseSummary> buildSummaryList(Map<String, double> categoryTotals, double total) {
      final list = <CategoryExpenseSummary>[];
      categoryTotals.forEach((catId, amount) {
        final catInfo = categoryMap[catId];
        final name = catInfo?['name'] as String? ?? 'Tanpa Kategori';
        final icon = catInfo?['icon'] as String? ?? 'help_outline';
        final color = catInfo?['color'] as int? ?? 0xFF5D5CFF;
        final percentage = total > 0 ? (amount / total) * 100 : 0.0;

        list.add(
          CategoryExpenseSummary(
            categorySyncId: catId,
            categoryName: name,
            categoryIcon: icon,
            categoryColor: color,
            totalAmount: amount,
            percentage: percentage,
          ),
        );
      });
      list.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      return list;
    }

    final categoryExpenses = buildSummaryList(expenseCategoryTotals, totalExpense);
    final categoryIncomes = buildSummaryList(incomeCategoryTotals, totalIncome);

    return MonthlyReportData(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netIncome: totalIncome - totalExpense,
      categoryExpenses: categoryExpenses,
      categoryIncomes: categoryIncomes,
    );
  }
}
