import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../application/recurring_transaction_controller.dart';
import '../domain/recurring_transaction.dart';
import 'widgets/recurring_tile.dart';

class RecurringTransactionListScreen extends ConsumerStatefulWidget {
  const RecurringTransactionListScreen({super.key});

  @override
  ConsumerState<RecurringTransactionListScreen> createState() =>
      _RecurringTransactionListScreenState();
}

class _RecurringTransactionListScreenState
    extends ConsumerState<RecurringTransactionListScreen> {
  Future<void> _handleDelete(RecurringTransaction recurring) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded,
                color: AppColors.expense, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hapus Jadwal?',
                style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Aturan jadwal ini akan dihapus secara permanen dari daftar. Riwayat transaksi sebelumnya yang sudah tercatat tidak akan terhapus. Lanjutkan?',
          style: GoogleFonts.hankenGrotesk(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Batal',
              style: GoogleFonts.manrope(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(recurringTransactionControllerProvider.notifier)
          .hardDelete(recurring.syncId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Jadwal transaksi berhasil dihapus.'
                  : 'Gagal menghapus jadwal transaksi.',
            ),
            backgroundColor: success ? AppColors.secondary : AppColors.expense,
          ),
        );
      }
    }
  }

  Future<void> _handleToggleActive(
      RecurringTransaction recurring, bool value) async {
    final success = await ref
        .read(recurringTransactionControllerProvider.notifier)
        .toggleActive(recurring.syncId, value);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Jadwal transaksi diaktifkan kembali.'
                : 'Jadwal transaksi berhasil dijeda.',
          ),
          backgroundColor: AppColors.secondary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengubah status jadwal transaksi.'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recurringAsync =
        ref.watch(recurringTransactionListStreamProvider);
    final walletsAsync = ref.watch(activeWalletsStreamProvider);
    final categoriesAsync = ref.watch(activeCategoriesStreamProvider);

    final walletMap = <String, String>{};
    for (final w in walletsAsync.valueOrNull ?? []) {
      walletMap[w.syncId] = w.name;
    }

    final categoryMap = <String, String>{};
    for (final c in categoriesAsync.valueOrNull ?? []) {
      categoryMap[c.syncId] = c.name;
    }

    final allItems = recurringAsync.valueOrNull ?? [];
    final activeItems =
        allItems.where((r) => r.isActive && !r.isCompleted).toList();
    final inactiveItems =
        allItems.where((r) => !r.isActive || r.isCompleted).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.secondary),
                  onPressed: () => context.pop(),
                )
              : null,
          title: Text(
            'Transaksi Terjadwal',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Aktif'),
                      if (activeItems.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${activeItems.length}',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Tab(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Dijeda & Selesai'),
                      if (inactiveItems.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${inactiveItems.length}',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        body: recurringAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.expense, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Terjadi kesalahan saat memuat data',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (_) {
            return TabBarView(
              children: [
                _buildList(
                  items: activeItems,
                  walletMap: walletMap,
                  categoryMap: categoryMap,
                  emptyIcon: Icons.event_available_rounded,
                  emptyTitle: 'Tidak Ada Jadwal Aktif',
                  emptySubtitle:
                      'Jadwal pengeluaran, pemasukan, atau transfer berulang yang aktif akan muncul di sini.',
                ),
                _buildList(
                  items: inactiveItems,
                  walletMap: walletMap,
                  categoryMap: categoryMap,
                  emptyIcon: Icons.pause_circle_outline_rounded,
                  emptyTitle: 'Tidak Ada Jadwal Dijeda / Selesai',
                  emptySubtitle:
                      'Jadwal rutin yang sedang dijeda atau sudah selesai batas waktunya akan dicatat di sini.',
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/add-transaction'),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            'Jadwal Baru',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList({
    required List<RecurringTransaction> items,
    required Map<String, String> walletMap,
    required Map<String, String> categoryMap,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: Icon(emptyIcon, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                emptySubtitle,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final walletName = walletMap[item.walletSyncId];
        final targetWalletName = item.targetWalletSyncId != null
            ? walletMap[item.targetWalletSyncId!]
            : null;
        final categoryName = item.categorySyncId != null
            ? categoryMap[item.categorySyncId!]
            : null;

        return RecurringTile(
          key: ValueKey(item.syncId),
          recurring: item,
          walletName: walletName,
          targetWalletName: targetWalletName,
          categoryName: categoryName,
          onDelete: () => _handleDelete(item),
          onToggleActive: (val) => _handleToggleActive(item, val),
        );
      },
    );
  }
}
