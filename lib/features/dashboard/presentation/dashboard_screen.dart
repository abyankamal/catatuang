import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../category/data/category_repository.dart';
import '../../category/domain/category.dart';
import '../../wallet/data/wallet_repository.dart';
import '../../wallet/domain/wallet.dart';
import '../application/dashboard_providers.dart';
import 'widgets/hero_balance_card.dart';
import 'widgets/transaction_list_tile.dart';
import 'widgets/wallet_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Seed default data if database is fresh
    Future.microtask(() async {
      await ref.read(walletRepositoryProvider).seedDefaultWalletIfEmpty();
      await ref.read(categoryRepositoryProvider).seedDefaultCategoriesIfEmpty();
    });
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final walletsAsync = ref.watch(activeWalletsStreamProvider);
    final recentTxAsync = ref.watch(recentTransactionsStreamProvider);
    final categoriesAsync = ref.watch(activeCategoriesStreamProvider);

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

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardSummaryProvider);
            ref.invalidate(activeWalletsStreamProvider);
            ref.invalidate(recentTransactionsStreamProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Greeting
                _buildHeader(),
                const SizedBox(height: 16),

                // Hero Total Balance Card
                summaryAsync.when(
                  skipLoadingOnReload: true,
                  data: (summary) => HeroBalanceCard(
                    totalBalance: summary.totalBalance,
                    monthlyIncome: summary.monthlyIncome,
                    monthlyExpense: summary.monthlyExpense,
                    lockedUntil: summary.lockedUntil,
                  ),
                  loading: () => const SizedBox(
                    height: 180,
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
                const SizedBox(height: 24),

                // Active Wallets Section
                _buildWalletsSection(walletsAsync),
                const SizedBox(height: 24),

                // Quick Action Buttons
                _buildQuickActionsSection(context),
                const SizedBox(height: 24),

                // Recent Transactions Section
                _buildRecentTransactionsSection(
                  recentTxAsync: recentTxAsync,
                  categoryMap: categoryMap,
                  walletMap: walletMap,
                  lockedUntil: summaryAsync.valueOrNull?.lockedUntil,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, Selamat Datang! 👋',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'CatatUang',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            DateFormatter.formatShortDate(DateTime.now()),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletsSection(AsyncValue<List<Wallet>> walletsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Kantong Saya',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Manajemen Kantong akan hadir pada Tab Pengaturan.'),
                  ),
                );
              },
              child: const Text('Kelola'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        walletsAsync.when(
          skipLoadingOnReload: true,
          data: (wallets) {
            if (wallets.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Text('Belum ada kantong aktif.'),
              );
            }

            return SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: wallets.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final wallet = wallets[index];
                  return WalletCard(wallet: wallet);
                },
              ),
            );
          },
          loading: () => const SizedBox(
            height: 110,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => Text('Error: $err'),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aksi Cepat',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: 'Pemasukan',
                icon: Icons.add_circle_outline,
                color: AppColors.income,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Form Pemasukan akan segera dibuka!')),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionButton(
                label: 'Pengeluaran',
                icon: Icons.remove_circle_outline,
                color: AppColors.expense,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Form Pengeluaran akan segera dibuka!')),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionButton(
                label: 'Transfer',
                icon: Icons.swap_horiz,
                color: AppColors.transfer,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Form Transfer akan segera dibuka!')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsSection({
    required AsyncValue<List<dynamic>> recentTxAsync,
    required Map<String, Category> categoryMap,
    required Map<String, Wallet> walletMap,
    DateTime? lockedUntil,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Transaksi Terakhir',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Daftar riwayat lengkap ada di Tab Transaksi.'),
                  ),
                );
              },
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        recentTxAsync.when(
          skipLoadingOnReload: true,
          data: (transactions) {
            if (transactions.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final category = tx.categorySyncId != null ? categoryMap[tx.categorySyncId] : null;
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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Catatan Keuangan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Belum ada pengeluaran atau pemasukan bulan ini.\nKetuk tombol aksi cepat di atas untuk mencatat.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
