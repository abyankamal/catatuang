import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../core/database/database_provider.dart';
import '../../category/domain/category.dart';
import '../../settings/domain/app_settings.dart';
import '../../transaction/domain/transaction.dart';
import '../../wallet/domain/wallet.dart';

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

class DetailedTransactionItem {
  final DateTime date;
  final String type; // INCOME, EXPENSE, TRANSFER_IN, TRANSFER_OUT
  final double amount;
  final String walletName;
  final String categoryName;
  final String? notes;

  const DetailedTransactionItem({
    required this.date,
    required this.type,
    required this.amount,
    required this.walletName,
    required this.categoryName,
    this.notes,
  });
}

class DetailedMonthlyReport {
  final int year;
  final int month;
  final String userName;
  final MonthlyReportData summary;
  final List<Wallet> wallets;
  final List<DetailedTransactionItem> transactions;

  const DetailedMonthlyReport({
    required this.year,
    required this.month,
    required this.userName,
    required this.summary,
    required this.wallets,
    required this.transactions,
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

  /// Mengambil data laporan bulanan mendalam untuk keperluan Export PDF
  Future<DetailedMonthlyReport> getDetailedMonthlyReport(int year, int month) async {
    final summary = await getMonthlyReport(year, month);

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1).subtract(const Duration(microseconds: 1));

    final transactions = await _isar.transactions
        .filter()
        .dateBetween(startDate, endDate)
        .sortByDateDesc()
        .findAll();

    final categories = await _isar.categorys.where().findAll();
    final wallets = await _isar.wallets.filter().isActiveEqualTo(true).findAll();
    final settings = await _isar.appSettings.where().findFirst();

    final catNameMap = <String, String>{};
    for (final c in categories) {
      catNameMap[c.syncId] = c.name;
    }

    final walletNameMap = <String, String>{};
    for (final w in wallets) {
      walletNameMap[w.syncId] = w.name;
    }

    final detailedTxList = transactions.map((t) {
      final categoryName = catNameMap[t.categorySyncId ?? ''] ??
          (t.type.contains('TRANSFER') ? 'Transfer Dompet' : 'Tanpa Kategori');
      final walletName = walletNameMap[t.walletSyncId] ?? 'Dompet';

      return DetailedTransactionItem(
        date: t.date,
        type: t.type,
        amount: t.amount,
        walletName: walletName,
        categoryName: categoryName,
        notes: t.description,
      );
    }).toList();

    final userName = settings?.userName?.trim().isNotEmpty == true
        ? settings!.userName!.trim()
        : 'Pengguna';

    return DetailedMonthlyReport(
      year: year,
      month: month,
      userName: userName,
      summary: summary,
      wallets: wallets,
      transactions: detailedTxList,
    );
  }

  /// Mengambil seluruh riwayat transaksi untuk keperluan Ekspor CSV All-Time
  Future<List<DetailedTransactionItem>> getAllTransactionsForExport() async {
    final transactions = await _isar.transactions
        .where()
        .sortByDateDesc()
        .findAll();

    final categories = await _isar.categorys.where().findAll();
    final wallets = await _isar.wallets.where().findAll();

    final catNameMap = <String, String>{};
    for (final c in categories) {
      catNameMap[c.syncId] = c.name;
    }

    final walletNameMap = <String, String>{};
    for (final w in wallets) {
      walletNameMap[w.syncId] = w.name;
    }

    if (kIsWeb || transactions.length < 50) {
      return transactions.map((t) {
        final categoryName = catNameMap[t.categorySyncId ?? ''] ??
            (t.type.contains('TRANSFER') ? 'Transfer Dompet' : 'Tanpa Kategori');
        final walletName = walletNameMap[t.walletSyncId] ?? 'Dompet';

        return DetailedTransactionItem(
          date: t.date,
          type: t.type,
          amount: t.amount,
          walletName: walletName,
          categoryName: categoryName,
          notes: t.description,
        );
      }).toList();
    }

    // Off-main-thread computation for large export mapping (AGENTS.md §5)
    final rawTxs = transactions.map((t) => {
      'date': t.date.toIso8601String(),
      'type': t.type,
      'amount': t.amount,
      'categorySyncId': t.categorySyncId,
      'walletSyncId': t.walletSyncId,
      'description': t.description,
    }).toList();

    return await Isolate.run(() {
      return rawTxs.map((t) {
        final date = DateTime.parse(t['date'] as String);
        final type = t['type'] as String;
        final amount = t['amount'] as double;
        final catSyncId = t['categorySyncId'] as String?;
        final walletSyncId = t['walletSyncId'] as String;
        final description = t['description'] as String?;

        final categoryName = catNameMap[catSyncId ?? ''] ??
            (type.contains('TRANSFER') ? 'Transfer Dompet' : 'Tanpa Kategori');
        final walletName = walletNameMap[walletSyncId] ?? 'Dompet';

        return DetailedTransactionItem(
          date: date,
          type: type,
          amount: amount,
          walletName: walletName,
          categoryName: categoryName,
          notes: description,
        );
      }).toList();
    });
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
