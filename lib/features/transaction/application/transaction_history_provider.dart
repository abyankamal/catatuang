import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/transaction_repository.dart';
import '../domain/transaction.dart';

class TransactionHistoryFilter {
  final int year;
  final int month;
  final String? walletSyncId;
  final String selectedType; // 'ALL', 'INCOME', 'EXPENSE', 'TRANSFER_OUT', 'TRANSFER_IN'

  const TransactionHistoryFilter({
    required this.year,
    required this.month,
    this.walletSyncId,
    this.selectedType = 'ALL',
  });

  TransactionHistoryFilter copyWith({
    int? year,
    int? month,
    String? walletSyncId,
    bool clearWallet = false,
    String? selectedType,
  }) {
    return TransactionHistoryFilter(
      year: year ?? this.year,
      month: month ?? this.month,
      walletSyncId: clearWallet ? null : (walletSyncId ?? this.walletSyncId),
      selectedType: selectedType ?? this.selectedType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionHistoryFilter &&
        other.year == year &&
        other.month == month &&
        other.walletSyncId == walletSyncId &&
        other.selectedType == selectedType;
  }

  @override
  int get hashCode => Object.hash(year, month, walletSyncId, selectedType);
}

class TransactionHistoryFilterNotifier extends StateNotifier<TransactionHistoryFilter> {
  TransactionHistoryFilterNotifier()
      : super(TransactionHistoryFilter(
          year: DateTime.now().year,
          month: DateTime.now().month,
        ));

  void setMonth(int year, int month) {
    if (state.year == year && state.month == month) return;
    state = state.copyWith(year: year, month: month);
  }

  void setWallet(String? walletSyncId) {
    final targetId = (walletSyncId == null || walletSyncId.isEmpty) ? null : walletSyncId;
    if (state.walletSyncId == targetId) return;
    if (targetId == null) {
      state = state.copyWith(clearWallet: true);
    } else {
      state = state.copyWith(walletSyncId: targetId);
    }
  }

  void setType(String type) {
    if (state.selectedType == type) return;
    state = state.copyWith(selectedType: type);
  }
}

final transactionHistoryFilterProvider =
    StateNotifierProvider<TransactionHistoryFilterNotifier, TransactionHistoryFilter>((ref) {
  return TransactionHistoryFilterNotifier();
});

final transactionHistoryStreamProvider = StreamProvider.autoDispose<List<Transaction>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  final filter = ref.watch(transactionHistoryFilterProvider);

  return repo.watchTransactionsByMonth(
    filter.year,
    filter.month,
    walletSyncId: filter.walletSyncId,
    typeFilter: filter.selectedType,
  );
});

final monthlySummaryProvider = FutureProvider.autoDispose<MonthlySummary>((ref) async {
  final repo = ref.watch(transactionRepositoryProvider);
  final filter = ref.watch(transactionHistoryFilterProvider);
  
  // Re-calculate when transactions stream emits
  ref.watch(transactionHistoryStreamProvider);

  return repo.calculateMonthlySummary(filter.year, filter.month);
});

class DailyTransactionsGroup {
  final String dateKey;
  final DateTime date;
  final String formattedHeaderDate;
  final List<Transaction> transactions;

  const DailyTransactionsGroup({
    required this.dateKey,
    required this.date,
    required this.formattedHeaderDate,
    required this.transactions,
  });
}

final groupedTransactionsProvider = Provider.autoDispose<AsyncValue<List<DailyTransactionsGroup>>>((ref) {
  final txAsync = ref.watch(transactionHistoryStreamProvider);

  return txAsync.whenData((transactions) {
    if (transactions.isEmpty) return const [];

    final dateFormatKey = DateFormat('yyyy-MM-dd');
    final shortDateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final fullDateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<Transaction>> groupedMap = {};
    for (final tx in transactions) {
      final dateKey = dateFormatKey.format(tx.date);
      groupedMap.putIfAbsent(dateKey, () => []).add(tx);
    }

    final List<DailyTransactionsGroup> result = [];
    for (final entry in groupedMap.entries) {
      final firstTx = entry.value.first;
      final date = DateTime(firstTx.date.year, firstTx.date.month, firstTx.date.day);
      
      String header;
      if (date == today) {
        header = 'Hari ini - ${shortDateFormat.format(firstTx.date)}';
      } else if (date == yesterday) {
        header = 'Kemarin - ${shortDateFormat.format(firstTx.date)}';
      } else {
        header = fullDateFormat.format(firstTx.date);
      }

      result.add(
        DailyTransactionsGroup(
          dateKey: entry.key,
          date: date,
          formattedHeaderDate: header,
          transactions: entry.value,
        ),
      );
    }

    return result;
  });
});
