import 'package:flutter_riverpod/flutter_riverpod.dart';
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
}

class TransactionHistoryFilterNotifier extends StateNotifier<TransactionHistoryFilter> {
  TransactionHistoryFilterNotifier()
      : super(TransactionHistoryFilter(
          year: DateTime.now().year,
          month: DateTime.now().month,
        ));

  void setMonth(int year, int month) {
    state = state.copyWith(year: year, month: month);
  }

  void setWallet(String? walletSyncId) {
    if (walletSyncId == null || walletSyncId.isEmpty) {
      state = state.copyWith(clearWallet: true);
    } else {
      state = state.copyWith(walletSyncId: walletSyncId);
    }
  }

  void setType(String type) {
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
