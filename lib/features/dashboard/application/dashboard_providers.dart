import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../category/data/category_repository.dart';
import '../../category/domain/category.dart';
import '../../settings/data/app_settings_repository.dart';
import '../../settings/domain/app_settings.dart';
import '../../transaction/data/transaction_repository.dart';
import '../../transaction/domain/transaction.dart';
import '../../wallet/data/wallet_repository.dart';
import '../../wallet/domain/wallet.dart';

final activeWalletsStreamProvider = StreamProvider<List<Wallet>>((ref) {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.watchActiveWallets();
});

final activeCategoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchActiveCategories();
});

final recentTransactionsStreamProvider = StreamProvider<List<Transaction>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchRecentTransactions(limit: 10);
});

final appSettingsStreamProvider = StreamProvider<AppSettings?>((ref) {
  final repo = ref.watch(appSettingsRepositoryProvider);
  return repo.watchSettings();
});

class DashboardSummaryState {
  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpense;
  final DateTime? lockedUntil;

  const DashboardSummaryState({
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    this.lockedUntil,
  });
}

/// Aggregated dashboard state provider recalculating automatically when wallets, transactions, or settings change
final dashboardSummaryProvider = FutureProvider<DashboardSummaryState>((ref) async {
  final walletsAsync = ref.watch(activeWalletsStreamProvider);
  final settingsAsync = ref.watch(appSettingsStreamProvider);
  // Ensure changes to transactions trigger recalculation
  ref.watch(recentTransactionsStreamProvider);

  final wallets = walletsAsync.valueOrNull ?? [];
  final settings = settingsAsync.valueOrNull;

  final txRepo = ref.watch(transactionRepositoryProvider);

  final totalBalance = wallets.fold(0.0, (sum, w) => sum + w.balance);

  final now = DateTime.now();
  final summary = await txRepo.calculateMonthlySummary(now.year, now.month);

  return DashboardSummaryState(
    totalBalance: totalBalance,
    monthlyIncome: summary.totalIncome,
    monthlyExpense: summary.totalExpense,
    lockedUntil: settings?.lockedUntil,
  );
});
