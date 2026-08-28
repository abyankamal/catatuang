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

    // 1. Calculate Date Range threshold
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

    // 2. Optimized Database-Level Query: Transactions
    List<Transaction> transactions = [];
    if (typeFilter != SearchTypeFilter.debt) {
      QueryBuilder<Transaction, Transaction, QAfterFilterCondition> txQuery;

      if (minDate != null) {
        txQuery = _isar.transactions.filter().dateGreaterThan(minDate, include: true);
      } else {
        txQuery = _isar.transactions.filter().idGreaterThan(0);
      }

      // Apply type filter directly at database level
      if (typeFilter == SearchTypeFilter.expense) {
        txQuery = txQuery.and().typeEqualTo('EXPENSE');
      } else if (typeFilter == SearchTypeFilter.income) {
        txQuery = txQuery.and().typeEqualTo('INCOME');
      } else if (typeFilter == SearchTypeFilter.transfer) {
        txQuery = txQuery.and().group(
              (q) => q.typeEqualTo('TRANSFER_IN').or().typeEqualTo('TRANSFER_OUT'),
            );
      }

      transactions = await txQuery.sortByDateDesc().findAll();
    }

    // 3. Optimized Database-Level Query: Debts
    List<Debt> debts = [];
    if (typeFilter == SearchTypeFilter.all || typeFilter == SearchTypeFilter.debt) {
      QueryBuilder<Debt, Debt, QAfterFilterCondition> debtQuery =
          _isar.debts.filter().isActiveEqualTo(true);

      if (minDate != null) {
        debtQuery = debtQuery.and().startDateGreaterThan(minDate, include: true);
      }

      debts = await debtQuery.sortByStartDateDesc().findAll();
    }

    // 4. Fetch Active Master Records
    final categories = await _isar.categorys.where().findAll();
    final wallets = await _isar.wallets.filter().isActiveEqualTo(true).findAll();
    final contacts = await _isar.contacts.where().findAll();

    final catMap = {for (final c in categories) c.syncId: c};
    final walletMap = {for (final w in wallets) w.syncId: w};
    final contactMap = {for (final c in contacts) c.syncId: c};
    final txMap = {for (final tx in transactions) tx.syncId: tx};
    final debtMap = {for (final d in debts) d.syncId: d};

    final parsedNumber = double.tryParse(cleanQuery.replaceAll(RegExp(r'[^0-9]'), ''));

    // 5. In-Memory Direct Matching (for small datasets < 100 or Web)
    if (kIsWeb || transactions.length < 100) {
      return _matchInMemory(
        cleanQuery: cleanQuery,
        parsedNumber: parsedNumber,
        typeFilter: typeFilter,
        transactions: transactions,
        debts: debts,
        wallets: wallets,
        catMap: catMap,
        walletMap: walletMap,
        contactMap: contactMap,
      );
    }

    // 6. Zero-Allocation Lightweight Isolate Processing for large datasets
    final payload = _SearchIsolatePayload(
      cleanQuery: cleanQuery,
      parsedNumber: parsedNumber,
      typeFilter: typeFilter,
      txItems: [
        for (final tx in transactions)
          _TxSearchDto(
            syncId: tx.syncId,
            description: tx.description?.toLowerCase(),
            amount: tx.amount,
            type: tx.type,
            walletSyncId: tx.walletSyncId,
            categorySyncId: tx.categorySyncId,
          ),
      ],
      debtItems: [
        for (final d in debts)
          _DebtSearchDto(
            syncId: d.syncId,
            title: d.title.toLowerCase(),
            notes: d.notes?.toLowerCase(),
            totalAmount: d.totalAmount,
            paidAmount: d.paidAmount,
            contactSyncId: d.contactSyncId,
          ),
      ],
      goalItems: [
        for (final w in wallets)
          _GoalSearchDto(
            syncId: w.syncId,
            name: w.name.toLowerCase(),
            balance: w.balance,
            targetAmount: w.targetAmount,
          ),
      ],
      walletNames: {for (final w in wallets) w.syncId: w.name.toLowerCase()},
      categoryNames: {for (final c in categories) c.syncId: c.name.toLowerCase()},
      contactNames: {for (final c in contacts) c.syncId: c.name.toLowerCase()},
    );

    final matchResult = await Isolate.run(() => _executeSearchInIsolate(payload));

    final enrichedTx = matchResult.matchedTxSyncIds
        .map((id) {
          final tx = txMap[id];
          if (tx == null) return null;
          return EnrichedTransactionItem(
            transaction: tx,
            wallet: walletMap[tx.walletSyncId],
            category: catMap[tx.categorySyncId ?? ''],
          );
        })
        .whereType<EnrichedTransactionItem>()
        .toList();

    final enrichedDebts = matchResult.matchedDebtSyncIds
        .map((id) {
          final debt = debtMap[id];
          if (debt == null) return null;
          return EnrichedDebtItem(
            debt: debt,
            contact: contactMap[debt.contactSyncId],
          );
        })
        .whereType<EnrichedDebtItem>()
        .toList();

    final matchedGoals = matchResult.matchedGoalSyncIds
        .map((id) => walletMap[id])
        .whereType<Wallet>()
        .toList();

    return GlobalSearchResult(
      query: cleanQuery,
      transactions: enrichedTx,
      debts: enrichedDebts,
      goals: matchedGoals,
      totalIncome: matchResult.totalIncome,
      totalExpense: matchResult.totalExpense,
    );
  }

  static GlobalSearchResult _matchInMemory({
    required String cleanQuery,
    required double? parsedNumber,
    required SearchTypeFilter typeFilter,
    required List<Transaction> transactions,
    required List<Debt> debts,
    required List<Wallet> wallets,
    required Map<String, Category> catMap,
    required Map<String, Wallet> walletMap,
    required Map<String, Contact> contactMap,
  }) {
    final matchedTx = <EnrichedTransactionItem>[];
    double totalIncome = 0.0;
    double totalExpense = 0.0;

    if (typeFilter != SearchTypeFilter.debt) {
      for (final tx in transactions) {
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

    final matchedDebts = <EnrichedDebtItem>[];
    if (typeFilter == SearchTypeFilter.all || typeFilter == SearchTypeFilter.debt) {
      for (final debt in debts) {
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

    final matchedGoals = <Wallet>[];
    if (typeFilter == SearchTypeFilter.all) {
      for (final w in wallets) {
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

  static _SearchIsolateResult _executeSearchInIsolate(_SearchIsolatePayload payload) {
    final matchedTxSyncIds = <String>[];
    double totalIncome = 0.0;
    double totalExpense = 0.0;

    if (payload.typeFilter != SearchTypeFilter.debt) {
      for (final tx in payload.txItems) {
        final walletName = payload.walletNames[tx.walletSyncId] ?? '';
        final categoryName = payload.categoryNames[tx.categorySyncId ?? ''] ?? '';

        final descMatch = tx.description?.contains(payload.cleanQuery) ?? false;
        final catMatch = categoryName.contains(payload.cleanQuery);
        final walletMatch = walletName.contains(payload.cleanQuery);
        final numberMatch = payload.parsedNumber != null &&
            (tx.amount == payload.parsedNumber ||
                tx.amount.toString().contains(payload.cleanQuery));

        if (descMatch || catMatch || walletMatch || numberMatch) {
          matchedTxSyncIds.add(tx.syncId);

          if (tx.type == 'INCOME') {
            totalIncome += tx.amount;
          } else if (tx.type == 'EXPENSE') {
            totalExpense += tx.amount;
          }
        }
      }
    }

    final matchedDebtSyncIds = <String>[];
    if (payload.typeFilter == SearchTypeFilter.all || payload.typeFilter == SearchTypeFilter.debt) {
      for (final debt in payload.debtItems) {
        final contactName = payload.contactNames[debt.contactSyncId] ?? '';
        final titleMatch = debt.title.contains(payload.cleanQuery);
        final notesMatch = debt.notes?.contains(payload.cleanQuery) ?? false;
        final contactMatch = contactName.contains(payload.cleanQuery);
        final numberMatch = payload.parsedNumber != null &&
            (debt.totalAmount == payload.parsedNumber ||
                debt.paidAmount == payload.parsedNumber ||
                debt.totalAmount.toString().contains(payload.cleanQuery));

        if (titleMatch || notesMatch || contactMatch || numberMatch) {
          matchedDebtSyncIds.add(debt.syncId);
        }
      }
    }

    final matchedGoalSyncIds = <String>[];
    if (payload.typeFilter == SearchTypeFilter.all) {
      for (final goal in payload.goalItems) {
        final nameMatch = goal.name.contains(payload.cleanQuery);
        final numberMatch = payload.parsedNumber != null &&
            (goal.balance == payload.parsedNumber ||
                (goal.targetAmount != null && goal.targetAmount == payload.parsedNumber));

        if (nameMatch || numberMatch) {
          matchedGoalSyncIds.add(goal.syncId);
        }
      }
    }

    return _SearchIsolateResult(
      matchedTxSyncIds: matchedTxSyncIds,
      matchedDebtSyncIds: matchedDebtSyncIds,
      matchedGoalSyncIds: matchedGoalSyncIds,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
    );
  }
}

class _TxSearchDto {
  final String syncId;
  final String? description;
  final double amount;
  final String type;
  final String walletSyncId;
  final String? categorySyncId;

  const _TxSearchDto({
    required this.syncId,
    this.description,
    required this.amount,
    required this.type,
    required this.walletSyncId,
    this.categorySyncId,
  });
}

class _DebtSearchDto {
  final String syncId;
  final String title;
  final String? notes;
  final double totalAmount;
  final double paidAmount;
  final String contactSyncId;

  const _DebtSearchDto({
    required this.syncId,
    required this.title,
    this.notes,
    required this.totalAmount,
    required this.paidAmount,
    required this.contactSyncId,
  });
}

class _GoalSearchDto {
  final String syncId;
  final String name;
  final double balance;
  final double? targetAmount;

  const _GoalSearchDto({
    required this.syncId,
    required this.name,
    required this.balance,
    this.targetAmount,
  });
}

class _SearchIsolatePayload {
  final String cleanQuery;
  final double? parsedNumber;
  final SearchTypeFilter typeFilter;
  final List<_TxSearchDto> txItems;
  final List<_DebtSearchDto> debtItems;
  final List<_GoalSearchDto> goalItems;
  final Map<String, String> walletNames;
  final Map<String, String> categoryNames;
  final Map<String, String> contactNames;

  const _SearchIsolatePayload({
    required this.cleanQuery,
    required this.parsedNumber,
    required this.typeFilter,
    required this.txItems,
    required this.debtItems,
    required this.goalItems,
    required this.walletNames,
    required this.categoryNames,
    required this.contactNames,
  });
}

class _SearchIsolateResult {
  final List<String> matchedTxSyncIds;
  final List<String> matchedDebtSyncIds;
  final List<String> matchedGoalSyncIds;
  final double totalIncome;
  final double totalExpense;

  const _SearchIsolateResult({
    required this.matchedTxSyncIds,
    required this.matchedDebtSyncIds,
    required this.matchedGoalSyncIds,
    required this.totalIncome,
    required this.totalExpense,
  });
}
