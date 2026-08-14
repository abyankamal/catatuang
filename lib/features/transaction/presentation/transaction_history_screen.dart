import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../category/domain/category.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../../wallet/domain/wallet.dart';
import '../application/transaction_controller.dart';
import '../application/transaction_history_provider.dart';
import '../domain/transaction.dart';
import 'add_transaction_screen.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  static const List<String> _monthsIndonesian = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  String _formatCurrency(double amount) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return currencyFormatter.format(amount);
  }

  void _showMonthPicker(BuildContext context, WidgetRef ref, TransactionHistoryFilter currentFilter) {
    int tempYear = currentFilter.year;
    int tempMonth = currentFilter.month;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pilih Periode',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            setModalState(() {
                              tempYear--;
                            });
                          },
                        ),
                        Text(
                          '$tempYear',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            setModalState(() {
                              tempYear++;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final isSelected = (index + 1) == tempMonth;
                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              tempMonth = index + 1;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _monthsIndonesian[index],
                              style: GoogleFonts.outfit(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          ref
                              .read(transactionHistoryFilterProvider.notifier)
                              .setMonth(tempYear, tempMonth);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Terapkan',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  void _showDetailBottomSheet(
    BuildContext context,
    WidgetRef ref,
    Transaction tx,
    List<Category> categories,
    List<Wallet> wallets,
  ) {
    final category = categories.firstWhere(
      (c) => c.syncId == tx.categorySyncId,
      orElse: () => Category()
        ..name = 'Tanpa Kategori'
        ..icon = 'help_outline',
    );

    final wallet = wallets.firstWhere(
      (w) => w.syncId == tx.walletSyncId,
      orElse: () => Wallet()..name = 'Dompet',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: tx.type == 'INCOME'
                        ? AppColors.income.withAlpha(25)
                        : tx.type == 'EXPENSE'
                            ? AppColors.expense.withAlpha(25)
                            : Colors.blue.withAlpha(25),
                    child: Icon(
                      tx.type == 'INCOME'
                          ? Icons.arrow_downward
                          : tx.type == 'EXPENSE'
                              ? Icons.arrow_upward
                              : Icons.swap_horiz,
                      color: tx.type == 'INCOME'
                          ? AppColors.income
                          : tx.type == 'EXPENSE'
                              ? AppColors.expense
                              : Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(tx.date),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${tx.type == 'INCOME' ? '+' : tx.type == 'EXPENSE' ? '-' : ''}${_formatCurrency(tx.amount)}',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: tx.type == 'INCOME'
                          ? AppColors.income
                          : tx.type == 'EXPENSE'
                              ? AppColors.expense
                              : AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              _detailRow('Tipe', _getTypeLabel(tx.type)),
              const SizedBox(height: 12),
              _detailRow('Dompet', wallet.name),
              if (tx.description != null && tx.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _detailRow('Catatan', tx.description!),
              ],
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDelete(context, ref, tx);
                      },
                      icon: const Icon(Icons.delete_outline, color: AppColors.expense),
                      label: Text(
                        'Hapus',
                        style: GoogleFonts.outfit(color: AppColors.expense),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.expense),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddTransactionScreen(
                              existingTransaction: tx,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, color: Colors.white),
                      label: Text(
                        'Edit',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: AppColors.secondary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'INCOME':
        return 'Pemasukan';
      case 'EXPENSE':
        return 'Pengeluaran';
      case 'TRANSFER_OUT':
        return 'Transfer Keluar';
      case 'TRANSFER_IN':
        return 'Transfer Masuk';
      default:
        return type;
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Transaction tx) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Hapus Transaksi?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Transaksi ini akan dihapus dan saldo dompet akan dikembalikan sesuai jumlah transaksi (Reversal Pattern).',
            style: GoogleFonts.outfit(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.outfit(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await ref
                    .read(transactionControllerProvider.notifier)
                    .deleteTransaction(tx.id);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Transaksi berhasil dihapus.'
                            : 'Gagal menghapus transaksi.',
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
              child: Text(
                'Hapus',
                style: GoogleFonts.outfit(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionHistoryFilterProvider);
    final transactionsAsync = ref.watch(transactionHistoryStreamProvider);
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final walletsAsync = ref.watch(activeWalletsStreamProvider);
    final categoriesAsync = ref.watch(activeCategoriesStreamProvider);

    final wallets = walletsAsync.asData?.value ?? [];
    final categories = categoriesAsync.asData?.value ?? [];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Riwayat Transaksi',
          style: GoogleFonts.outfit(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.secondary),
            tooltip: 'Cari Transaksi',
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month Selector & Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                // Month selector row
                InkWell(
                  onTap: () => _showMonthPicker(context, ref, filter),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withAlpha(40)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${_monthsIndonesian[filter.month - 1]} ${filter.year}',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Filters Row (Wallet + Type)
                Row(
                  children: [
                    // Wallet Dropdown Filter
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: filter.walletSyncId,
                            hint: Text(
                              'Semua Dompet',
                              style: GoogleFonts.outfit(fontSize: 13),
                            ),
                            isExpanded: true,
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  'Semua Dompet',
                                  style: GoogleFonts.outfit(fontSize: 13),
                                ),
                              ),
                              ...wallets.map(
                                (w) => DropdownMenuItem<String?>(
                                  value: w.syncId,
                                  child: Text(
                                    w.isGoal
                                        ? '🎯 ${w.name} (Tabungan)'
                                        : '💳 ${w.name}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: w.isGoal
                                          ? AppColors.primary
                                          : AppColors.secondary,
                                      fontWeight: w.isGoal
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              ref
                                  .read(transactionHistoryFilterProvider.notifier)
                                  .setWallet(val);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Type Filter Dropdown
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: filter.selectedType,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(
                                value: 'ALL',
                                child: Text('Semua Tipe', style: GoogleFonts.outfit(fontSize: 13)),
                              ),
                              DropdownMenuItem(
                                value: 'EXPENSE',
                                child: Text('Pengeluaran', style: GoogleFonts.outfit(fontSize: 13)),
                              ),
                              DropdownMenuItem(
                                value: 'INCOME',
                                child: Text('Pemasukan', style: GoogleFonts.outfit(fontSize: 13)),
                              ),
                              DropdownMenuItem(
                                value: 'TRANSFER',
                                child: Text('Transfer', style: GoogleFonts.outfit(fontSize: 13)),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                ref
                                    .read(transactionHistoryFilterProvider.notifier)
                                    .setType(val);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Monthly Summary Banner
          summaryAsync.maybeWhen(
            data: (summary) => Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.arrow_downward, color: AppColors.income, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Pemasukan',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(summary.totalIncome),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.income,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.grey.shade200,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.arrow_upward, color: AppColors.expense, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Pengeluaran',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatCurrency(summary.totalExpense),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.expense,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),

          // Transactions List
          Expanded(
            child: transactionsAsync.when(
              skipLoadingOnReload: true,
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (err, stack) => Center(
                child: Text(
                  'Terjadi kesalahan: $err',
                  style: GoogleFonts.outfit(color: AppColors.expense),
                ),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum Ada Transaksi',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tidak ada catatan transaksi pada periode ini.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Group transactions by Date
                final Map<String, List<Transaction>> grouped = {};
                for (final tx in transactions) {
                  final dateKey = DateFormat('yyyy-MM-dd').format(tx.date);
                  grouped.putIfAbsent(dateKey, () => []).add(tx);
                }

                final dateKeys = grouped.keys.toList();

                return ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                  itemCount: dateKeys.length,
                  itemBuilder: (context, index) {
                    final dateStr = dateKeys[index];
                    final txsInDate = grouped[dateStr]!;
                    final date = DateTime.parse(dateStr);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            _formatHeaderDate(date),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        Card(
                          elevation: 0,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: txsInDate.length,
                            separatorBuilder: (context, i) => Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: Colors.grey.shade100,
                            ),
                            itemBuilder: (context, i) {
                              final tx = txsInDate[i];

                              final category = categories.firstWhere(
                                (c) => c.syncId == tx.categorySyncId,
                                orElse: () => Category()
                                  ..name = 'Tanpa Kategori'
                                  ..icon = 'help_outline',
                              );

                              final wallet = wallets.firstWhere(
                                (w) => w.syncId == tx.walletSyncId,
                                orElse: () => Wallet()..name = 'Dompet',
                              );

                              final isIncome = tx.type == 'INCOME';
                              final isExpense = tx.type == 'EXPENSE';

                              return ListTile(
                                onTap: () => _showDetailBottomSheet(
                                  context,
                                  ref,
                                  tx,
                                  categories,
                                  wallets,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: isIncome
                                      ? AppColors.income.withAlpha(20)
                                      : isExpense
                                          ? AppColors.expense.withAlpha(20)
                                          : Colors.blue.withAlpha(20),
                                  child: Icon(
                                    isIncome
                                        ? Icons.arrow_downward
                                        : isExpense
                                            ? Icons.arrow_upward
                                            : Icons.swap_horiz,
                                    color: isIncome
                                        ? AppColors.income
                                        : isExpense
                                            ? AppColors.expense
                                            : Colors.blue,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  tx.description != null && tx.description!.isNotEmpty
                                      ? tx.description!
                                      : category.name,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  '${wallet.name} • ${DateFormat('HH:mm').format(tx.date)}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                trailing: Text(
                                  '${isIncome ? '+' : isExpense ? '-' : ''}${_formatCurrency(tx.amount)}',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isIncome
                                        ? AppColors.income
                                        : isExpense
                                            ? AppColors.expense
                                            : AppColors.secondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatHeaderDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return 'Hari ini - ${DateFormat('dd MMM yyyy', 'id_ID').format(date)}';
    } else if (checkDate == yesterday) {
      return 'Kemarin - ${DateFormat('dd MMM yyyy', 'id_ID').format(date)}';
    } else {
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
    }
  }
}
