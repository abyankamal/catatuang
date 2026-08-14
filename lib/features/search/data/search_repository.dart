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

    final rawTransactions = allTransactions.map((tx) => {
      'id': tx.id,
      'syncId': tx.syncId,
      'type': tx.type,
      'amount': tx.amount,
      'date': tx.date.toIso8601String(),
      'description': tx.description,
      'walletSyncId': tx.walletSyncId,
      'categorySyncId': tx.categorySyncId,
      'transactionGroupId': tx.transactionGroupId,
      'debtSyncId': tx.debtSyncId,
      'createdAt': tx.createdAt.toIso8601String(),
      'updatedAt': tx.updatedAt.toIso8601String(),
    }).toList();

    final rawCategories = allCategories.map((c) => {
      'id': c.id,
      'syncId': c.syncId,
      'name': c.name,
      'type': c.type,
      'icon': c.icon,
      'colorValue': c.colorValue,
      'isActive': c.isActive,
    }).toList();

    final rawWallets = allWallets.map((w) => {
      'id': w.id,
      'syncId': w.syncId,
      'name': w.name,
      'balance': w.balance,
      'isActive': w.isActive,
      'isGoal': w.isGoal,
      'targetAmount': w.targetAmount,
      'targetDate': w.targetDate?.toIso8601String(),
      'createdAt': w.createdAt.toIso8601String(),
      'updatedAt': w.updatedAt.toIso8601String(),
    }).toList();

    final rawDebts = allDebts.map((d) => {
      'id': d.id,
      'syncId': d.syncId,
      'title': d.title,
      'type': d.type,
      'contactSyncId': d.contactSyncId,
      'totalAmount': d.totalAmount,
      'paidAmount': d.paidAmount,
      'startDate': d.startDate.toIso8601String(),
      'dueDate': d.dueDate?.toIso8601String(),
      'notes': d.notes,
      'isActive': d.isActive,
      'createdAt': d.createdAt.toIso8601String(),
      'updatedAt': d.updatedAt.toIso8601String(),
    }).toList();

    final rawContacts = allContacts.map((c) => {
      'id': c.id,
      'syncId': c.syncId,
      'name': c.name,
      'phoneNumber': c.phoneNumber,
      'email': c.email,
      'isActive': c.isActive,
    }).toList();

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
    final minDateIso = minDate?.toIso8601String();

    // Check if we should compute directly or via Isolate (AGENTS.md §5)
    if (kIsWeb || allTransactions.length < 100) {
      return _filterAndMatch(
        cleanQuery: cleanQuery,
        parsedNumber: parsedNumber,
        typeFilter: typeFilter,
        minDateIso: minDateIso,
        rawTransactions: rawTransactions,
        rawDebts: rawDebts,
        rawWallets: rawWallets,
        rawCategories: rawCategories,
        rawContacts: rawContacts,
      );
    }

    // For larger datasets, run matching off the main thread (Isolate.run)
    return await Isolate.run(() {
      return _filterAndMatch(
        cleanQuery: cleanQuery,
        parsedNumber: parsedNumber,
        typeFilter: typeFilter,
        minDateIso: minDateIso,
        rawTransactions: rawTransactions,
        rawDebts: rawDebts,
        rawWallets: rawWallets,
        rawCategories: rawCategories,
        rawContacts: rawContacts,
      );
    });
  }

  static GlobalSearchResult _filterAndMatch({
    required String cleanQuery,
    required double? parsedNumber,
    required SearchTypeFilter typeFilter,
    required String? minDateIso,
    required List<Map<String, dynamic>> rawTransactions,
    required List<Map<String, dynamic>> rawDebts,
    required List<Map<String, dynamic>> rawWallets,
    required List<Map<String, dynamic>> rawCategories,
    required List<Map<String, dynamic>> rawContacts,
  }) {
    final now = DateTime.now();
    final minDate = minDateIso != null ? DateTime.parse(minDateIso) : null;

    final catMap = <String, Category>{};
    for (final cData in rawCategories) {
      final cat = Category()
        ..id = cData['id'] as int? ?? 0
        ..syncId = cData['syncId'] as String
        ..name = cData['name'] as String
        ..type = cData['type'] as String
        ..icon = cData['icon'] as String
        ..colorValue = cData['colorValue'] as int? ?? 0xFF5D5CFF
        ..isActive = cData['isActive'] as bool? ?? true;
      catMap[cat.syncId] = cat;
    }

    final walletMap = <String, Wallet>{};
    final allWallets = <Wallet>[];
    for (final wData in rawWallets) {
      final wallet = Wallet()
        ..id = wData['id'] as int? ?? 0
        ..syncId = wData['syncId'] as String
        ..name = wData['name'] as String
        ..balance = wData['balance'] as double? ?? 0.0
        ..isActive = wData['isActive'] as bool? ?? true
        ..isGoal = wData['isGoal'] as bool? ?? false
        ..targetAmount = wData['targetAmount'] as double?
        ..targetDate = wData['targetDate'] != null ? DateTime.tryParse(wData['targetDate'] as String) : null
        ..createdAt = DateTime.tryParse(wData['createdAt'] as String? ?? '') ?? now
        ..updatedAt = DateTime.tryParse(wData['updatedAt'] as String? ?? '') ?? now;
      walletMap[wallet.syncId] = wallet;
      allWallets.add(wallet);
    }

    final contactMap = <String, Contact>{};
    for (final cData in rawContacts) {
      final contact = Contact()
        ..id = cData['id'] as int? ?? 0
        ..syncId = cData['syncId'] as String
        ..name = cData['name'] as String
        ..phoneNumber = cData['phoneNumber'] as String?
        ..email = cData['email'] as String?
        ..isActive = cData['isActive'] as bool? ?? true;
      contactMap[contact.syncId] = contact;
    }

    final allTransactions = rawTransactions.map((txData) {
      return Transaction()
        ..id = txData['id'] as int? ?? 0
        ..syncId = txData['syncId'] as String
        ..type = txData['type'] as String
        ..amount = txData['amount'] as double? ?? 0.0
        ..date = DateTime.tryParse(txData['date'] as String? ?? '') ?? now
        ..description = txData['description'] as String?
        ..walletSyncId = txData['walletSyncId'] as String
        ..categorySyncId = txData['categorySyncId'] as String?
        ..transactionGroupId = txData['transactionGroupId'] as String?
        ..debtSyncId = txData['debtSyncId'] as String?
        ..createdAt = DateTime.tryParse(txData['createdAt'] as String? ?? '') ?? now
        ..updatedAt = DateTime.tryParse(txData['updatedAt'] as String? ?? '') ?? now;
    }).toList();

    final allDebts = rawDebts.map((dData) {
      return Debt()
        ..id = dData['id'] as int? ?? 0
        ..syncId = dData['syncId'] as String
        ..title = dData['title'] as String
        ..type = dData['type'] as String
        ..contactSyncId = dData['contactSyncId'] as String
        ..totalAmount = dData['totalAmount'] as double? ?? 0.0
        ..paidAmount = dData['paidAmount'] as double? ?? 0.0
        ..startDate = DateTime.tryParse(dData['startDate'] as String? ?? '') ?? now
        ..dueDate = dData['dueDate'] != null ? DateTime.tryParse(dData['dueDate'] as String) : null
        ..notes = dData['notes'] as String?
        ..isActive = dData['isActive'] as bool? ?? true
        ..createdAt = DateTime.tryParse(dData['createdAt'] as String? ?? '') ?? now
        ..updatedAt = DateTime.tryParse(dData['updatedAt'] as String? ?? '') ?? now;
    }).toList();

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
