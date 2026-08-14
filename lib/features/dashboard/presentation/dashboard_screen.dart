import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../budget/presentation/widgets/dashboard_budget_card.dart';
import '../../category/domain/category.dart';
import '../../debt/application/debt_providers.dart';
import '../../notification/application/notification_providers.dart';
import '../../notification/presentation/widgets/notification_sheet.dart';
import '../../wallet/domain/wallet.dart';
import '../application/dashboard_providers.dart';
import 'widgets/expense_focus_card.dart';
import 'widgets/hero_balance_card.dart';
import 'widgets/transaction_list_tile.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final walletsAsync = ref.watch(activeWalletsStreamProvider);
    final recentTxAsync = ref.watch(recentTransactionsStreamProvider);
    final categoriesAsync = ref.watch(activeCategoriesStreamProvider);
    final expenseFocusAsync = ref.watch(dashboardExpenseFocusProvider);
    final debtSummaryAsync = ref.watch(debtSummaryProvider);

    debugPrint(
      'DASHBOARD BUILD: summary=$summaryAsync, wallets=$walletsAsync, tx=$recentTxAsync, cat=$categoriesAsync',
    );

    // Build Category lookup map
    final Map<String, Category> categoryMap = {};
    categoriesAsync.whenData((categories) {
      for (final cat in categories) {
        categoryMap[cat.syncId] = cat;
      }
    });

    // Build Wallet lookup map
    final Map<String, Wallet> walletMap = {};
    walletsAsync.whenData((wallets) {
      for (final w in wallets) {
        walletMap[w.syncId] = w;
      }
    });

    final bool hasWallets = walletMap.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardSummaryProvider);
            ref.invalidate(activeWalletsStreamProvider);
            ref.invalidate(recentTransactionsStreamProvider);
            ref.invalidate(dashboardExpenseFocusProvider);
            ref.invalidate(debtSummaryProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Catat Uang (Left), Notification & Profile (Right)
                    _buildHeader(),
                    const SizedBox(height: 20),

                    // Hero Total Balance Card
                    summaryAsync.when(
                      skipLoadingOnReload: true,
                      data: (summary) => HeroBalanceCard(
                        totalBalance: summary.totalBalance,
                        monthlyIncome: summary.monthlyIncome,
                        monthlyExpense: summary.monthlyExpense,
                        lockedUntil: summary.lockedUntil,
                        hasWallets: hasWallets,
                        onAddTap: () {
                          if (hasWallets) {
                            context.push('/add_transaction');
                          } else {
                            context.push('/wallets/add');
                          }
                        },
                        onScanTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Fitur Pindai Struk akan segera hadir!',
                              ),
                            ),
                          );
                        },
                      ),
                      loading: () => const SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (err, stack) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.expenseLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text('Gagal memuat ringkasan: $err'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Debt & Receivable Quick Overview Banner
                    _buildDebtQuickBanner(debtSummaryAsync),
                    const SizedBox(height: 20),

                    // Monthly Budget Progress Quick Overview
                    const DashboardBudgetCard(),

                    // Recent Transactions Section (Aktivitas Terbaru)
                    _buildRecentTransactionsSection(
                      recentTxAsync: recentTxAsync,
                      categoryMap: categoryMap,
                      walletMap: walletMap,
                      lockedUntil: summaryAsync.valueOrNull?.lockedUntil,
                      hasWallets: hasWallets,
                    ),
                    const SizedBox(height: 28),

                    // Expense Focus Section (Fokus Pengeluaran)
                    ExpenseFocusCard(
                      monthlyExpense:
                          summaryAsync.valueOrNull?.monthlyExpense ?? 0.0,
                      categoryExpenses:
                          expenseFocusAsync.valueOrNull?.categoryExpenses ?? [],
                    ),
                    const SizedBox(
                      height: 100,
                    ), // Extra padding for floating bottom nav
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final settings = ref.watch(appSettingsStreamProvider).valueOrNull;
    final userName = settings?.userName;
    final avatarIcon = settings?.avatarIcon;

    IconData getAvatarIconData(String? iconName) {
      switch (iconName) {
        case 'face':
          return Icons.face_rounded;
        case 'account_circle':
          return Icons.account_circle_rounded;
        case 'work':
          return Icons.work_rounded;
        case 'savings':
          return Icons.savings_rounded;
        case 'pets':
          return Icons.pets_rounded;
        case 'star':
          return Icons.star_rounded;
        case 'emoji_emotions':
          return Icons.emoji_emotions_rounded;
        case 'person':
        default:
          return Icons.person_rounded;
      }
    }

    // Time-based greeting helper
    String getTimeBasedGreeting() {
      final hour = DateTime.now().hour;
      if (hour >= 4 && hour < 11) {
        return 'Selamat Pagi';
      } else if (hour >= 11 && hour < 15) {
        return 'Selamat Siang';
      } else if (hour >= 15 && hour < 18) {
        return 'Selamat Sore';
      } else {
        return 'Selamat Malam';
      }
    }

    final greeting = getTimeBasedGreeting();
    final greetingText = userName != null && userName.isNotEmpty
        ? '$greeting, $userName!'
        : '$greeting!';

    return Row(
      children: [
        // App Title on Top (Big & Purple) & Greeting below (Small & Black)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Catat Uang',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              greetingText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const Spacer(),

        // Search Icon
        IconButton(
          onPressed: () => context.push('/search'),
          icon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade700,
            size: 24,
          ),
          tooltip: 'Pencarian Global',
        ),

        // Notification Icon with Active Badge
        Builder(
          builder: (context) {
            final unreadCount = ref.watch(unreadRemindersCountProvider);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () => NotificationSheet.show(context),
                  icon: Icon(
                    unreadCount > 0
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    color: unreadCount > 0 ? AppColors.primary : Colors.grey.shade700,
                    size: 24,
                  ),
                  tooltip: 'Pusat Pengingat',
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.expense,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 4),

        // Profile Avatar
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                getAvatarIconData(avatarIcon),
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsSection({
    required AsyncValue<List<dynamic>> recentTxAsync,
    required Map<String, Category> categoryMap,
    required Map<String, Wallet> walletMap,
    DateTime? lockedUntil,
    required bool hasWallets,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Aktivitas Terbaru',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Daftar riwayat lengkap ada di Tab Riwayat.'),
                  ),
                );
              },
              child: Text(
                'Lihat Semua',
                style: TextStyle(
                  color: AppColors.primary.withAlpha(200),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        recentTxAsync.when(
          skipLoadingOnReload: true,
          data: (transactions) {
            if (transactions.isEmpty) {
              return _buildEmptyState(hasWallets: hasWallets);
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length > 3 ? 3 : transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final category = tx.categorySyncId != null
                    ? categoryMap[tx.categorySyncId]
                    : null;
                final wallet = walletMap[tx.walletSyncId];

                return TransactionListTile(
                  transaction: tx,
                  category: category,
                  walletName: wallet?.name ?? 'Kantong',
                  lockedUntil: lockedUntil,
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, stack) => Text('Error: $err'),
        ),
      ],
    );
  }

  Widget _buildDebtQuickBanner(AsyncValue<DebtSummary> debtSummaryAsync) {
    return debtSummaryAsync.maybeWhen(
      data: (summary) {
        final hasActiveDebts = summary.remainingPayable > 0 || summary.remainingReceivable > 0;
        final hasOverdue = summary.overdueCount > 0;

        return InkWell(
          onTap: () => context.push('/debts'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasOverdue ? AppColors.expense.withAlpha(50) : Colors.grey.shade100,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(4),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (hasOverdue ? AppColors.expense : AppColors.primary).withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.handshake_outlined,
                    color: hasOverdue ? AppColors.expense : AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Utang & Piutang',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          if (hasOverdue) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.expense.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${summary.overdueCount} Jatuh Tempo',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.expense,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasActiveDebts
                            ? 'Utang: Rp ${CurrencyFormatter.format(summary.remainingPayable)} • Piutang: Rp ${CurrencyFormatter.format(summary.remainingReceivable)}'
                            : 'Kelola catatan pinjaman & hak tagihan Anda',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyState({required bool hasWallets}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.neutral,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 36,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasWallets
                ? 'Belum Ada Catatan Keuangan'
                : 'Kamu Belum Punya Dompet',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasWallets
                ? 'Belum ada pengeluaran atau pemasukan bulan ini.\nKetuk tombol + Tambah di atas untuk mencatat.'
                : 'Silakan buat dompet pertama kamu untuk mulai mencatat arus kas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

