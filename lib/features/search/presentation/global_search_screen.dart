import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../wallet/domain/wallet.dart';
import '../application/search_providers.dart';
import '../data/search_repository.dart';
import '../domain/search_result.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  late final TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(searchFilterProvider).query;
    _searchController = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'restaurant':
      case 'food':
        return Icons.restaurant_rounded;
      case 'directions_car':
      case 'transport':
        return Icons.directions_car_rounded;
      case 'shopping_bag':
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'movie':
      case 'entertainment':
        return Icons.movie_rounded;
      case 'receipt_long':
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'medical_services':
      case 'health':
        return Icons.medical_services_rounded;
      case 'school':
      case 'education':
        return Icons.school_rounded;
      case 'card_giftcard':
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'work':
      case 'salary':
        return Icons.work_rounded;
      case 'trending_up':
      case 'investment':
        return Icons.trending_up_rounded;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet_rounded;
      case 'swap_horiz':
        return Icons.swap_horiz_rounded;
      case 'savings':
        return Icons.savings_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchFilter = ref.watch(searchFilterProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.secondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: true,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
          decoration: InputDecoration(
            hintText: 'Cari transaksi, nominal, kategori...',
            hintStyle: GoogleFonts.hankenGrotesk(
              color: Colors.grey.shade400,
              fontSize: 15,
            ),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchFilterProvider.notifier).setQuery('');
                    },
                  )
                : null,
          ),
          onChanged: (val) {
            ref.read(searchFilterProvider.notifier).setQuery(val);
          },
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Section
          _buildFilterChips(searchFilter),

          // Search Results Area
          Expanded(
            child: _searchController.text.trim().isEmpty
                ? _buildInitialState()
                : resultsAsync.when(
                    skipLoadingOnReload: true,
                    data: (results) {
                      if (results.isEmpty) {
                        return _buildEmptyResultState(_searchController.text);
                      }
                      return _buildResultsList(results);
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (err, _) => Center(
                      child: Text('Terjadi kesalahan saat mencari: $err'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(SearchFilterState searchFilter) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Type Filters
            _buildTypeFilterChip('Semua', SearchTypeFilter.all, searchFilter.typeFilter),
            _buildTypeFilterChip('Pengeluaran', SearchTypeFilter.expense, searchFilter.typeFilter),
            _buildTypeFilterChip('Pemasukan', SearchTypeFilter.income, searchFilter.typeFilter),
            _buildTypeFilterChip('Transfer', SearchTypeFilter.transfer, searchFilter.typeFilter),
            _buildTypeFilterChip('Utang/Piutang', SearchTypeFilter.debt, searchFilter.typeFilter),

            const SizedBox(width: 8),
            Container(height: 20, width: 1, color: Colors.grey.shade300),
            const SizedBox(width: 8),

            // Date Range Filters
            _buildDateRangeChip('Semua Waktu', SearchDateRangeFilter.allTime, searchFilter.dateRangeFilter),
            _buildDateRangeChip('Bulan Ini', SearchDateRangeFilter.thisMonth, searchFilter.dateRangeFilter),
            _buildDateRangeChip('3 Bulan', SearchDateRangeFilter.last3Months, searchFilter.dateRangeFilter),
            _buildDateRangeChip('Tahun Ini', SearchDateRangeFilter.thisYear, searchFilter.dateRangeFilter),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilterChip(String label, SearchTypeFilter filterValue, SearchTypeFilter current) {
    final isSelected = filterValue == current;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        labelStyle: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: isSelected ? Colors.white : Colors.grey.shade700,
        ),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        showCheckmark: false,
        onSelected: (val) {
          ref.read(searchFilterProvider.notifier).setTypeFilter(filterValue);
        },
      ),
    );
  }

  Widget _buildDateRangeChip(String label, SearchDateRangeFilter filterValue, SearchDateRangeFilter current) {
    final isSelected = filterValue == current;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        labelStyle: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: isSelected ? Colors.white : Colors.grey.shade700,
        ),
        selected: isSelected,
        selectedColor: AppColors.secondary,
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        showCheckmark: false,
        onSelected: (val) {
          ref.read(searchFilterProvider.notifier).setDateRangeFilter(filterValue);
        },
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 54,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pencarian Cerdas',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ketik nama pengeluaran, pemasukan, kategori, dompet, nominal, atau nama kontak.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyResultState(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 54,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak Ditemukan',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tidak ada hasil yang cocok dengan "$query". Coba gunakan kata kunci atau filter lain.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(GlobalSearchResult results) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Card if transactions found
        if (results.transactions.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${results.transactions.length} Transaksi Ditemukan',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (results.totalExpense > 0)
                  Text(
                    'Keluar: ${CurrencyFormatter.format(results.totalExpense)}',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.expense,
                    ),
                  ),
                if (results.totalIncome > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Masuk: ${CurrencyFormatter.format(results.totalIncome)}',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.income,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Transactions Section
        if (results.transactions.isNotEmpty) ...[
          _buildSectionHeader('Transaksi', results.transactions.length),
          const SizedBox(height: 8),
          ...results.transactions.map((item) => _buildTransactionCard(item)),
          const SizedBox(height: 16),
        ],

        // Debts Section
        if (results.debts.isNotEmpty) ...[
          _buildSectionHeader('Utang & Piutang', results.debts.length),
          const SizedBox(height: 8),
          ...results.debts.map((item) => _buildDebtCard(item)),
          const SizedBox(height: 16),
        ],

        // Goals / Wallets Section
        if (results.goals.isNotEmpty) ...[
          _buildSectionHeader('Dompet & Target Tabungan', results.goals.length),
          const SizedBox(height: 8),
          ...results.goals.map((item) => _buildWalletCard(item)),
        ],

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Text(
      '$title ($count)',
      style: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildTransactionCard(EnrichedTransactionItem item) {
    final tx = item.transaction;
    final isIncome = tx.type == 'INCOME';
    final isTransfer = tx.type.contains('TRANSFER');

    final color = isTransfer
        ? AppColors.primary
        : (isIncome ? AppColors.income : AppColors.expense);

    final prefix = isTransfer ? '' : (isIncome ? '+ ' : '- ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Category / Type Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(item.category?.colorValue ?? 0xFF5D5CFF).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isTransfer ? Icons.swap_horiz_rounded : _getIconData(item.category?.icon),
              color: Color(item.category?.colorValue ?? 0xFF5D5CFF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Details: Description, Category & Wallet, Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description != null && tx.description!.isNotEmpty
                      ? tx.description!
                      : (item.category?.name ?? (isTransfer ? 'Transfer Dana' : 'Transaksi')),
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.wallet?.name ?? 'Dompet',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '•',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        DateFormatter.formatFullDate(tx.date),
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Amount
          Text(
            '$prefix${CurrencyFormatter.format(tx.amount)}',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtCard(EnrichedDebtItem item) {
    final debt = item.debt;
    final isPayable = debt.type == 'PAYABLE';
    final color = isPayable ? AppColors.expense : AppColors.income;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.handshake_outlined,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.title,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${isPayable ? "Utang ke" : "Piutang dari"}: ${item.contact?.name ?? "Kontak"}',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(debt.totalAmount),
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(Wallet wallet) {
    final isGoal = wallet.isGoal;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isGoal ? Colors.pink : AppColors.primary).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGoal ? Icons.savings_rounded : Icons.account_balance_wallet_rounded,
              color: isGoal ? Colors.pink : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallet.name,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isGoal ? 'Target Tabungan' : 'Dompet Reguler',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(wallet.balance),
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
