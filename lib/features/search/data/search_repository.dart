import 'dart:isolate';

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../core/database/database_provider.dart';
import '../../category/domain/category.dart';
import '../../contact/domain/contact.dart';
import '../../debt/domain/debt.dart';
import '../../transaction/domain/transaction.dart';
import '../../wallet/domain/wallet.dart';
import '../domain/search_result.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return SearchRepository(isar);
});

enum SearchTypeFilter {
  all,
  expense,
  income,
  transfer,
  debt,
}

enum SearchDateRangeFilter {
  allTime,
  thisMonth,
  last3Months,
  thisYear,
}

class SearchRepository {
  final Isar _isar;

  SearchRepository(this._isar);

  Future<GlobalSearchResult> search({
    required String query,
    SearchTypeFilter typeFilter = SearchTypeFilter.all,
    SearchDateRangeFilter dateRangeFilter = SearchDateRangeFilter.allTime,
  }) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return const GlobalSearchResult.empty();
    }

    // 1. Fetch data from Isar
    final allTransactions = await _isar.transactions.where().sortByDateDesc().findAll();
    final allCategories = await _isar.categorys.where().findAll();
    final allWallets = await _isar.wallets.where().findAll();
    final allDebts = await _isar.debts.where().findAll();
    final allContacts = await _isar.contacts.where().findAll();

    final catMap = {for (var c in allCategories) c.syncId: c};
    final walletMap = {for (var w in allWallets) w.syncId: w};
    final contactMap = {for (var c in allContacts) c.syncId: c};

    // Calculate Date Range
    final now = DateTime.now();
    DateTime? minDate;
    switch (dateRangeFilter) {
      case SearchDateRangeFilter.thisMonth:
        minDate = DateTime(now.year, now.month, 1);
        break;
      case SearchDateRangeFilter.last3Months:
        minDate = DateTime(now.year, now.month - 2, 1);
        break;
      case SearchDateRangeFilter.thisYear:
        minDate = DateTime(now.year, 1, 1);
        break;
      case SearchDateRangeFilter.allTime:
        minDate = null;
        break;
    }

    final parsedNumber = double.tryParse(cleanQuery.replaceAll(RegExp(r'[^0-9]'), ''));

    // Check if we should compute directly or via Isolate (AGENTS.md §5)
    if (kIsWeb || allTransactions.length < 100) {
      return _filterAndMatch(
        cleanQuery: cleanQuery,
        parsedNumber: parsedNumber,
        typeFilter: typeFilter,
        minDate: minDate,
        allTransactions: allTransactions,
        allDebts: allDebts,
        allWallets: allWallets,
        catMap: catMap,
        walletMap: walletMap,
        contactMap: contactMap,
      );
    }

    // For larger datasets, run matching off the main thread (Isolate.run)
    return await Isolate.run(() {
      return _filterAndMatch(
        cleanQuery: cleanQuery,
        parsedNumber: parsedNumber,
        typeFilter: typeFilter,
        minDate: minDate,
        allTransactions: allTransactions,
        allDebts: allDebts,
        allWallets: allWallets,
        catMap: catMap,
        walletMap: walletMap,
        contactMap: contactMap,
      );
    });
  }

  static GlobalSearchResult _filterAndMatch({
    required String cleanQuery,
    required double? parsedNumber,
    required SearchTypeFilter typeFilter,
    required DateTime? minDate,
    required List<Transaction> allTransactions,
    required List<Debt> allDebts,
    required List<Wallet> allWallets,
    required Map<String, Category> catMap,
    required Map<String, Wallet> walletMap,
    required Map<String, Contact> contactMap,
  }) {
    final matchedTx = <EnrichedTransactionItem>[];
    double totalIncome = 0.0;
    double totalExpense = 0.0;

    // Filter Transactions
    if (typeFilter != SearchTypeFilter.debt) {
      for (final tx in allTransactions) {
        if (minDate != null && tx.date.isBefore(minDate)) continue;

        // Type filter check
        if (typeFilter == SearchTypeFilter.expense && tx.type != 'EXPENSE') continue;
        if (typeFilter == SearchTypeFilter.income && tx.type != 'INCOME') continue;
        if (typeFilter == SearchTypeFilter.transfer &&
            !tx.type.contains('TRANSFER')) {
          continue;
        }

        final wallet = walletMap[tx.walletSyncId];
        final category = catMap[tx.categorySyncId ?? ''];

        final descMatch = tx.description?.toLowerCase().contains(cleanQuery) ?? false;
        final catMatch = category?.name.toLowerCase().contains(cleanQuery) ?? false;
        final walletMatch = wallet?.name.toLowerCase().contains(cleanQuery) ?? false;
        final numberMatch = parsedNumber != null &&
            (tx.amount == parsedNumber || tx.amount.toString().contains(cleanQuery));

        if (descMatch || catMatch || walletMatch || numberMatch) {
          matchedTx.add(EnrichedTransactionItem(
            transaction: tx,
            wallet: wallet,
            category: category,
          ));

          if (tx.type == 'INCOME') {
            totalIncome += tx.amount;
          } else if (tx.type == 'EXPENSE') {
            totalExpense += tx.amount;
          }
        }
      }
    }

    // Filter Debts
    final matchedDebts = <EnrichedDebtItem>[];
    if (typeFilter == SearchTypeFilter.all || typeFilter == SearchTypeFilter.debt) {
      for (final debt in allDebts) {
        if (!debt.isActive) continue;
        if (minDate != null && debt.startDate.isBefore(minDate)) continue;

        final contact = contactMap[debt.contactSyncId];
        final titleMatch = debt.title.toLowerCase().contains(cleanQuery);
        final notesMatch = debt.notes?.toLowerCase().contains(cleanQuery) ?? false;
        final contactMatch = contact?.name.toLowerCase().contains(cleanQuery) ?? false;
        final numberMatch = parsedNumber != null &&
            (debt.totalAmount == parsedNumber ||
                debt.paidAmount == parsedNumber ||
                debt.totalAmount.toString().contains(cleanQuery));

        if (titleMatch || notesMatch || contactMatch || numberMatch) {
          matchedDebts.add(EnrichedDebtItem(
            debt: debt,
            contact: contact,
          ));
        }
      }
    }

    // Filter Goals & Wallets
    final matchedGoals = <Wallet>[];
    if (typeFilter == SearchTypeFilter.all) {
      for (final w in allWallets) {
        if (!w.isActive) continue;
        final nameMatch = w.name.toLowerCase().contains(cleanQuery);
        final numberMatch = parsedNumber != null &&
            (w.balance == parsedNumber ||
                (w.targetAmount != null && w.targetAmount == parsedNumber));

        if (nameMatch || numberMatch) {
          matchedGoals.add(w);
        }
      }
    }

    return GlobalSearchResult(
      query: cleanQuery,
      transactions: matchedTx,
      debts: matchedDebts,
      goals: matchedGoals,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
    );
  }
}
